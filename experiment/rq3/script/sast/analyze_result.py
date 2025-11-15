# analyze SAST warnings at file / function / block level
# this script counts the warnings in target file / function and code block

# run this file in sast path

import json
import argparse
from typing import List
import csv
from io import StringIO
import subprocess

from tree_sitter import Parser, Node
from tree_sitter_languages import get_language
from SATResult import SATResult

import codechecker.result_reader as codechecker_reader
import codeql.result_reader as codeql_reader
import flawfinder.result_reader as flawfinder_reader


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


# TODO fix dataflow extraction - still not working correctly
def extract_data_flow(node, variables={}):
    if node.type == "declaration":
        var_name = [
            n.text.decode()
            for n in node.child_by_field_name("declarator").children
            if n.type == "identifier"
        ]
        if len(var_name) != 0:
            variables[var_name[0]] = {"defined": node.start_point, "used": []}
    elif node.type == "assignment_expression":
        var_name = node.child(0).text.decode()
        if var_name in variables:
            variables[var_name]["used"].append(node.start_point)
    for child in node.children:
        extract_data_flow(child, variables)
    return variables


# return smallest code block (start_line, end_line) that contain a warning
# multiple code blocks can be merged in case of multiple warning lines
# if warnings are in multiple lines, they must be consecutive. hence, one final block
def map_warning_to_granular_code(warning_lines: tuple, block_lines: list) -> list:
    warned_blocks = []

    warned_blocks.extend(
        [
            g
            for g in block_lines
            if (g[0] <= warning_lines[0] and g[1] >= warning_lines[0])
            or (g[0] <= warning_lines[1] and g[1] >= warning_lines[1])
        ]
    )

    return warned_blocks


# return basic code block lines of a function that contain changed code
def get_relevant_blocks(
    bp_lines: tuple,
    target_file_bp: str,
    breakpoints: list,
    function: Node,
    method: str = "ast",
) -> list:
    statement_types = [
        "compound_statement",
        "if_statement",
        "for_statement",
        "switch_statement",
        "while_statement",
        "do_statement",
        "case_statement",
        "try_statement",
    ]

    target_blocks = []

    # identify bp_number (index of bp in breakpoints) using target_file_bp and bp_line
    bp0_number = breakpoints.index((target_file_bp, int(bp_lines[0])))
    bp1_number = breakpoints.index((target_file_bp, int(bp_lines[1])))

    assert bp0_number == bp1_number

    # func_start = function.start_point[0] + 1
    # func_end = function.end_point[0] + 1
    # print("function start - end lines", func_start, func_end)
    if method == "ast":
        # ast mapping
        blocks = {type: find_ast_node(function, type) for type in statement_types}
        block_lines = set()
        groomed_block_lines = []
        for _, block in blocks.items():
            if len(block) != 0:
                # print(type, len(block))
                blocks = [(b.start_point[0] + 1, b.end_point[0] + 1) for b in block]
                block_lines.update(blocks)
        # remove biggest block that cover entire function
        # should not map a warning to since it's redundant with function granularity
        complete_function_block = (len(file_content.split("\n")) + 100, -1)
        for block in block_lines:
            if (
                block[0] <= complete_function_block[0]
                and block[1] >= complete_function_block[1]
            ):
                complete_function_block = block
        # print("biggest block", complete_function_block)
        # multiple sub-blocks, consider the non-block consecutive lines as a block
        if len(block_lines) > 1:
            block_lines.remove(complete_function_block)
            block_lines = sorted(
                list(block_lines),
                key=lambda x: x[0],
            )
            merged_blocks = []
            # sort and merge overlapping, contiguous, and nested ranges
            for start, end in block_lines:
                if (
                    merged_blocks and merged_blocks[-1][1] >= start - 1
                ):  # overlapping or contiguous
                    merged_blocks[-1] = (
                        merged_blocks[-1][0],
                        max(merged_blocks[-1][1], end),
                    )  # merge
                else:
                    merged_blocks.append((start, end))
            start = complete_function_block[0]
            end = complete_function_block[1]
            prev_end = start - 1  # start filling lines from a complete block
            for cur_start, cur_end in merged_blocks:
                if prev_end + 1 < cur_start:
                    groomed_block_lines.append(
                        (prev_end + 1, cur_start - 1)
                    )  # fill the gap
                groomed_block_lines.append((cur_start, cur_end))
                prev_end = cur_end
            if prev_end < end:  # fill remaining gap at the end
                groomed_block_lines.append((prev_end + 1, end))

        # which blocks contains target code
        target_blocks = [
            g
            for g in groomed_block_lines
            if g[0] <= bp_lines[1] and g[1] >= bp_lines[0]
        ]

    elif method == "dataflow":
        pass
        # TODO dataflow mapping
        # block_vars = {}
        # block_vars = extract_data_flow(function, variables=block_vars)
        # print(block_vars)

    # append bp_number in every hit block
    return [(b[0], b[1], bp0_number) for b in target_blocks]


