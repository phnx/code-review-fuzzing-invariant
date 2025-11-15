# read DIG invariant files for comparison and clustering
# require sympy

import argparse
import os
import glob
from itertools import combinations
import pickle
import random
import hashlib
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
import multiprocessing
from multiprocessing import Queue

import numpy as np
from scipy.spatial.distance import hamming
from sympy import symbols
from sympy.parsing.sympy_parser import parse_expr
from tqdm import tqdm
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl
from dotenv import load_dotenv

import common

load_dotenv(dotenv_path="/script/framework_config.env")

# max invariant files to be analyzed (prevent OOM)
MAX_INV_FILES = int(os.getenv("MAXIMUM_BP_INVARIANTS_ANALYZED", 1500))

# max threads
MAX_THREADS = 8

# for reusing throughout script
metrics = ["dice", "hamming", "jaccard", "overlap_coefficient"]

# NOTE whethre or not to convert the invariant to DIG Object
# if True, pickle file will contain DigInvariant object,
# comparison will be robust because the object is parsed using SymPy
# if False, just compare raw invariant strings, but faster.. a lot faster
CONVERT_INVARIANT_TO_DIG_OBJECT = False


# each line of invariants is cast to this class for ease of management
class DigInvariant:
    lhs: str = ""
    rhs: str = ""
    comparator: str = ""
    modulo: int = None  # for comparator mod
    sha256: str = ""

    # possible math comparators
    condition_comparators = [" == ", " <= ", " >= ", " < ", " > "]

    def __init__(self, invariant_str: str):

        if " === " in invariant_str:
            # modulo
            # e.g., shift + syoffset === 0 (mod 2)
            splitter = " === "
            congruence = invariant_str.split(splitter)[0]

            modulo_data = invariant_str.split(splitter)[1]
            modulo = modulo_data.split(" ")[0]
            remainder = modulo_data.split(" ")[-1].lstrip(")")

            comparator = "mod"
            lhs = congruence
            rhs = remainder
            self.modulo = modulo

        elif any(e in invariant_str for e in self.condition_comparators):
            # math condition
            # e.g., (bytewidth, dd, h, leftbyte, shift, ss, w, x, y) - syoffset == 0
            for splitter in self.condition_comparators:
                if len(invariant_str.split(splitter)) > 1:
                    lhs = invariant_str.split(splitter)[0]
                    rhs = invariant_str.split(splitter)[1]
                    comparator = splitter.strip()

        else:
            print("Unsupported ", invariant_str)
            # empty lhs
            lhs = ""
            rhs = str(random.random() * 100000)
            comparator = "nan"

            # suppress exception in production, just produce a unique invariant
            # raise NotImplemented

        # object assignment
        self.comparator = comparator
        self.lhs = lhs
        self.rhs = rhs
        self.converted_lhs = None

        # NOTE this parsing can take long time
        if lhs != "":
            try:
                self.converted_lhs = parse_expr(lhs, evaluate=True).simplify()
            except Exception:
                print("cannot parse invariant:", lhs)
                exit(1)

        self.sha256 = self.sha256_hash()

    def __key(self):
        return (self.rhs, self.comparator, self.modulo, str(self.converted_lhs))

    def __hash__(self):
        return hash(self.__key())

    def sha256_hash(self):
        return hashlib.sha256(
            "_".join(
                (
                    str(self.converted_lhs),
                    self.rhs,
                    self.comparator,
                    "not_mod" if self.modulo is None else self.modulo,
                )
            ).encode("utf-8")
        ).hexdigest()

    # def __lt__(self, other):
    #     # TODO how to say one invariant comes before other invariant
    #     return (self.b) < (obj.b)

    def __eq__(self, other):

        if type(other) != type(self):
            raise ValueError

        return (
            self.comparator == other.comparator
            and self.converted_lhs == other.converted_lhs
            and self.rhs == other.rhs
            and self.modulo == other.modulo
        )

    def __repr__(self):
        return self.__str__()

    def __str__(self):
        return f"DIG Invariant type: {self.comparator}, {self.lhs}"


