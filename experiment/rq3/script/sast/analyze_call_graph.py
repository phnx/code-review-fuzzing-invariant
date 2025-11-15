# create static call graph to anazlyze relationship of the breakpoints
# to check if other breakpoints can call / be called by buggy breakpoints
# can be part of discussion

# run this file in sast path after
# export BIC_REPOSITORY_PATH=/experiment/repo/bic

import json
import argparse
import os
import shutil
from typing import List
import csv
from io import StringIO
import subprocess

from tree_sitter import Parser, Node, Tree
from tree_sitter_languages import get_language


def _parse_csv_line(line: str) -> list:
    reader = csv.reader(StringIO(line))
    return next(reader)


def _get_breakpoint_information(file_path: str) -> list:
    breakpoints = []
    breakpoint_lines = []
    with open(file_path) as file:
        breakpoint_lines = [
            line.rstrip() for line in file if not line.strip().startswith("#")
        ]

    for bp in breakpoint_lines:
        bp_items = _parse_csv_line(bp)

        if len(bp_items) >= 2:
            bp_file, bp_line = bp_items[:2]

            breakpoints.append((bp_file, int(bp_line.strip())))

    return breakpoints


# find all sub AST nodes by type
def find_ast_node(node: Node, target_type: str) -> list:
    nodes = []
    if node.type == target_type:
        nodes.append(node)
    for child in node.children:
        nodes.extend(find_ast_node(child, target_type))
    return nodes


# get caller callee list
def get_caller_callee_mapping(source_code: bytes) -> dict:
    tree = parser.parse(source_code)
    root = tree.root_node

    mapping = {}  # caller → [callee list]

    def walk(node, current_function=None):
        if node.type in ["function_definition"]:
            # get function name
            # just one level is information enough
            decl = node.child_by_field_name("declarator")
            func_name = decl.text.decode("utf-8").split("(")[0]
            current_function = func_name
            mapping[current_function] = []

        elif node.type == "call_expression":
            function_node = node.child_by_field_name("function")
            callee = function_node.text.decode("utf-8").split("(")[0]
            if current_function:
                mapping.setdefault(current_function, []).append(callee)

        for child in node.children:
            walk(child, current_function)

    walk(root)
    return mapping


# # small number / use manual check
# def get_transitive_callees(caller_map: dict, start_func: str, visited=None):
#     if visited is None:
#         visited = set()

#     callees = caller_map.get(start_func, [])
#     result = set()

#     for callee in callees:
#         if callee not in visited:
#             visited.add(callee)
#             result.add(callee)
#             result.update(get_transitive_callees(caller_map, callee, visited))
#     return result


def get_function_ranges(source_code: bytes):
    tree = parser.parse(source_code)
    root = tree.root_node

    function_ranges = {}  # function_name → (start_line, end_line)

    def walk(node):
        if node.type == "function_definition":
            # just one level is information enough
            decl = node.child_by_field_name("declarator")

            func_name = decl.text.decode("utf-8").split("(")[0]
            start_line = node.start_point[0] + 1  # 0-based to 1-based
            end_line = node.end_point[0] + 1
            function_ranges[func_name] = (start_line, end_line)

        for child in node.children:
            walk(child)

    walk(root)
    return function_ranges


if __name__ == "__main__":

    parser = Parser()
    CPP_LANGUAGE = get_language("cpp")
    parser.set_language(CPP_LANGUAGE)

    targets = [
        "arrow-40653",
        "aspell-18462",
        "curl-8000",
        "exiv2-50315",
        "file-30222",
        "grok-28418",
        "harfbuzz-55779",
        "leptonica-25212",
        "libarchive-44843",
        "libhtp-17198",
        "libxml2-17737",
        "ndpi-49057",
        "openh264-26220",
        "openssl-17715",
        "pcapplusplus-23592",
        "readstat-13262",
        "usrsctp-18080",
        "zstd-21970",
    ]

    for target in targets:
        # fetch target repo for source code access
        subprocess.run(["rm", "-rf", "/experiment/repo"])
        subprocess.run(["mkdir", "-p", "/experiment/repo"])
        subprocess.run(["bash", f"/experiment_data_sast/{target}/sast_prep.sh"])

        # bp targets
        bp_file_count = 0
        bp_function_count = 0

        # read BIC breakpoints
        breakpoints = _get_breakpoint_information(
            file_path=f"/experiment_data_sast/{target}/target_commit_info/bic_breakpoints"
        )

        print(breakpoints)

        target_files_bp = list(set([bp[0] for bp in breakpoints]))
        bp_file_count = len(target_files_bp)

        # collect target information
        function_range = {}

        # cleanup target path
        function_call_path = f"/experiment_data_sast/{target}/sast/function_call_info"
        shutil.rmtree(function_call_path, ignore_errors=True)
        os.makedirs(function_call_path, exist_ok=True)

        # function call information to associate BPs
        for target_file_bp in target_files_bp:

            print(target_file_bp)
            file_content: str = ""
            with open(f"/experiment/repo/bic/{target_file_bp}", "r") as target_file:
                file_content = target_file.read()

            # parsing function to identify target file / function / block
            # file_tree = parser.parse(file_content.encode())
            # function_tree = find_ast_node(
            #     node=file_tree.root_node, target_type="call_expression"
            # )
            # func: Node

            caller_callee_mapping = get_caller_callee_mapping(
                source_code=file_content.encode()
            )
            functions_with_range = get_function_ranges(
                source_code=file_content.encode()
            )

            # bp file function ranges
            if target_file_bp not in function_range.keys():
                function_range[target_file_bp] = []

            # store the list of caller / callees

            # get bp information in specific file
            # {bp_number: information}
            bp_information = {
                str(i): {"bp_line": bp[1]}
                for i, bp in enumerate(breakpoints)
                if bp[0] == target_file_bp
            }

            # map bp to function
            for func_name, func_lines in functions_with_range.items():

                func_start = func_lines[0]
                func_end = func_lines[1]

                # append function start - end line to bp
                for bp_number, bp_info in bp_information.items():
                    if (
                        bp_info["bp_line"] >= func_start
                        and bp_info["bp_line"] <= func_end
                    ):
                        bp_information[bp_number]["func_name"] = func_name
                        bp_information[bp_number]["func_start"] = func_start
                        bp_information[bp_number]["func_end"] = func_end

            print(bp_information)
            function_range[target_file_bp].append(bp_information)

            print(functions_with_range)

            print(caller_callee_mapping)

            # write output text
            with open(
                f"{function_call_path}/bp_function_info.txt",
                "a",
            ) as output_fp:
                output_fp.write("=====================\n")
                output_fp.write(f"{target_file_bp}\n")
                output_fp.write("=====================\n")
                output_fp.write(json.dumps(bp_information, indent=4))
                output_fp.write("\n\n")

            with open(
                f"{function_call_path}/functions_range.txt",
                "a",
            ) as output_fp:
                output_fp.write("=====================\n")
                output_fp.write(f"{target_file_bp}\n")
                output_fp.write("=====================\n")
                output_fp.write(json.dumps(functions_with_range, indent=4))
                output_fp.write("\n\n")

            with open(
                f"{function_call_path}/caller_callee_map.txt",
                "a",
            ) as output_fp:
                output_fp.write("=====================\n")
                output_fp.write(f"{target_file_bp}\n")
                output_fp.write("=====================\n")
                output_fp.write(json.dumps(caller_callee_mapping, indent=4))
                output_fp.write("\n\n")

    print("done")
