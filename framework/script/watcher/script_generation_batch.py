# generate debugging script that capture stack frames before and after code changes
import argparse
import os
import sys
import csv
from io import StringIO
import subprocess

from dotenv import load_dotenv

load_dotenv(dotenv_path="/script/framework_config.env")

# timeout in seconds that kills LLDB when running for too long, 0 for not killing at all
LLDB_TIMEOUT_SEC = int(os.getenv("LLDB_TIMEOUT_SEC", "60"))


def _get_batch_debug_script(
    code_target: str, breakpoints: list, breakpoint_variables: list, input_file: str
) -> str:

    batch_script = """
settings set interpreter.stop-command-source-on-error 0
settings set auto-confirm 1
batch_breakpoint_commands

run input_file
quit
"""

    batch_breakpoint_commands = ""

    for bp_index, bp in enumerate(breakpoints):
        bp_file = bp[0]
        bp_line = bp[1]

        bp_no = bp_index + 1

        # one breakpoint command
        script = f"""breakpoint set --file target_file --line target_line
breakpoint command add {bp_no}
frame info
selected_variable_frame
continue
DONE
"""

        script = script.replace("target_file", os.path.join(code_target, bp_file))
        script = script.replace("target_line", str(bp_line))

        # list all variables that are selected for observation
        # print frame variable in decimal format
        selected_varaible_frame = ""
        for variable in breakpoint_variables[bp_index]:
            selected_varaible_frame += f"frame variable {variable} -f dec \n"

        script = script.replace("selected_variable_frame", selected_varaible_frame)

        batch_breakpoint_commands += f"{script}\n"

    # aggregate commands
    batch_script = batch_script.replace(
        "batch_breakpoint_commands", batch_breakpoint_commands
    )
    batch_script = batch_script.replace("input_file", input_file)

    return batch_script


def _get_file_lines(file_path: str) -> list:
    if file_path == "":
        return []

    with open(file_path) as file:
        return [line.rstrip() for line in file if not line.strip().startswith("#")]


def _parse_csv_line(line: str) -> list:
    reader = csv.reader(StringIO(line))
    return next(reader)


def _get_breakpoint_information(breakpoint_lines: list) -> list:
    breakpoints = []
    for bp in breakpoint_lines:
        bp_items = _parse_csv_line(bp)

        if len(bp_items) >= 2:
            bp_file, bp_line = bp_items[:2]

            breakpoints.append((bp_file, int(bp_line.strip())))

    return breakpoints