# =========================================================================


# NOTE copied from variable_analysis.py - unmodified
def read_file_lines(file_path: str) -> list:
    # print(file_path)
    lines = []
    with open(file_path, "rb") as fp:
        for line in fp:

            # ignore encoding error
            line = line.decode(errors="replace").strip()
            if line != "" and not line.startswith("#"):
                lines.append(line)

    return lines


# return list of invariant strings
def read_invariant_file(file_path: str) -> list:
    invariants = []

    with open(file_path, "rb") as fp:
        for line in fp:

            # ignore encoding error
            line = line.decode(errors="replace").strip()
            if line != "" and line[:1].isdigit():

                # "input" and "content" is Symbol word - post-hoc fix (already update generate_trace to prevent future cases)
                line = line.replace("input", "input_")
                line = line.replace("content", "content_")

                invariants.append(line.split(".")[-1].strip())

            # NOTE observe other possible results, decide to exclude or include
            # else:
            #     if not (
            #         line.strip().startswith("alg:")
            #         or line.strip().startswith("settings:")
            #         or line.strip().startswith("dummy ")
            #     ):
            #         print("Not included:", line)

    return invariants


# organize invariant objects separately to reduce bottleneck
def get_invariant_file_name(type: str, bp_number: str) -> str:
    return f"{stored_invariant_output_file}_{type}_at_bp_{bp_number}"


# =========================================================================
# diversity metrics - modified for pairwise comparison
def _metric_jaccard(input_invariants: list, tqdm_position: int) -> dict:
    def __metric_pair_jaccard(list1: list, list2: list) -> float:
        # jaccard index
        intersection = len(set(list1).intersection(list2))
        union = len(set(list1).union(list2))

        return intersection / union if union != 0 else 0.0

    print("calculating jaccard")
    similarities = []

    # only one side is blank -> 0 similarity
    if (len(input_invariants[0]) != 0 and len(input_invariants[1]) == 0) or (
        len(input_invariants[0]) == 0 and len(input_invariants[1]) != 0
    ):
        similarities = [0.0]

    else:
        coord_pairs = list(combinations(range(len(input_invariants)), 2))
        similarities = [
            __metric_pair_jaccard(input_invariants[p[0]], input_invariants[p[1]])
            for p in tqdm(iterable=coord_pairs, position=tqdm_position, desc="jaccard")
            if len(input_invariants[p[0]]) != 0 and len(input_invariants[p[1]]) != 0
        ]

    # return 1 - np.mean(similarities)
    return {"raw_scores": similarities, "mean_score": 1 - np.mean(similarities)}


def _metric_dice(input_invariants: list, tqdm_position: int) -> dict:
    def __metric_pair_dice(list1: list, list2: list) -> float:
        # Dice-Sorensen similarity
        intersection = len(set(list1).intersection(list2))
        return (
            2 * intersection / (len(list1) + len(list2))
            if len(list1) != 0 or len(list2) != 0
            else 0.0
        )

    print("calculating dice")
    similarities = []

    # only one side is blank -> 0 similarity
    if (len(input_invariants[0]) != 0 and len(input_invariants[1]) == 0) or (
        len(input_invariants[0]) == 0 and len(input_invariants[1]) != 0
    ):
        similarities = [0.0]

    else:
        coord_pairs = list(combinations(range(len(input_invariants)), 2))
        similarities = [
            __metric_pair_dice(input_invariants[p[0]], input_invariants[p[1]])
            for p in tqdm(coord_pairs, position=tqdm_position, desc="dice")
            if len(input_invariants[p[0]]) != 0 and len(input_invariants[p[1]]) != 0
        ]

    # return 1 - np.mean(similarities)
    return {"raw_scores": similarities, "mean_score": 1 - np.mean(similarities)}


