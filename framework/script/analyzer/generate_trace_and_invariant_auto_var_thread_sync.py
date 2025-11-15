# read debug result file then generate DIG trace file and learn invariants
# TODO this code can be added to watcher/variable_analysis.py once the algorithms are clear

import argparse
import os
import shutil
import signal
import sys
import re
import random
import subprocess
import hashlib
import random
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

# timeout in seconds that kills DIG when running for too long, 0 for not killing at all
DIG_TIMEOUT_SEC = 60

# max variables to be taken at breakpoint
MAX_BREAKPOINT_VARIABLES = 10

# max invariant files to be analyzed (prevent OOM)
MAX_INV_FILES = 1500

# max threads
MAX_THREADS = 2

# max trace line to generate likely invariants
MAX_TRACE_LINES = 0


# replace symbols with underscore
def clean_variable_name(variable_name: str) -> str:

    # these variables must be modified to prevent sympy exceptions
    sympy_reserved_words = [
        # Mathematical Constants
        "pi",
        "E",
        "I",
        "oo",
        "nan",
        "zoo",
        "GoldenRatio",
        "Catalan",
        "EulerGamma",
        # Core Classes and Constructors
        "Symbol",
        "symbols",
        "Integer",
        "Rational",
        "Float",
        "Matrix",
        "ImmutableMatrix",
        "MutableDenseMatrix",
        "Function",
        "Lambda",
        "Derivative",
        "Integral",
        "Limit",
        "Sum",
        "Product",
        "RootOf",
        "RootSum",
        "Poly",
        "Roots",
        "series",
        "series_limit",
        "Tuple",
        "FiniteSet",
        "Expr",
        "Basic",
        "S",
        # Basic Mathematical Operations
        "Add",
        "Mul",
        "Pow",
        "sqrt",
        "abs",
        "sign",
        "simplify",
        "expand",
        "factor",
        "collect",
        "apart",
        "log",
        "exp",
        "sin",
        "cos",
        "tan",
        "cot",
        "sec",
        "csc",
        "asin",
        "acos",
        "atan",
        "acot",
        "asec",
        "acsc",
        "sinh",
        "cosh",
        "tanh",
        "coth",
        "sech",
        "csch",
        "asinh",
        "acosh",
        "atanh",
        "acoth",
        "asech",
        "acsch",
        # Special Mathematical Functions
        "gamma",
        "factorial",
        "binomial",
        "beta",
        "erf",
        "erfc",
        "Ei",
        "Li",
        "besselj",
        "bessely",
        "besseli",
        "besselk",
        "hankel1",
        "hankel2",
        "legendre",
        "chebyshevt",
        "chebyshevu",
        "hermite",
        "laguerre",
        # Logical Operators and Relational Functions
        "And",
        "Or",
        "Not",
        "Implies",
        "Equivalent",
        "Eq",
        "Ne",
        "Lt",
        "Le",
        "Gt",
        "Ge",
        "Xor",
        # Assumptions
        "positive",
        "negative",
        "zero",
        "real",
        "imaginary",
        "integer",
        "rational",
        "even",
        "odd",
        "prime",
        "composite",
        # Core SymPy Functions and Modules
        "diff",
        "integrate",
        "limit",
        "solveset",
        "solve",
        "linsolve",
        "nonlinsolve",
        "subs",
        "evalf",
        "is_real",
        "is_integer",
        "is_prime",
        "pprint",
        "srepr",
        "latex",
        "mathml",
        # Python Built-in Keywords
        "and",
        "as",
        "assert",
        "break",
        "class",
        "continue",
        "def",
        "del",
        "elif",
        "else",
        "except",
        "finally",
        "for",
        "from",
        "global",
        "if",
        "import",
        "in",
        "is",
        "lambda",
        "nonlocal",
        "not",
        "or",
        "pass",
        "raise",
        "return",
        "try",
        "while",
        "with",
        "yield",
        # Built-in Functions
        "abs",
        "all",
        "any",
        "bin",
        "bool",
        "chr",
        "complex",
        "divmod",
        "float",
        "hex",
        "int",
        "len",
        "list",
        "map",
        "max",
        "min",
        "next",
        "oct",
        "open",
        "pow",
        "range",
        "round",
        "set",
        "slice",
        "str",
        "sum",
        "type",
        "zip",
        "input",
        "content",
    ]

    if variable_name in sympy_reserved_words:
        variable_name = f"{variable_name}_"

    return re.sub(r"[\W_]+", "_", variable_name)


