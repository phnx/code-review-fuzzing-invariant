# extract execution count on the changed function

import os
import json
import sys
import csv
from io import StringIO
from pathlib import Path
import subprocess

import cxxfilt


def _get_source_code_file_from_list(filenames: list) -> str:
    source_code_files_list = list(
        set(
            [
                f
                for f in filenames
                if f.lower().split(".")[-1]
                in [
                    "c",
                    "cpp",
                    "cc",
                    "cxx",
                    "c++",
                    "h",
                    "hpp",
                    "hh",
                    "hxx",
                    "h++",
                    "inc",
                    "incl_cpp",
                ]
            ]
        )
    )

    # expect single source code file name (exclude header files)
    assert len(source_code_files_list) > 0
    return source_code_files_list[0]


def _get_function_name(function_name: str) -> str:
    pure_function_name = function_name

    # function_name can be normal name or filename:function_name
    if not "::" in function_name:
        pure_function_name = function_name.split(":")[-1]

    demangled_function_name = ""
    try:
        demangled_function_name = cxxfilt.demangle(pure_function_name)
    except Exception:
        # in case of exception, try using cmd llvm-cxxfilt
        try:
            ret = subprocess.run(
                ["llvm-cxxfilt", pure_function_name],
                text=True,
                timeout=0.001,
                capture_output=True,
            )
            demangled_function_name = ret.stdout.strip()
        except subprocess.TimeoutExpired:
            demangled_function_name = ""

    final_function_name = demangled_function_name

    # mangled function name may require removing of params
    if demangled_function_name != function_name:
        final_function_name = final_function_name.split("(")[0].strip()

    return final_function_name


def _get_file_lines(file_path: str) -> list:
    content: str = Path(file_path).read_text()
    if content.strip() == "":
        return []
    return content.splitlines()


def _parse_csv_line(line: str) -> list:
    reader = csv.reader(StringIO(line))
    return next(reader)


def _get_changed_file_and_functions(commit_changes: list) -> list:
    changed_functions = []
    for cc in commit_changes:
        c_items = _parse_csv_line(cc)

        if len(c_items) >= 2:
            c_file, c_function = c_items[:2]
            changed_functions.append((c_file, c_function))

    return list(set(changed_functions))


if __name__ == "__main__":

    # receive execution report file and commit changes file from parent script
    commit_changes_path = sys.argv[1]
    execution_trace_path = sys.argv[2]

    # test
    # commit_changes_path = "output-exported/vcc/jbig2dec/reachability/c3134491a3010fcce440a45968407c6511766671/commit-changes"
    # execution_trace_path = "output-exported/vcc/jbig2dec/coverage/execution-trace.json"

    if not (
        os.path.isfile(commit_changes_path) and os.path.isfile(execution_trace_path)
    ):
        print("commit changes or execution trace does not exist")
        sys.exit(1)

    # read files
    commit_changes: list = _get_file_lines(file_path=commit_changes_path)
    execution_trace: dict = json.load(open(execution_trace_path))

    # get list of changed functions in a commit
    changed_functions = _get_changed_file_and_functions(commit_changes=commit_changes)

    # match hit functions with changed functions
    if (
        "data" in execution_trace.keys()
        and len(execution_trace["data"]) == 1
        and "functions" in execution_trace["data"][0].keys()
    ):

        for func in execution_trace["data"][0]["functions"]:
            file_name = _get_source_code_file_from_list(filenames=func["filenames"])
            func_name = _get_function_name(function_name=func["name"])

            if func_name == "":
                # skip function that cannot be demangled
                continue

            hit_count = func["count"]

            if hit_count > 0:
                for changed_function in changed_functions:
                    # TODO consider region start / end lines for accurate function signature
                    if (
                        file_name.endswith(
                            changed_function[0]
                        )  # remove absolute path (only compare from repository root)
                        and changed_function[1].split("(")[0].strip() == func_name
                    ):
                        # a changed function was executed
                        print(file_name, func_name, hit_count)

                        break

    sys.exit(0)