def _metric_overlap_coefficient(input_invariants: list, tqdm_position: int) -> dict:
    def __metric_pair_overlap_coefficient(list1: list, list2: list) -> float:
        # Szymkiewicz-Simpson Coefficient
        intersection = len(set(list1).intersection(list2))
        return (
            intersection / min(len(list1), len(list2))
            if min(len(list1), len(list2)) != 0
            else 0.0
        )

    print("calculating overlap")
    coefficients = []

    # only one side is blank -> 0 similarity
    if (len(input_invariants[0]) != 0 and len(input_invariants[1]) == 0) or (
        len(input_invariants[0]) == 0 and len(input_invariants[1]) != 0
    ):
        coefficients = [0.0]

    else:
        coord_pairs = list(combinations(range(len(input_invariants)), 2))
        coefficients = [
            __metric_pair_overlap_coefficient(
                input_invariants[p[0]], input_invariants[p[1]]
            )
            for p in tqdm(coord_pairs, position=tqdm_position, desc="overlap")
            if len(input_invariants[p[0]]) != 0 and len(input_invariants[p[1]]) != 0
        ]

    # return 1 - np.mean(coefficients)
    return {"raw_scores": coefficients, "mean_score": 1 - np.mean(coefficients)}


def _metric_hamming(input_invariants: list, tqdm_position: int) -> dict:
    # hamming distance - using all invariants

    # number of maximum dimension of invariant vectors
    total_invariant_instances = sum([len(i) for i in input_invariants]) * len(
        input_invariants
    )

    # all invariant objects
    unified_invariants = list(set([i for i_list in input_invariants for i in i_list]))
    # bypass hashing if using raw invariant strings and object not having sha256 attribute
    if CONVERT_INVARIANT_TO_DIG_OBJECT or (
        len(unified_invariants) > 0 and hasattr(unified_invariants[0], "sha256")
    ):
        hashed_unified_invariants = [i.sha256 for i in unified_invariants]
    else:
        hashed_unified_invariants = unified_invariants

    # sort invariants
    hashed_unified_invariants = sorted(hashed_unified_invariants)

    # ensure that the pairs are sorted and position is sustained by encoding invariants into vector
    # create unused integers to fill as unique values
    data_encoded = []
    unused_index = [i for i in range(1, total_invariant_instances)]

    for input_invariant in input_invariants:
        # bypass hashing if using raw invariant strings and object not having sha256 attribute
        if CONVERT_INVARIANT_TO_DIG_OBJECT or (
            len(input_invariant) > 0 and hasattr(input_invariant[0], "sha256")
        ):
            current_invariant_set = [i.sha256 for i in input_invariant]
        else:
            current_invariant_set = [i for i in input_invariant]
        all_hashed_invariants = hashed_unified_invariants.copy()

        # matched invariant is encoded with -1 for uniqueness, other unmatched is filled with arbitrary index to sustain distance
        encoded_existing_invariants = [
            (-1 if kept_hash in current_invariant_set else unused_index.pop())
            for kept_hash in all_hashed_invariants
        ]
        data_encoded.append(encoded_existing_invariants)

    print("calculating hamming")
    hamming_distances = []

    # only one side is blank -> 1 different
    if (len(input_invariants[0]) != 0 and len(input_invariants[1]) == 0) or (
        len(input_invariants[0]) == 0 and len(input_invariants[1]) != 0
    ):
        hamming_distances = [1.0]

    else:
        coord_pairs = list(combinations(range(len(input_invariants)), 2))
        hamming_distances = [
            hamming(data_encoded[p[0]], data_encoded[p[1]])
            for p in tqdm(coord_pairs, position=tqdm_position, desc="hamming")
            if len(input_invariants[p[0]]) != 0 and len(input_invariants[p[1]]) != 0
        ]

    # return np.mean(hamming_distances)
    return {"raw_scores": hamming_distances, "mean_score": np.mean(hamming_distances)}


