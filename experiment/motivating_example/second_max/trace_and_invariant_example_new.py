# this script simulates execution traces for mining likely invariants and calculating distances
# demonstrate the how distance measure can reflect the actual traces and likely invariants

# must run this file from motivating_example path

# from ..analyzer.analyze_invariants_thread import DigInvariant

import random
import os
import sys
import random
import shutil
import subprocess
import json

import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl
from scipy.stats import mannwhitneyu

sys.path.append(os.path.abspath(".."))

from analyzer.analyze_invariants_thread import (
    process_single_invariant_file,
    calculate_metric_scores,
)

random.seed(27)
DIG_TIMEOUT_SEC = 300


def chance(ratio: float = 0.5) -> bool:
    return True if random.random() < ratio else False


def target_program_imitation(
    initial_trace: list, buggy_version: bool, arr: list
) -> list:

    trace = initial_trace

    max_val, second = -sys.maxsize, -sys.maxsize
    for cnt, val in enumerate(arr):
        # imitate the target program version
        if not buggy_version:
            if val > max_val:
                second = max_val
                max_val = val
            elif val > second and val < max_val:
                second = val
        else:
            second = (
                second
                if val > max_val
                else (val if val > second and val < max_val else second)
            )
            max_val = val if val > max_val else max_val

        trace.append(f"dummy; {cnt}; {max_val}; {second}; {val};")

    return trace


def generate_array(size: int = 5, reveal_bug: bool = False):

    # random 5 numbers from certain range
    size_1 = random.randint(1, 20)
    size_2 = random.randint(21, 40)
    size_3 = random.randint(41, 60)
    size_4 = random.randint(61, 80)
    size_5 = random.randint(81, 100)

    if reveal_bug:
        # forces incorrect second max updates in buggy version
        arr = [size_1, size_2, size_3, size_4, size_5]
    else:
        # ensures second max updates correctly even in buggy version
        arr = [size_5, size_4, size_2, size_3, size_1]

    # extend array randomly if needed, make sure any extension is smaller real second_max
    while len(arr) < size:
        arr.append(random.randint(1, size_3))

    return arr[:size]


def generate_traces(
    size: int = 5, example_type: str = "same_version", revealing_ratio: float = 0.5
) -> tuple:
    # example_type == same_version
    # [excluded] case 1: simulate a pair of trace "from any inputs" in buggy version
    # example_type == cross_version
    # case 2: simulate a pair of trace "from same input" in clean and buggy version
    # expecting that some mutated trace_b should display the different behavior of the buggy version

    buggy_label = False

    trace_a = ["dummy; I count_; I max_; I second_; I arr_val_;"]
    trace_b = ["dummy; I count_; I max_; I second_; I arr_val_;"]

    # NOTE same_version excluded
    if example_type == "same_version":
        # generate two arrays for two traces
        arr1 = generate_array(size=size, reveal_bug=chance(ratio=0.5))
        arr2 = generate_array(size=size, reveal_bug=chance(ratio=0.5))

        trace_a = target_program_imitation(
            initial_trace=trace_a, buggy_version=True, arr=arr1
        )
        trace_b = target_program_imitation(
            initial_trace=trace_b, buggy_version=True, arr=arr2
        )

    else:
        # generate one array for two traces
        reveal_bug = chance(ratio=revealing_ratio)
        buggy_label = reveal_bug

        arr = generate_array(size=size, reveal_bug=reveal_bug)
        trace_a = target_program_imitation(
            initial_trace=trace_a, buggy_version=False, arr=arr
        )
        trace_b = target_program_imitation(
            initial_trace=trace_b, buggy_version=True, arr=arr
        )

    return ("\n".join(trace_a), "\n".join(trace_b), buggy_label)


def write_trace_file(trace_content: str, trace_file_path: str):
    with open(trace_file_path, "w") as fp:
        fp.write(trace_content)


def mine_invariant(trace_file_path: str, invariant_file_path):
    with open(invariant_file_path, "w") as invariant_output:
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
                    "--seed",
                    "27",
                ],
                stdout=invariant_output,
                stderr=invariant_output,
            )
            process.wait(timeout=DIG_TIMEOUT_SEC)
        except subprocess.TimeoutExpired:
            print("DIG timeout")
            process.kill()
            process.wait()