# get absolute paths to all files in sub-folders
# all file names must be digit for debug output
def get_all_files(folder_path: str, file_name_is_all_digit: bool = True):
    if file_name_is_all_digit:
        return [
            str(file)
            for file in Path(folder_path).rglob("*")
            if file.is_file() and file.name.isdigit()
        ]

    return [str(file) for file in Path(folder_path).rglob("*") if file.is_file()]


# NOTE copied from variable_analysis.py - unmodified
def read_file_lines(file_path: str) -> list:
    lines = []

    if file_path != "":
        with open(file_path, "rb") as fp:
            for line in fp:

                # ignore encoding error
                line = line.decode(errors="replace").strip()
                if line != "" and not line.startswith("#"):
                    lines.append(line)

    return lines


# read debug output, collect frame variable values and changes throughout the execution
def get_breakpoint_frame_variable_values(lines: list) -> dict:

    # replace multiple spaces with single space
    lines = [" ".join(l.split()) for l in lines]

    # get variable values
    variable_values = {}
    execution_rounds = 0

    # dummy trace for unhit bp
    if len(lines) == 0:
        variable_values = {"unhit": []}

    temp_execution_round = {}
    all_var_unavailable = True  # prevent a case where none of vars are valid
    for i, line in enumerate(lines):

        # process line by line and keep temporary values in a block
        # variable line - keep
        if not line.strip().startswith("(lldb)") and line.strip().startswith("("):
            # NOTE variable name can be in different position, use beginning of line as reference
            variable_name = line.split(" = ")[0].split(" ")[-1]
            c_variable_name = clean_variable_name(variable_name=variable_name)

            # TODO should also detect the case where variable value is not available?
            # TODO also extract data type / memory address is possible
            # TODO also detect struct change
            # default case store zero value (given decimal value range) if variable does not exist
            temp_execution_round[c_variable_name] = 0

            prospect_value = "not_usable_yet"
            last_element = line.split(" ")[-1]

            # special case of string, use hashlib to properly convert to an integer
            # NOTE collision could happen in rare cases
            # something like: (char *) ms->o.buf = 93825003197680 "very short file (no magic)"
            if (
                last_element.strip().startswith('"')
                and last_element.strip().endswith('"')
            ) or (
                last_element.strip().startswith("'")
                and last_element.strip().endswith("'")
            ):
                last_element = line.split(" ")[-1]
                prospect_value = str(
                    int(
                        hashlib.sha256(last_element.encode()).hexdigest(),
                        16,
                    )
                    % 10**8
                )

            else:
                # take first decimal value after = to prevent non-ascii characters from lldb
                prospect_value = line.split("=")[1].strip().split(" ")[0]

            # print(variable_name, c_variable_name, last_element, prospect_value)

            # only store actual value if the value is all digit, otherwise default to zero
            if all(i.isdigit() for i in prospect_value) or all(
                i.isdigit() for i in prospect_value[1:]
            ):
                try:
                    temp_execution_round[c_variable_name] = int(prospect_value)
                    all_var_unavailable = False
                except Exception:
                    temp_execution_round[c_variable_name] = 0

        # flush collected data / keep small smaplings
        # last of block (i.e., "(lldb) continue")
        # finish one execution round
        if line == "(lldb) continue":
            # only store current values when the execution round is completed
            for var, val in temp_execution_round.items():
                if not all_var_unavailable:
                    if var not in variable_values:
                        variable_values[var] = []
                    variable_values[var].append(val)

            temp_execution_round = {}
            execution_rounds += 1

    # deduct last continue to exit
    execution_rounds -= 1

    # keep counter
    # with open("execution_rounds", "a") as er:
    #     er.write(f"round {execution_rounds}\n")

    # TODO return backtrace
    return variable_values