# use to manage queue
def _metric_wrapper(
    queue: Queue,
    metric_name: str,
    metric_function,
    input_invariants: list,
    tqdm_position: int,
):
    result = metric_function(
        input_invariants=input_invariants, tqdm_position=tqdm_position
    )

    try:
        # replace blank invariants (NaN) with -1, to be managed in analysis
        if np.isnan(result["mean_score"]):
            queue.put({metric_name: -1.0})
        else:
            queue.put({metric_name: result["mean_score"]})

    except Exception as ex:
        print("cannot enqueue", str(ex))


# calculate pairwise scores at BP using the learned invariants from all inputs
# not that input_invariants is a list of lists
def calculate_metric_distances(input_invariants: list) -> list:

    q = Queue()

    metric_functions = {
        "dice": _metric_dice,
        "hamming": _metric_hamming,
        "jaccard": _metric_jaccard,
        "overlap_coefficient": _metric_overlap_coefficient,
    }

    # use multiprocessing to calculate metrics
    distances = []
    processes = {}
    tqdm_position = 1

    print("calculate parallel metrics")
    for metric, metric_function in metric_functions.items():

        p = multiprocessing.Process(
            target=_metric_wrapper,
            args=(
                q,
                metric,
                metric_function,
                input_invariants,
                tqdm_position,
            ),
        )
        p.start()
        processes[metric] = p
        tqdm_position += 1
        # linear calculation - unused
        # diversity_score = metric_function(input_invariants=input_invariants)

    print("finishing calculations")
    for metric, process in processes.items():
        process.join()

    print("joining calculation")
    for _ in range(len(metric_functions)):
        result = q.get()

        metric_name = list(result)[0]
        mean_score = float(result[metric_name])

        print(f"{metric_name}: {mean_score}")

        distances.append(result)

    # sort distances by dict key
    distances = sorted(distances, key=lambda d: list(d.keys())[0])

    # merge dicts to one dict
    distance_dict = {}
    for distance in distances:
        metric = list(distance.keys())[0]
        value = list(distance.values())[0]
        distance_dict[metric] = value

    return distance_dict


# =========================================================================


# worker function for process_invariant_files_at_bp
def process_single_invariant_file(inv_file_path: str) -> tuple:

    invariants = read_invariant_file(file_path=inv_file_path)
    invariants_count = len(invariants)

    # collect a set of input's invariants in a list
    print(multiprocessing.current_process().name, inv_file_path, invariants_count)

    # assume the filename does not violate any rules
    fuzzing_input_name = inv_file_path.split("/")[-2]

    # a set of invariant from one input
    bp_invariant_objects = []

    # convert to sympy and simplify expressions
    # simply extract lhs / rhs of the splitter
    for expr in invariants:

        # print(expr)
        if CONVERT_INVARIANT_TO_DIG_OBJECT:
            # convert to DigInvariant object for robust comparison
            bp_invariant_objects.append(DigInvariant(invariant_str=expr))
        else:
            # just store raw invariant string, fast
            bp_invariant_objects.append(expr)

        # print(invariant_objects)

    return (fuzzing_input_name, bp_invariant_objects)


# read invariant files at a breakpoint using multiprocessing
# return {input_file_name: [invariants], ...}
def process_invariant_files_at_bp(bp_inv_file_paths: list) -> dict:

    # use multiprocessing to read file and convert to SymPy
    bp_invariants = []

    print("read invariant files")
    print("MAX_THREADS", MAX_THREADS)
    with multiprocessing.Pool(processes=MAX_THREADS) as pool:
        bp_invariant_objects = pool.map(
            process_single_invariant_file, bp_inv_file_paths
        )
        bp_invariants.extend(bp_invariant_objects)

    # assume that fuzzing input is unique at a bp, no collision
    return {x[0]: x[1] for x in bp_invariants}


# collect paths to all invariants files at each BP given a root path
def collect_bp_inv_file_paths(invariant_output_path: str) -> dict:
    bp_inv_file_paths = {}
    for path, _, inv_files in os.walk(invariant_output_path):

        for inv_file in inv_files:
            bp_number = inv_file.split(".")[0]

            if bp_number not in bp_inv_file_paths:
                bp_inv_file_paths[bp_number] = []

            inv_file_path = os.path.join(path, inv_file)
            bp_inv_file_paths[bp_number].append(inv_file_path)

    return bp_inv_file_paths