if __name__ == "__main__":

    # parser = argparse.ArgumentParser()

    # parser.add_argument(
    #     "--tool",
    #     help="tool name",
    #     default="",
    # )
    # parser.add_argument(
    #     "--target",
    #     help="target name",
    #     default="",
    # )

    # args = parser.parse_args()

    # # receive invariant_output_path
    # target = args.target
    # tool = args.tool

    parser = Parser()
    CPP_LANGUAGE = get_language("cpp")
    parser.set_language(CPP_LANGUAGE)

    tools = ["codechecker", "codeql", "flawfinder"]
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

    readers = {
        "codechecker": codechecker_reader,
        "codeql": codeql_reader,
        "flawfinder": flawfinder_reader,
    }

    result_extenstion = {
        "codechecker": "json",
        "codeql": "sarif",
        "flawfinder": "sarif",
    }

    for target in targets:
        # fetch target repo for source code access
        subprocess.run(["rm", "-rf", "/experiment/repo"])
        subprocess.run(["mkdir", "-p", "/experiment/repo"])
        subprocess.run(["bash", f"/experiment_data_sast/{target}/sast_prep.sh"])

        # bp targets
        bp_file_count = 0
        bp_function_count = 0
        bp_block_count = 0

        # read BIC breakpoints
        breakpoints = _get_breakpoint_information(
            file_path=f"/experiment_data_sast/{target}/target_commit_info/bic_breakpoints"
        )

        target_files_bp = list(set([bp[0] for bp in breakpoints]))
        bp_file_count = len(target_files_bp)

        # collect target information
        function_range = {}
        block_range = {}
        # function / AST warnings for finer-grained detection analysis
        for target_file_bp in target_files_bp:

            # print(target_file_bp)
            file_content: str = ""
            with open(f"/experiment/repo/bic/{target_file_bp}", "r") as target_file:
                file_content = target_file.read()

            # parsing function to identify target file / function / block
            file_tree = parser.parse(file_content.encode())
            function_tree = find_ast_node(
                node=file_tree.root_node, target_type="function_definition"
            )
            func: Node

            # bp file function ranges
            if target_file_bp not in function_range.keys():
                function_range[target_file_bp] = []
                block_range[target_file_bp] = []

            # get bp lines in specific file
            bp_lines = [bp[1] for bp in breakpoints if bp[0] == target_file_bp]
            # print(bp_lines)

            # only collect funcion ranges that contain bps
            for func in function_tree:
                func_start = func.start_point[0] + 1
                func_end = func.end_point[0] + 1

                if any([b for b in bp_lines if b >= func_start and b <= func_end]):
                    function_range[target_file_bp].append((func_start, func_end))
                    bp_function_count += 1

                    # collect target function blocks where bps are
                    # TODO justify targetting block using selected bp is in favor of SAST e.g., reduce false positives
                    # bp block is selected based on debugging method to enable the direct comparison with SAST warnings
                    target_blocks = [
                        get_relevant_blocks(
                            (bp_line, bp_line),
                            target_file_bp=target_file_bp,
                            breakpoints=breakpoints,
                            function=func,
                        )
                        for bp_line in bp_lines
                    ]
                    flattened_list = [
                        item for sublist in target_blocks for item in sublist
                    ]

                    block_range[target_file_bp].extend(flattened_list)
                    block_range[target_file_bp] = list(set(block_range[target_file_bp]))

                    # print(f"Function found at line {func_start} - {func_end}")

        # print("target block range")
        # print(block_range)
        for bp_file, bp_file_blocks in block_range.items():
            bp_block_count += len(bp_file_blocks)

        # save target blocks in target project
        with open(
            f"/experiment_data_sast/{target}/target_commit_info/target_blocks.json", "w"
        ) as output_fp:
            json.dump(block_range, output_fp, indent=4)

        # per tool, warnings count
        for tool in tools:
            print("===================================")
            print("analyzing", tool, target)

            # count detection  scenari0
            bp_file_warning_count = 0
            bp_function_warning_count = 0
            bp_block_warning_count = 0
            total_warning_count = 0

            reader = readers[tool]

            results: List[SATResult] = reader.read_result(
                result_filename=f"/experiment_data_sast/{target}/sast/{tool}/result/result.{result_extenstion[tool]}"
            )

            result_dict = [r.to_dict() for r in results]
            total_warning_count = len(result_dict)

            # collect warned blocks in hit function
            target_warned_blocks = {}

            # filter warnings in breakpoint files, add function flag
            result_dict_target_files = []
            for r in result_dict:
                # if warning in bp file
                if r["location_file"] in target_files_bp:
                    r["warning_in_target_file"] = True

                    bp_file_warning_count += 1

                    # if warning in bp function, check function range
                    file_function_ranges = function_range[r["location_file"]]
                    target_function_block_ranges = block_range[r["location_file"]]

                    # match bp functions with warnings
                    if any(
                        [
                            f
                            for f in file_function_ranges
                            if (
                                f[0] <= r["location_start_line"]
                                and f[1] >= r["location_start_line"]
                            )
                            and (
                                f[1] >= r["location_end_line"]
                                and r["location_end_line"] != -1
                            )
                        ]
                    ):
                        r["warning_in_target_function"] = True
                        bp_function_warning_count += 1

                        # match warning using `compound_statement` element in AST
                        warned_blocks = map_warning_to_granular_code(
                            warning_lines=(
                                r["location_start_line"],
                                r["location_end_line"],
                            ),
                            block_lines=target_function_block_ranges,
                        )
                        if len(warned_blocks) > 0:
                            if r["location_file"] not in target_warned_blocks.keys():
                                target_warned_blocks[r["location_file"]] = []

                            # collect warned blocks
                            target_warned_blocks[r["location_file"]].append(
                                warned_blocks
                            )

                            # update r["warning_in_target_code_block"]
                            r["warning_in_target_code_block"] = True

                            # print("warning hit blocks", target_function_block_ranges)
                            bp_block_warning_count += 1

                    result_dict_target_files.append(r)

            column_names = []
            if len(result_dict) > 0:
                column_names = result_dict[0].keys()
            else:
                print("empty result")

            # DONE - NOT REWRITE
            # all warnings
            # with open(
            #     f"/experiment_data_sast/{target}/sast/{tool}/result/converted_result.csv",
            #     "w",
            #     newline="",
            # ) as output_fp:
            #     dict_writer = csv.DictWriter(output_fp, fieldnames=column_names)
            #     dict_writer.writeheader()
            #     dict_writer.writerows(result_dict)

            # DONE - NOT REWRITE
            # file warnings
            with open(
                f"/experiment_data_sast/{target}/sast/{tool}/result/converted_result_in_bp_file.csv",
                "w",
                newline="",
            ) as output_fp:
                dict_writer = csv.DictWriter(output_fp, fieldnames=column_names)
                dict_writer.writeheader()
                dict_writer.writerows(result_dict_target_files)

            # warned blocks
            with open(
                f"/experiment_data_sast/{target}/sast/{tool}/result/warned_blocks.json",
                "w",
            ) as output_fp:
                json.dump(target_warned_blocks, output_fp, indent=4)

            # write summary text
            with open(
                f"/experiment_data_sast/{target}/sast/{tool}/result/summary.txt",
                "w",
                newline="",
            ) as output_fp:
                output_fp.write(f"total warnings: {total_warning_count}\n")
                output_fp.write(
                    f"total warnings in target files: {bp_file_warning_count}\n"
                )
                output_fp.write(
                    f"total warnings in target functions: {bp_function_warning_count}\n"
                )
                output_fp.write(
                    f"total warnings in target blocks: {bp_block_warning_count}\n"
                )
                output_fp.write(f"total target files: {bp_file_count}\n")
                output_fp.write(f"total target functions: {bp_function_count}\n")
                output_fp.write(f"total target blocks: {bp_block_count}\n")

    print("done")