# expect that bp_file_path are single bp file i.e., numerical name
def process_debug_result(
    bp_file_path: str,
    trace_output_path: str = "",
):

    print("creating trace for: ", bp_file_path)

    # bp number
    bp_number = bp_file_path.split("/")[-1]

    # original fuzzing input file name
    input_file_name = bp_file_path.split("/")[-2]

    breakpoint_debug_lines = read_file_lines(file_path=bp_file_path)
    all_frame_variable_values = get_breakpoint_frame_variable_values(
        lines=breakpoint_debug_lines
    )

    # NOTE random up to MAX_BREAKPOING_VARIABLES variables to prevent OOM
    random.seed(27)
    selected_keys = random.sample(
        all_frame_variable_values.keys(),
        min(MAX_BREAKPOINT_VARIABLES, len(all_frame_variable_values)),
    )
    # update var values
    all_frame_variable_values = {
        key: all_frame_variable_values[key] for key in selected_keys
    }

    trace_lines = format_trace(
        variable_values=all_frame_variable_values,
    )

    if len(trace_lines) > 1:

        if trace_output_path != "":
            # write trace file for DIG
            new_trace_path = os.path.join(trace_output_path, input_file_name)
            os.makedirs(new_trace_path, exist_ok=True)

            with open(os.path.join(new_trace_path, f"{bp_number}.trace"), "w") as fp:
                fp.write("\n".join(trace_lines))
        else:
            print("=========================================")
            print(bp_file_path)
            print("=========================================")
            for trace_line in trace_lines:
                print(trace_line)


# run DIG
def process_trace_result(trace_file_path: str, invariant_output_path: str):

    print("learning invariants for: ", trace_file_path)

    # trace file name
    trace_file = trace_file_path.split("/")[-1]

    # original fuzzing input file name
    input_file_name = trace_file_path.split("/")[-2]

    # write invariants
    new_invariant_path = os.path.join(invariant_output_path, input_file_name)

    os.makedirs(new_invariant_path, exist_ok=True)
    new_invariant_file_path = os.path.join(new_invariant_path, f"{trace_file}.inv")

    # check if invariants already exist, skip mining
    if os.path.isfile(new_invariant_file_path):
        print("result exists, skip")
        return False

    # run DIG with python 3.10
    with open(new_invariant_file_path, "w") as invariant_output:
        process: subprocess.Popen = None
        try:
            process = subprocess.Popen(
                [
                    "python3.10",
                    "-O",
                    "/program/dig/src/dig.py",
                    trace_file_path,
                    "-log",
                    "3",
                    "--nofilter",
                    "--nosimplify",
                    "--seed",
                    "27",
                ],
                stdout=invariant_output,
                stderr=invariant_output,
                start_new_session=True,
            )
            process.wait(timeout=DIG_TIMEOUT_SEC)
        except subprocess.TimeoutExpired:
            print("DIG timeout, skip")
            # kill session https://alexandra-zaharia.github.io/posts/kill-subprocess-and-its-children-on-timeout-python/
            os.killpg(os.getpgid(process.pid), signal.SIGKILL)


# process trace file in batch
def process_trace_batch(trace_file_list: list, invariant_output_path: str) -> bool:
    for trace_file in trace_file_list:
        process_trace_result(
            trace_file_path=trace_file, invariant_output_path=invariant_output_path
        )

    return True


# emitating DIG trace format
def format_trace(variable_values: dict) -> list:
    trace_function_name = "dummy"
    trace_lines = []

    variables = list(variable_values.keys())

    header_line = f"{trace_function_name};"
    for var in variables:
        header_line = f"{header_line} I {var};"

    # execution count up to minimum execution_count to prevent index oob
    execution_count = min([len(variable_values[v]) for v in variables])

    # gather values
    for i in range(execution_count):
        trace_line = f"{trace_function_name};"
        for v in variables:
            trace_line = f"{trace_line} {variable_values[v][i]};"

        trace_lines.append(trace_line)

    # TODO convert non numerical values or extreme values to smaller values
    # this can be done ONLY when the entire input corpus is visible
    # TODO remove variables that may not influence the invariants

    # remove redundant trace lines
    trace_lines = list(set(trace_lines))

    # NOTE if restricted, randomly select up to MAX_TRACE_LINES execution traces to reduce DIG performance issue
    # local seed - use same seed for every trace - global seed would make it uncontrollable for multiple traces
    random.seed(27)
    if MAX_TRACE_LINES != 0:
        trace_lines = random.sample(trace_lines, min(MAX_TRACE_LINES, len(trace_lines)))

    # insert header line
    trace_lines.insert(0, header_line)

    return trace_lines


# kill hanging DIG processes - dangerous command
def kill_other_procs_but_me():
    try:
        print("prune hanging processes")
        os.kill(-1, signal.SIGKILL)
    except ProcessLookupError:
        print("nothing to kill")