# =========================================================================
# read invariant object for both BIC and BFC at a given bp_number
def read_invariant_bp(
    invariant_bp_file: str,
    invariant_output_path: str,
    bp_number: str,
) -> dict:
    invariant_bp = {}
    # parse and process bic_invariant_bp & store as object file
    print("read bp invariants")

    # collect file_paths
    inv_file_paths = collect_bp_inv_file_paths(
        invariant_output_path=invariant_output_path
    )

    # NOTE randomly select up to MAX_INV_FILES to prevent OOM
    random.seed(27)

    inv_length = len(inv_file_paths[bp_number])
    target_inv_file_paths = random.sample(
        inv_file_paths[bp_number],
        min(MAX_INV_FILES, inv_length),
    )

    print("total files to be analyzed:", len(target_inv_file_paths))
    print(
        "reduced analysis to prevent OOM:",
        not (inv_length == len(target_inv_file_paths)),
    )

    # only process selected files
    invariant_bp = process_invariant_files_at_bp(
        bp_inv_file_paths=target_inv_file_paths
    )

    # TODO make this asynchronous write, no waiting time
    # store invariant bp object
    with open(invariant_bp_file, "wb") as invariant_fp:
        print("write file - update checkpoint", invariant_bp_file)
        pickle.dump(invariant_bp, invariant_fp)

    return invariant_bp


def load_pickle(path):
    with open(path, "rb") as f:
        return pickle.load(f)


# =========================================================================


# TODO add analysis functions i.e., visualizing distribution, k-mean clustering, hierarchical clustering, silhouette score
def plot_bp_distribution(
    distance_dict: dict, plot_result_file: str, is_buggy_bp: bool = False
):
    # fig, axes = plt.subplots(1, 1, figsize=(10, 8), sharey=True)
    fig, axes = plt.subplots(4, 1, figsize=(10, 8))
    axes = axes.flatten()

    for i, metric in enumerate(distance_dict.keys()):
        # putting list in dataframe
        df = pd.DataFrame(
            {
                "metric": [metric] * len(distance_dict[metric]),
                "value": distance_dict[metric],
            }
        )

        # TODO use is_buggy_bp to plot different color
        sns.kdeplot(
            data=df,
            x="value",
            # hue="buggy",
            ax=axes[i],
            # legend=True,
            # hue_order=hue_order,
            # palette=palette_dict,
            fill=True,
        )

        axes[i].set_title(f"invariant_{metric}")
        axes[i].set_xlabel("Distance")
        axes[i].set_ylabel("Density")

    plt.tight_layout()
    plt.savefig(plot_result_file)