def calcualte_distances(invariant_file_a: str, invariant_file_b: str) -> list:
    invariant_a = process_single_invariant_file(inv_file_path=invariant_file_a)
    invariant_b = process_single_invariant_file(inv_file_path=invariant_file_b)

    # mean similarity is equivalent to distance with one pair of invariant sets
    pair_distance = calculate_metric_scores(
        input_invariants=[invariant_a, invariant_b],
        bp_raw_score_path="example/unused_temp",
    )

    return pair_distance


if __name__ == "__main__":

    max_iteration = 400

    # cleanup
    shutil.rmtree(f"./example/test_program/cross_version_ratio_10", ignore_errors=True)
    shutil.rmtree(f"./example/test_program/cross_version_ratio_20", ignore_errors=True)
    shutil.rmtree(f"./example/test_program/cross_version_ratio_30", ignore_errors=True)
    shutil.rmtree(f"./example/test_program/cross_version_ratio_40", ignore_errors=True)
    shutil.rmtree(f"./example/test_program/cross_version_ratio_50", ignore_errors=True)

    # simulate
    os.makedirs(f"./example/test_program/cross_version_ratio_10", exist_ok=True)
    os.makedirs(f"./example/test_program/cross_version_ratio_20", exist_ok=True)
    os.makedirs(f"./example/test_program/cross_version_ratio_30", exist_ok=True)
    os.makedirs(f"./example/test_program/cross_version_ratio_40", exist_ok=True)
    os.makedirs(f"./example/test_program/cross_version_ratio_50", exist_ok=True)

    # exclude same_version, results show that buggy version's distance
    # is larger than non-bugger version's distance, but the hypothesis
    # does not hold in real dataset
    # examples = ["same_version", "cross_version"]
    examples = [
        "cross_version_ratio_10",
        "cross_version_ratio_20",
        "cross_version_ratio_30",
        "cross_version_ratio_40",
        "cross_version_ratio_50",
    ]

    for example_type in examples:
        example_path = f"example/test_program/{example_type}"

        ratio = int(example_type.split("_")[-1])
        revealing_chance: float = ratio * 0.01

        # following steps must be run in loops, the best results will be retained
        distance_results = f"{example_path}/distance_results"
        summary = f"{example_path}/summary"

        distances = []

        max_metrics = {
            "dice": -1,
            "hamming": -1,
            "jaccard": -1,
            "overlap_coefficient": -1,
        }
        min_metrics = {
            "dice": 2,
            "hamming": 2,
            "jaccard": 2,
            "overlap_coefficient": 2,
        }

        # which pair contains buggy behavior in buggy version
        buggy_label = []

        # mine invariant
        for i in range(max_iteration):
            print(
                revealing_chance,
                "invariant iteration",
                (i + 1),
                "out of",
                max_iteration,
            )

            trace_a_file = f"{example_path}/trace_a_{i}"
            trace_b_file = f"{example_path}/trace_b_{i}"
            invariant_a_file = f"{example_path}/invariant_a_{i}"
            invariant_b_file = f"{example_path}/invariant_b_{i}"

            # mutate trace
            trace_a, trace_b, is_revealing_bug = generate_traces(
                size=random.randint(5, 10),
                example_type=example_type,
                revealing_ratio=revealing_chance,
            )
            buggy_label.append(is_revealing_bug)

            # write temp trace file
            write_trace_file(trace_file_path=trace_a_file, trace_content=trace_a)
            write_trace_file(trace_file_path=trace_b_file, trace_content=trace_b)

            # mine invaraint and save to file
            mine_invariant(
                trace_file_path=trace_a_file, invariant_file_path=invariant_a_file
            )
            mine_invariant(
                trace_file_path=trace_b_file, invariant_file_path=invariant_b_file
            )

            # ensure no dangling subprocesses
            subprocess.run(["kill", "-9", "-1"])

        # single pairs measure - only works for cross-version
        for i in range(max_iteration):

            invariant_a_file = f"{example_path}/invariant_a_{i}"
            invariant_b_file = f"{example_path}/invariant_b_{i}"

            print(
                revealing_chance, "distance iteration", (i + 1), "out of", max_iteration
            )

            # read invariant and calculate distances in two ways
            # [excluded] case 1) same_version: calculating distance among different pair of trace "from any inputs" in buggy version
            # case 2) cross_version: calculating distance among the pair of trace "from same input" in clean and buggy version
            pair_distances = calcualte_distances(
                invariant_file_a=invariant_a_file, invariant_file_b=invariant_b_file
            )

            # collect max-min just for additional information
            distance_dict = {}
            for d in pair_distances:
                k, v = list(d.items())[0]
                distance_dict[k] = v

            for metric in max_metrics.keys():
                max_metrics[metric] = max(max_metrics[metric], distance_dict[metric])
                min_metrics[metric] = min(min_metrics[metric], distance_dict[metric])

            distances.append(pair_distances)

        # store distances
        for i, distance in enumerate(distances):
            is_b_buggy = buggy_label[i]
            with open(distance_results, "a") as fp:
                fp.write(f"{i} {'buggy' if is_b_buggy else 'non_buggy'} {distance}\n")

        # distribution plot
        plot_result_file = f"{example_path}/distribution"

        # reshape data for kdeplot
        value_list = {}
        buggy_list = {}

        # pallete dict
        hue_order = ["yes", "no"]
        palette = sns.color_palette("tab10", n_colors=len(hue_order))
        palette_dict = dict(zip(hue_order, palette))

        # fig, axes = plt.subplots(1, 1, figsize=(10, 8), sharey=True)
        fig, axes = plt.subplots(4, 1, figsize=(10, 8))
        axes = axes.flatten()

        # prepare data for violinplot for each metric,
        # each side for is_b_buggy = 0 (normal pair) or 1 (buggy pair)
        # a bit redundant with above loop, but more tidy
        for i, pair_distances in enumerate(distances):

            distance_dict = {}
            for d in pair_distances:
                k, v = list(d.items())[0]
                distance_dict[k] = v

            is_b_buggy = buggy_label[i]

            for metric in distance_dict.keys():
                if metric not in value_list.keys():
                    value_list[metric] = []
                    buggy_list[metric] = []

                value_list[metric].append(distance_dict[metric])
                buggy_list[metric].append("yes" if is_b_buggy else "no")

        # plot four metrics in one row
        # sns.violinplot(
        #     x="metric",
        #     y="value",
        #     hue="buggy",
        #     data=df,
        #     ax=axes,
        #     legend=True,
        #     split=True,
        # )

        for i, metric in enumerate(value_list.keys()):
            # putting list in dataframe
            df = pd.DataFrame(
                {
                    "metric": [metric] * len(value_list[metric]),
                    "value": value_list[metric],
                    "buggy": buggy_list[metric],
                }
            )

            # run mann-whitney u-test on buggy / non_buggy values
            u_buggy_diff, p_buggy_diff = mannwhitneyu(
                df[df["buggy"] == "yes"]["value"].tolist(),
                df[df["buggy"] == "no"]["value"].tolist(),
                alternative="two-sided",
            )
            u_buggy_greater, p_buggy_greater = mannwhitneyu(
                df[df["buggy"] == "yes"]["value"].tolist(),
                df[df["buggy"] == "no"]["value"].tolist(),
                alternative="greater",
            )

            # save test result
            with open(f"{example_path}/distribution_mwu_test", "a") as test_fp:
                test_fp.write(
                    f"metric: {metric}, two-sided Ubuggy: {u_buggy_diff}, p-value: {p_buggy_diff}\n"
                )
                test_fp.write(
                    f"metric: {metric}, greater Ubuggy: {u_buggy_greater}, p-value: {p_buggy_greater}\n"
                )
                test_fp.write(f"====================\n")

            sns.kdeplot(
                data=df,
                x="value",
                hue="buggy",
                ax=axes[i],
                legend=True,
                hue_order=hue_order,
                palette=palette_dict,
                fill=True,
            )

            axes[i].set_title(f"{metric}")
            axes[i].set_xlabel("Distance")
            axes[i].set_ylabel("Density")

        plt.tight_layout()
        plt.savefig(plot_result_file)

        print("max")
        print(max_metrics)
        print("min")
        print(min_metrics)

        with open(summary, "w") as fp:
            fp.write("max\n")
            fp.write(json.dumps(max_metrics, indent=4))
            fp.write("\n\n")
            fp.write("min\n")
            fp.write(json.dumps(min_metrics, indent=4))

    # TODO after running simulation, walkthrough the invariant can the distances, understand how the results are being so
    # make a conclusion 1) what are the characteristics of buggy invariants compared to normal invariants?
    # keep the hypothesis abstract, with possibility

    print("DONE")