if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    # accept BFC ad BIC paths, to select symmetric trace files in both versions
    parser.add_argument(
        "--bfc_debug_output_path",
        help="path to store debug result",
        default="",
    )
    parser.add_argument(
        "--bfc_trace_output_path",
        help="deatination path for execution traces",
        default="",
    )
    parser.add_argument(
        "--bfc_invariant_output_path",
        help="destination path for invariants",
        default="",
    )
    parser.add_argument(
        "--bic_debug_output_path",
        help="path to store debug result",
        default="",
    )
    parser.add_argument(
        "--bic_trace_output_path",
        help="deatination path for execution traces",
        default="",
    )
    parser.add_argument(
        "--bic_invariant_output_path",
        help="destination path for invariants",
        default="",
    )

    parser.add_argument(
        "--max_threads",
        default="",
        help="maximum workers to read invariant files, blank to use file default",
    )

    args = parser.parse_args()

    # receive arguments
    bfc_debug_output_path = args.bfc_debug_output_path
    bfc_trace_output_path = args.bfc_trace_output_path
    bfc_invariant_output_path = args.bfc_invariant_output_path
    bic_debug_output_path = args.bic_debug_output_path
    bic_trace_output_path = args.bic_trace_output_path
    bic_invariant_output_path = args.bic_invariant_output_path
    max_threads = args.max_threads

    if max_threads == "":
        max_threads = MAX_THREADS
    else:
        max_threads = int(max_threads)

    if bfc_debug_output_path == "" or bic_debug_output_path == "":
        print("empty debug_output_path")
        sys.exit(1)

    # if invariant output paths already exist, just skip to trace processing
    # NOTE we completely skip debug result processing and trace creation because we have completed that part in our experiment
    if not (
        os.path.isdir(bfc_invariant_output_path)
        and os.path.isdir(bic_invariant_output_path)
    ):

        # cleanup
        if bfc_trace_output_path != "" and bfc_invariant_output_path != "":
            shutil.rmtree(bfc_trace_output_path, ignore_errors=True)
            # shutil.rmtree(bfc_invariant_output_path, ignore_errors=True)

        if bic_trace_output_path != "" and bic_invariant_output_path != "":
            shutil.rmtree(bic_trace_output_path, ignore_errors=True)
            # shutil.rmtree(bic_invariant_output_path, ignore_errors=True)

        # BFC
        bfc_all_debug_results = get_all_files(
            folder_path=bfc_debug_output_path, file_name_is_all_digit=True
        )

        print("generate BFC trace")
        print("MAX_THREADS", max_threads)
        print("debug_output_path", len(bfc_all_debug_results))

        # multi-thread process debug files and create trace files
        with ThreadPoolExecutor(max_workers=max_threads) as executor:
            result = {
                executor.submit(process_debug_result, file, bfc_trace_output_path): file
                for file in bfc_all_debug_results
            }

        # BIC
        bic_all_debug_results = get_all_files(
            folder_path=bic_debug_output_path, file_name_is_all_digit=True
        )

        print("generate BIC trace")
        print("MAX_THREADS", max_threads)
        print("debug_output_path", len(bic_all_debug_results))

        # multi-thread process debug files and create trace files
        with ThreadPoolExecutor(max_workers=max_threads) as executor:
            result = {
                executor.submit(process_debug_result, file, bic_trace_output_path): file
                for file in bic_all_debug_results
            }

        # clear up mempry
        del bfc_all_debug_results
        del bic_all_debug_results

    # ====================================================================

    # process trace files for BFC and BIC together
    # create invariants
    if (bfc_trace_output_path != "" and bfc_invariant_output_path != "") and (
        bic_trace_output_path != "" and bic_invariant_output_path != ""
    ):

        bfc_all_trace_results = get_all_files(
            folder_path=bfc_trace_output_path, file_name_is_all_digit=False
        )

        bic_all_trace_results = get_all_files(
            folder_path=bic_trace_output_path, file_name_is_all_digit=False
        )

        print("process BFC / BIC invariant together")

        print("generate invariants")
        print("MAX_THREADS", MAX_THREADS)
        print("bfc_all_trace_results", len(bfc_all_trace_results))
        print("bic_all_trace_results", len(bic_all_trace_results))

        # sampling to cap maximum input per BPs
        # walk through all_trace_results and group trace files by BP
        print("check trace files per bp")
        bfc_trace_bps = {}
        bic_trace_bps = {}
        for trace_file in bfc_all_trace_results:
            bp_number = trace_file.split("/")[-1].split(".")[0]
            if bp_number not in bfc_trace_bps.keys():
                bfc_trace_bps[bp_number] = []
            bfc_trace_bps[bp_number].append(trace_file)

        for trace_file in bic_all_trace_results:
            bp_number = trace_file.split("/")[-1].split(".")[0]
            if bp_number not in bic_trace_bps.keys():
                bic_trace_bps[bp_number] = []
            bic_trace_bps[bp_number].append(trace_file)

        bfc_bps = set(bfc_trace_bps.keys())
        bic_bps = set(bic_trace_bps.keys())

        # check common BPs in BFC and BIC, only process invariants at these BPs
        common_bps = list(bfc_bps.intersection(bic_bps))

        for bp_number in common_bps:
            print("working at bp number", bp_number)

            bfc_traces = bfc_trace_bps[bp_number]
            bic_traces = bic_trace_bps[bp_number]

            print("bp_bfc_trace", len(bfc_traces))
            print("bp_bic_trace", len(bic_traces))

            random.seed(27)

            # if traces exceed MAX_INV_FILEs
            # check total common traces e.g., S out of Nbfc / Nbic
            # maintain proportion of trace files within MAX_INV_FILEs
            # i.e., sample [S/N * MAX_INV_FILEs] similar traces
            # fill remaining with sample of (Nbfc - S)/Nbfc and (Nbic - S)/Nbic

            selected_bfc_traces = []
            selected_bic_traces = []
            if len(bfc_traces) > MAX_INV_FILES or len(bic_traces) > MAX_INV_FILES:
                print("capping trace length")

                # original fuzzing input file name
                bfc_trace_inputs = [t.split("/")[-2] for t in bfc_traces]
                bic_trace_inputs = [t.split("/")[-2] for t in bic_traces]

                common_inputs = set(bfc_trace_inputs).intersection(
                    set(bic_trace_inputs)
                )
                bfc_unique_inputs = set(bfc_trace_inputs).difference(
                    set(bic_trace_inputs)
                )
                bic_unique_inputs = set(bic_trace_inputs).difference(
                    set(bfc_trace_inputs)
                )

                # sample size from each group
                # use maxmium proportion to decide number of common inputs
                common_sample_size = int(
                    max(
                        len(common_inputs) / len(bfc_trace_inputs),
                        len(common_inputs) / len(bic_trace_inputs),
                    )
                    * MAX_INV_FILES
                )

                print("total common inputs", len(common_inputs))
                print("sample common inputs", common_sample_size)

                # space to fill-up on each side
                remaining_size = MAX_INV_FILES - common_sample_size

                # execute sampling
                # ensure that samples are as symmetric as possible in BFC and BIC
                sampled_common_inputs = random.sample(common_inputs, common_sample_size)
                unused_common_inputs = [
                    x for x in common_inputs if x not in sampled_common_inputs
                ]

                sampled_bfc_inputs = []
                sampled_bic_inputs = []

                bfc_pool = list(bfc_unique_inputs)
                bic_pool = list(bic_unique_inputs)

                if remaining_size > len(bfc_unique_inputs):
                    bfc_pool += unused_common_inputs
                if remaining_size > len(bic_unique_inputs):
                    bic_pool += unused_common_inputs

                sampled_bfc_inputs = random.sample(bfc_pool, remaining_size)
                sampled_bic_inputs = random.sample(bic_pool, remaining_size)

                # fill-up space on each side
                selected_bfc_inputs = sampled_common_inputs + sampled_bfc_inputs
                selected_bic_inputs = sampled_common_inputs + sampled_bic_inputs

                # assemble trace file path to selected trace input files
                selected_bfc_traces = [
                    f"{bfc_trace_output_path}/{t}/{bp_number}.trace"
                    for t in selected_bfc_inputs
                ]
                selected_bic_traces = [
                    f"{bic_trace_output_path}/{t}/{bp_number}.trace"
                    for t in selected_bic_inputs
                ]

            else:
                # use all bfc/bic traces
                selected_bfc_traces = bfc_traces
                selected_bic_traces = bic_traces

            # ===================================================

            print("selected_bfc_traces", len(selected_bfc_traces))
            print("selected_bic_traces", len(selected_bic_traces))

            # BFC and BIC
            print("process BFC and BIC traces")
            # multi-thread mine invariants
            with ThreadPoolExecutor(max_workers=MAX_THREADS) as executor:
                result1 = executor.submit(
                    process_trace_batch, selected_bfc_traces, bfc_invariant_output_path
                )

                result2 = executor.submit(
                    process_trace_batch, selected_bic_traces, bic_invariant_output_path
                )

            # cleanup hanging subprocess
            kill_other_procs_but_me()