# calculate pairwise distance betwen BFC / BIC invariants at each BP of the same input
if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--bfc_invariant_output_path",
        help="path of produced invariant (each subfolder contain set of invariants at each breakpoint)",
        default="",
    )

    parser.add_argument(
        "--bic_invariant_output_path",
        help="path of produced invariant (each subfolder contain set of invariants at each breakpoint)",
        default="",
    )

    parser.add_argument(
        "--stored_invariant_output_file",
        help="a file that store converted invariants",
        default="",
    )

    parser.add_argument(
        "--stored_invariant_score_text",
        help="a file that store invariant scores as readable text",
        default="",
    )

    parser.add_argument(
        "--max_threads",
        default="",
        help="maximum workers to read invariant files, blank to use file default",
    )

    args = parser.parse_args()

    # receive invariant_output_path - NOW WE HAVE 2 INVARIANT PATHS FOR COMPARISON - MUST LOOK AT THE SAME INPUT / BP PAIRS
    bfc_invariant_output_path = args.bfc_invariant_output_path
    bic_invariant_output_path = args.bic_invariant_output_path
    stored_invariant_output_file = args.stored_invariant_output_file
    stored_invariant_score_text = args.stored_invariant_score_text
    max_threads = args.max_threads

    if max_threads == "":
        max_threads = MAX_THREADS
    else:
        max_threads = int(max_threads)

    print("parsing and analyzing invariants across BFC and BIC")

    # available invariant at each BP
    invariant_recipe_file = f"{stored_invariant_output_file}_recipe"

    # work on a BP basis, consider existing data at BP not by stages

    # invariant_object_recipe is a guide to parse invariant files and load invariant objects
    invariant_object_recipe = {"bfc": [], "bic": []}
    # if recipe file exists, load it; otherwise, create recipe first
    if os.path.isfile(invariant_recipe_file):
        with open(invariant_recipe_file, "rb") as recipe_fp:
            invariant_object_recipe = pickle.load(recipe_fp)

    else:
        # make a recipe of BFC and BIC invariants
        print("make invariant bp recipe for BFC and BIC")
        # collect file paths - BFC and BIC
        bfc_inv_file_paths = collect_bp_inv_file_paths(
            invariant_output_path=bfc_invariant_output_path
        )
        bic_inv_file_paths = collect_bp_inv_file_paths(
            invariant_output_path=bic_invariant_output_path
        )

        bfc_bps = list(bfc_inv_file_paths.keys())
        bic_bps = list(bic_inv_file_paths.keys())

        # store available bp_number as a recipe of available bps in either version
        with open(invariant_recipe_file, "wb") as recipe_fp:
            invariant_object_recipe = {"bfc": bfc_bps, "bic": bic_bps}
            print("write invariant object recipe")
            pickle.dump(invariant_object_recipe, recipe_fp)

    # =========================================================================

    # follow invariant_recipe to parse invariant object at each bp
    print("bp invariants overview")

    # finalize common_bps available in dataset
    bfc_bps = invariant_object_recipe["bfc"]
    bic_bps = invariant_object_recipe["bic"]
    common_bps = list(set(bfc_bps).intersection(set(bic_bps)))

    print("common BPs between BFC and BIC", common_bps)

    # update hit_bps for later analysis
    hit_bps = common_bps

    for bp_number in common_bps:

        # =========================================================================

        # check if raw metric distances are calculated,
        # skip invariant loading and distance calculation to final step
        bp_raw_distance_file_pattern = (
            f"{stored_invariant_score_text}_raw_*_at_bp_{bp_number}"
        )
        raw_distance_files = glob.glob(bp_raw_distance_file_pattern)

        # check if raw_distance_files has all BPs according to recipe
        # if not, update recipe to allow process remaining BPs

        # assert that raw distance files can exist only after the distance is calculated at all BPs following recipe
        raw_distance_files_exist = True if len(raw_distance_files) > 0 else False

        # skip to distance analysis if raw distance files at this BP exists
        # otherwise, process invariant files
        if not raw_distance_files_exist:
            print("no raw scores, not skip to distance analysis")

            # check if invariant object is available, load or process BFC / BIC objects at ONE bp at a time to prevent OOM
            bfc_invariant_bp_file = get_invariant_file_name(
                type="bfc", bp_number=str(bp_number)
            )
            bic_invariant_bp_file = get_invariant_file_name(
                type="bic", bp_number=str(bp_number)
            )

            loadable_bfc_file = True if os.path.isfile(bfc_invariant_bp_file) else False
            loadable_bic_file = True if os.path.isfile(bic_invariant_bp_file) else False

            # make BFC / BIC read in parallel,
            # if reading also store file for next loading
            with ProcessPoolExecutor() as executor:
                if not loadable_bfc_file:
                    future1 = executor.submit(
                        read_invariant_bp,
                        bfc_invariant_bp_file,
                        bfc_invariant_output_path,
                        bp_number,
                    )

                if not loadable_bic_file:
                    future2 = executor.submit(
                        read_invariant_bp,
                        bic_invariant_bp_file,
                        bic_invariant_output_path,
                        bp_number,
                    )

            # load bp file to ensure data source
            bfc_invariant_bp = {}
            bic_invariant_bp = {}

            print("loading invariant object files at bp ", bp_number)

            # read two files in parallel, use process pool
            with ProcessPoolExecutor() as executor:
                future1 = executor.submit(load_pickle, bfc_invariant_bp_file)
                future2 = executor.submit(load_pickle, bic_invariant_bp_file)

                bfc_invariant_bp = future1.result()
                bic_invariant_bp = future2.result()

            bfc_invariants = len(bfc_invariant_bp)
            bic_invariants = len(bic_invariant_bp)

            print(
                "invariants at bp:",
                bp_number,
                "BFC invariants:",
                bfc_invariants,
                "BIC invariants:",
                bic_invariants,
            )

            # ========================================================

            # then, calculate the distance of union invariants (similarity = 0 when one side is missing)
            print("calculating distances")
            print("invariant distance at bp:", bp_number)

            bp_raw_score_path = (
                f"{stored_invariant_score_text}_raw_METRIC_NAME_at_bp_{bp_number}"
            )

            bfc_bp_input_files = bfc_invariant_bp.keys()
            bic_bp_input_files = bic_invariant_bp.keys()

            # what input generates invariants in both version, and either version
            common_inputs = set(bfc_bp_input_files).intersection(bic_bp_input_files)
            bfc_bp_input_files_diff = common_inputs.difference(set(bfc_bp_input_files))
            bic_bp_input_files_diff = common_inputs.difference(set(bfc_bp_input_files))

            # preserve order of above list
            common_inputs = list(common_inputs)
            bfc_bp_input_files_diff = list(bfc_bp_input_files_diff)
            bic_bp_input_files_diff = list(bic_bp_input_files_diff)

            # calculate distance for common inputs
            bp_metric_distances = {}
            for metric in metrics:
                bp_metric_distances[metric] = []

            common_inputs = sorted(common_inputs)
            input_file_order = (
                common_inputs + bfc_bp_input_files_diff + bic_bp_input_files_diff
            )

            # print(input_file_order)

            for fuzzing_input in common_inputs:
                # calculate distance of just a pair, mean score = distance
                metric_distances = calculate_metric_distances(
                    input_invariants=[
                        bfc_invariant_bp[fuzzing_input],
                        bic_invariant_bp[fuzzing_input],
                    ]
                )
                for metric, value in metric_distances.items():
                    bp_metric_distances[metric].append(value)

            # topup different inputs that generate invariants in single version (100% different)
            for i in range(len(bfc_bp_input_files_diff) + len(bic_bp_input_files_diff)):
                for metric, _ in bp_metric_distances.items():
                    bp_metric_distances[metric].append(1.0)

            # store raw distances
            # if raw distances exist, the script will not process invariant files again
            for metric, values in bp_metric_distances.items():
                bp_metric_raw_dictance_file = bp_raw_score_path.replace(
                    "METRIC_NAME", metric
                )

                with open(bp_metric_raw_dictance_file, "w") as invariant_raw_score_fp:
                    for raw_distance in values:
                        invariant_raw_score_fp.write(f"{raw_distance}\n")

            # store input file name for inspection
            with open(
                f"{stored_invariant_score_text}_fuzzing_input_at_bp_{bp_number}", "w"
            ) as invariant_raw_score_fp:
                for fuzzing_input in input_file_order:
                    invariant_raw_score_fp.write(f"{fuzzing_input}\n")

    # end if not skip_to_distance_analysis

    # ========================================================

    # read back the raw distance files
    print("reading raw distance files for further analysis")

    #  clean up verdict  file, not creating one if no need suggestion to review
    verdict_file = f"{stored_invariant_score_text}_suggestion"
    if os.path.isfile(verdict_file):
        os.remove(verdict_file)

    for bp_number in hit_bps:
        # should this BP be checked by reviewers
        bp_needs_review = False

        bp_raw_score_path = (
            f"{stored_invariant_score_text}_raw_METRIC_NAME_at_bp_{bp_number}"
        )

        bp_measure_path = (
            f"{stored_invariant_score_text}_measure_METRIC_NAME_at_bp_{bp_number}"
        )

        distance_dict = {}
        # collect density of peaks that signify some invariant difference
        high_peaks_density = []
        for metric in metrics:
            bp_metric_raw_dictance_file = bp_raw_score_path.replace(
                "METRIC_NAME", metric
            )

            # result measure file
            bp_metric_measure_file = bp_measure_path.replace("METRIC_NAME", metric)

            # NOTE distance -1 occurs in case of blank invariants i.e., incomparable
            distances = read_file_lines(file_path=bp_metric_raw_dictance_file)
            # exclude incomparable cases
            distances = [float(x) for x in distances if x != "-1.0"]

            print(bp_metric_raw_dictance_file, len(distances))

            distance_dict[metric] = distances

            # TODO TODO TODO TODO TODO TODO TODO
            # TODO - see how we should analyze raw distances e.g., clustering etc.
            try:
                kde_peaks = common.run_kde(data_list=distances)
                kde_furthest_peak = common.get_max_diff_in_list(data=kde_peaks["x"])
                sd = common.run_standard_variation(data_list=distances)
                iqr = common.run_interquartile_range(data_list=distances)

                # TODO Gaussian Mixture Model

                # TODO Reverse KL-divergence

                # store measures
                with open(bp_metric_measure_file, "w") as measure_fp:
                    measure_fp.write("==============================\n")
                    measure_fp.write("kde peaks\n")
                    measure_fp.write(f"{kde_peaks} \n")
                    measure_fp.write("=====================\n")
                    measure_fp.write("kde furthest peaks\n")
                    measure_fp.write(f"{str(kde_furthest_peak)} \n")
                    measure_fp.write("==============================\n")
                    measure_fp.write("sd\n")
                    measure_fp.write(f"{sd} \n")
                    measure_fp.write("==============================\n")
                    measure_fp.write("iqr\n")
                    measure_fp.write(f"{iqr} \n")
                    measure_fp.write("==============================\n")

                    # we keep looking if these values always higher in buggy cases?

                # check kde_peak and label BP
                x_no_difference_kde_threshold = 0.00022
                if len(kde_peaks["x"]) > 0:
                    # remove smallest peak that signifies no invariant differences
                    if kde_peaks["x"][0] < x_no_difference_kde_threshold:

                        kde_peaks["x"] = kde_peaks["x"][1:]
                        kde_peaks["y"] = kde_peaks["y"][1:]

                    # if there still more peaks, take the peaks' density into consideration
                    if len(kde_peaks["x"]) > 0:
                        high_peaks_density.append(kde_peaks["y"])

                else:
                    # no peaks situation
                    # check if all or most Xs are zero, if so, this BP may not need a review
                    # otherwise, if all or most Xs are 1, add to high_peaks_density
                    zero_check = [True if d == 0.0 else False for d in distances]
                    one_check = [True if d == 1.0 else False for d in distances]

                    if all(one_check) or sum(one_check) > sum(zero_check):
                        # need some attention, append a dummy density
                        high_peaks_density.append([1])
                    else:
                        # zero situation
                        pass
            except Exception:
                print(
                    f"distance analysis for metric {metric} failed at bp {bp_number}, most likely due to limited data points"
                )
                pass

        # review collected peaks density from all metrics, if more than half of the metrics agree, label as review-needed
        bp_needs_review = (
            True if len(high_peaks_density) >= 0.5 * len(metrics) else False
        )
        # append the verdict file
        if bp_needs_review:
            with open(verdict_file, "a") as vf:
                vf.write(f"detected invariant differences at bp {bp_number}\n")

        # visualizing histogram plot
        plot_result_file = (
            f"{stored_invariant_score_text}_distribution_at_bp_{bp_number}"
        )
        plot_bp_distribution(
            distance_dict=distance_dict, plot_result_file=plot_result_file
        )

        # TODO K-mean clustering

        # TODO silhouette score

        # TODO dendogram

    print("DONE")
