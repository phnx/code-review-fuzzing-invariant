# locate changed function based on file content and patch
# generate commit-changes in stdout

import sys
import argparse
from pathlib import Path

from git import Repo, Diff
import lizard
from lizard import FunctionInfo
import whatthepatch


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


if __name__ == "__main__":

    # expect path to repository
    repository_path = sys.argv[1]
    exit_code: int = 1

    repository_path = repository_path.rstrip("/")

    # access repository to obtain changes
    repo = Repo(repository_path)
    commits_list = list(repo.iter_commits())
    current_commit = commits_list[0]

    diffs = current_commit.diff("HEAD~1", create_patch=True)

    diff: Diff
    # read each of the changed files
    for diff in diffs:

        raw_parsed_patch = list(whatthepatch.parse_patch(diff.diff.decode()))
        new_lines = []
        # new_lines = [
        #     changed_line.new
        #     for diff in raw_parsed_patch
        #     for changed_line in diff.changes
        #     # remove empty line
        #     if str(changed_line.line).strip() != "" and changed_line.new is not None
        # ]

        # update, keep references from old diff to maintain a complete change set including deleted only lines,
        old_lines = [
            changed_line.old
            for diff in raw_parsed_patch
            for changed_line in diff.changes
            # remove empty line
            if str(changed_line.line).strip() != "" and changed_line.old is not None
        ]

        new_lines = sorted(list(set(new_lines + old_lines)))
        # print("complete line in file ============")
        # print(diff.b_path, new_lines)
        # print(old_lines)

        # check b file extension, must not be a deleted file
        changed_file = diff.b_path

        if changed_file is not None and is_changed_file_source_code(
            filename=changed_file
        ):
            exit_code = 0

            # complete file information, function extraction
            file_information = lizard.analyze_file.analyze_source_code(
                changed_file,
                get_file_content(f"{repository_path}/{changed_file}"),
            )

            func: FunctionInfo
            for func in file_information.function_list:
                # if changed_line in func.start_line, func.end_line
                # get ranges of changed lines in a function
                changed_lines_in_function = [
                    line_number
                    for line_number in new_lines
                    if line_number >= func.start_line and line_number <= func.end_line
                ]
                if any(changed_lines_in_function):
                    # NOTE change to short name if CodeQL cannot query complete signature
                    # func_name = func.long_name.split("(")[0]
                    func_name = func.long_name

                    # print changed file and function in format
                    # "file_name","function_name","change-lines","function_nloc","function_token_count","function_param_count","function_cyclomatic_complexity"
                    changed_lines_string = "-".join(
                        [str(l) for l in changed_lines_in_function]
                    )

                    print(
                        f'"{func.filename}","{func_name}","{changed_lines_string}","{func.nloc}","{func.token_count}","{func.parameter_count}","{func.cyclomatic_complexity}"'
                    )

    sys.exit(exit_code)