if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--repository_path",
        help="path to respository (bug-inducing version) - to maintain absolute path for debugging",
        default="",
    )
    parser.add_argument(
        "--target_variable_path",
        help="path to store observed variables information",
        default="",
    )
    parser.add_argument(
        "--target_breakpoint_file",
        help="path to store selected breakpoints information",
        default="",
    )
    parser.add_argument(
        "--test_input", help="path that contains testing input files", default=""
    )
    parser.add_argument(
        "--debug_script_path", help="path to store debug script", default=""
    )
    parser.add_argument(
        "--execution_target",
        help="coverage-enable binary (bug-inducing version)",
        default="",
    )
    parser.add_argument(
        "--debug_output_path", help="path to store debug trace", default=""
    )

    args = parser.parse_args()

    # receive arguments
    repository_path = args.repository_path
    target_variable_path = args.target_variable_path
    target_breakpoint_file = args.target_breakpoint_file
    test_input = args.test_input
    debug_script_path = args.debug_script_path
    execution_target = args.execution_target
    debug_output_path = args.debug_output_path

    if (
        (repository_path == "" and not os.path.isdir(repository_path))
        or (target_variable_path == "" and not os.path.isdir(target_variable_path))
        or (target_breakpoint_file == "" and not os.path.isfile(target_breakpoint_file))
        or (test_input == "" and not os.path.isdir(test_input))
        or (debug_script_path == "" and not os.path.isdir(debug_script_path))
        or (execution_target == "" and not os.path.isfile(execution_target))
        or (debug_output_path == "" and not os.path.isdir(debug_output_path))
    ):
        print("some intended input files do not exist")
        print(
            (repository_path == "" and not os.path.isdir(repository_path)),
            (target_variable_path == "" and not os.path.isdir(target_variable_path)),
            (
                target_breakpoint_file == ""
                and not os.path.isfile(target_breakpoint_file)
            ),
            (test_input == "" and not os.path.isdir(test_input)),
            (debug_script_path == "" and not os.path.isdir(debug_script_path)),
            (execution_target == "" and not os.path.isfile(execution_target)),
            (debug_output_path == "" and not os.path.isdir(debug_output_path)),
        )
        sys.exit(1)

    # read files

    target_breakpoint_lines: list = _get_file_lines(file_path=target_breakpoint_file)

    # get list of selected breakpoints
    breakpoints = _get_breakpoint_information(breakpoint_lines=target_breakpoint_lines)

    found_lldb_error = False
    bp_target_variables = []
    # loop through breakpoint line to check hit function
    for bp_index, bp in enumerate(breakpoints):
        bp_file = bp[0]
        bp_line = bp[1]

        # get list of variables at selected breakpoint
        bp_target_variables.append(
            _get_file_lines(file_path=os.path.join(target_variable_path, str(bp_index)))
        )

    # generate batch script for all breakpoints - one execution per input
    input_debug_script = _get_batch_debug_script(
        code_target=repository_path,
        breakpoints=breakpoints,
        breakpoint_variables=bp_target_variables,
        input_file=test_input,
    )

    # create single script
    debug_script_file_path = os.path.join(debug_script_path, f"batch.lldb")
    print(debug_script_file_path)
    with open(debug_script_file_path, "w") as fp:
        fp.write(input_debug_script)

    # run script and manage timeout
    # normal command
    # lldb --batch --source $DEBUG_SCRIPT_FILEPATH $EXECUTION_TARGET

    # run single script then process the output and create separate result
    try:
        output_capture = StringIO()

        process = subprocess.run(
            [
                "lldb",
                "--batch",
                "--source",
                debug_script_file_path,
                execution_target,
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=LLDB_TIMEOUT_SEC,
            text=True,
        )

        output_capture.write(process.stdout)
        debug_output_content = output_capture.getvalue().splitlines()
        output_capture.close()

        # inspect debug_output_content,
        # if anyline starts with "error: " or "WARNING", set found_lldb_error = 1
        if any(
            [
                l
                for l in debug_output_content
                if l.strip().startswith("error:") or l.strip().startswith("WARNING:")
            ]
        ):
            found_lldb_error = 1

        # NOTE keep aggregated result for inspection
        with open(f"{debug_output_path}/batch", "w") as debug_output:
            debug_output.write("\n".join(debug_output_content))

        bp_execution_trace = []

        # create empty debug file for every breakpoint
        for bp_index, _ in enumerate(breakpoints):
            open(f"{debug_output_path}/{bp_index}", "w").close()

        def append_bp_file(debug_lines: list, bp_index: int):
            global debug_output_path
            with open(f"{debug_output_path}/{bp_index}", "a") as debug_output:
                debug_output.write("\n".join(debug_lines) + "\n")

        # process batch output, split into target debug file
        # find line "(lldb)  frame info", collect all line afterword (must have "(lldb) continue" as last line)
        # check last token e.g., buggy.c:19:23 in the line following "(lldb)  frame info"
        # split last token and get line number, check bp_index in breakpoints
        # lookup "breakpoints" to get bp_index and append collected lines to target file
        debug_chunk = []
        cur_bp_index = -1  # impossible bp
        total_line = len(debug_output_content)
        for ln, debug_line in enumerate(debug_output_content):

            # update cur_bp_index
            if debug_line.strip().startswith("frame #"):
                bp_info = debug_line.split(" ")[-1]
                bp_file = bp_info.split(":")[0]
                bp_line = bp_info.split(":")[1]

                # lookup breakpoint to get cur_bp_index
                # beware that lldb bp_info might not be absolute path, just use a fair comparison
                for bp_index, bp in enumerate(breakpoints):
                    if bp[0].endswith(bp_file) and int(bp[1]) == int(bp_line):
                        cur_bp_index = bp_index
                        break

            # update current_chunk
            debug_chunk.append(debug_line)

            # reached last line, write to current chunk file
            if ln == total_line - 1 and cur_bp_index != -1:
                append_bp_file(debug_lines=debug_chunk, bp_index=cur_bp_index)

            # starting new chunk, write to current chunk and reset
            if debug_line.strip() == "(lldb)  frame info" and cur_bp_index != -1:
                append_bp_file(debug_lines=debug_chunk, bp_index=cur_bp_index)
                debug_chunk = []
                cur_bp_index = -1

    except Exception as ex:
        print("lldb exception", str(ex))
        found_lldb_error = True

    return_code = 0
    if found_lldb_error:
        return_code = 1

    sys.exit(return_code)
