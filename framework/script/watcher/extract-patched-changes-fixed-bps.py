# locate changed function based on file content and patch
# locate two breakpoints: before and after the patch

import re
import sys
import argparse
from pathlib import Path
import random

from git import Repo, Diff
import lizard
from lizard import FunctionInfo
import whatthepatch

# maximum number of breakpoints and variables
MAX_BREAKPOINTS = 10
MAX_BREAKPOINT_VARIABLES = 10

# offset for first bp, to prevent overlapping with second bp
FIRST_BP_OFFSET = 3


def get_file_content(file_path: str) -> str:
    return Path(file_path).read_text()


def is_changed_file_source_code(filename: str) -> bool:
    return filename.lower().split(".")[-1] in [
        "c",
        "h",
        "cpp",
        "cc",
        "cxx",
        "c++",
        "hpp",
        "hh",
        "hxx",
        "h++",
        "inc",
    ]


def _replace_comment(code):
    """
    Remove both single-line (//) and multi-line (/* */) comments from the code,
    replacing them with empty lines while preserving the line numbers.
    """
    # Replace multi-line comments with empty lines
    code = re.sub(
        r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"), code, flags=re.DOTALL
    )
    # Replace single-line comments with an empty line
    code = re.sub(r"//.*", "\n", code)

    return code


if __name__ == "__main__":

    # expect path to repository
    repository_path = sys.argv[1]

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--repository_path",
        help="path to repository, to get source code files",
        default="",
    )

    parser.add_argument(
        "--output_breakpoint_file",
        help="output file for storing selected breakpoint locations",
        default="",
    )

    args = parser.parse_args()

    # receive invariant_output_path
    repository_path = args.repository_path
    output_breakpoint_file = args.output_breakpoint_file

    repository_path = repository_path.rstrip("/")

    # storing output
    output_target_change = []
    output_breakpoint = []
    output_breakpoint_variables = []

    # access repository to obtain changes
    repo = Repo(repository_path)
    commits_list = list(repo.iter_commits())
    current_commit = commits_list[0]

    # diffs = current_commit.diff("HEAD~1", create_patch=True)
    # list unstaged changes (compared to working tree) from patch
    # https://gitpython.readthedocs.io/en/stable/reference.html?highlight=diffable#git.diff.Diffable.diff
    diffs = repo.index.diff(None, create_patch=True)

    diff: Diff
    # read each of the changed files
    for diff in diffs:
        raw_parsed_patch = list(whatthepatch.parse_patch(diff.diff.decode()))

        # new line numbers
        new_lines = [
            changed_line.new
            for diff in raw_parsed_patch
            for changed_line in diff.changes
            # remove empty line
            if str(changed_line.line).strip() != "" and changed_line.new is not None
        ]

        # check b file extension, must not be a deleted file
        changed_file = diff.b_path

        # print("new lines", changed_file, new_lines)

        if changed_file is None or not is_changed_file_source_code(
            filename=changed_file
        ):
            "change file is None or not a source code file, skip"
            continue

        changed_file_content = get_file_content(f"{repository_path}/{changed_file}")
        absolute_breakpoint_lines = []

        raw_file_content = changed_file_content.split("\n")
        for line_index, content_line in enumerate(raw_file_content):
            # patched BPs
            if 'asm("nop"); /* breakpoint */' in content_line:
                absolute_breakpoint_lines.append(line_index)

        print(changed_file, absolute_breakpoint_lines)

        sorted_absolute_breakpoint_lines = sorted(absolute_breakpoint_lines)
        for l_n in sorted_absolute_breakpoint_lines:
            output_breakpoint.append(f'"{changed_file}","{l_n + 1}"')

    # write breakpoints
    with open(output_breakpoint_file, "w") as fp:
        for l in output_breakpoint:
            fp.write(f"{l}\n")

    sys.exit(0)
