# follow this script to build abd test single motivating example
# NOTE change subject path

export TARGET_PROGRAM=$1

# work from subject path
cd /experiment_data/$TARGET_PROGRAM


#  ==================================================

# cross-version distance
# modified pairs
mkdir -p /experiment_data/$TARGET_PROGRAM/fuzzing_test/distance_cross_version_modified
python3 /script/analyzer/analyze_invariants_thread_cross_version.py \
    --bfc_invariant_output_path /experiment_data/$TARGET_PROGRAM/fuzzing_test/original_1_invariant  \
    --bic_invariant_output_path /experiment_data/$TARGET_PROGRAM/fuzzing_test/modified_invariant  \
    --stored_invariant_output_file /experiment_data/$TARGET_PROGRAM/fuzzing_test/distance_cross_version_modified/invariant_object \
    --stored_invariant_score_text /experiment_data/$TARGET_PROGRAM/fuzzing_test/distance_cross_version_modified/invariant_distance

# UNUSED compare traces
# python3 /script/analyzer/analyze_traces_thread_cross_version.py \
#     --bfc_trace_output_path /experiment_data/$TARGET_PROGRAM/fuzzing_test/original_1_trace  \
#     --bic_trace_output_path /experiment_data/$TARGET_PROGRAM/fuzzing_test/modified_trace  \
#     --stored_trace_output_file /experiment_data/$TARGET_PROGRAM/fuzzing_test/distance_cross_version_modified/trace_object \
#     --stored_trace_score_text /experiment_data/$TARGET_PROGRAM/fuzzing_test/distance_cross_version_modified/trace_distance


# original pairs
mkdir -p /experiment_data/$TARGET_PROGRAM/fuzzing_test/distance_cross_version_original
python3 /script/analyzer/analyze_invariants_thread_cross_version.py \
    --bfc_invariant_output_path /experiment_data/$TARGET_PROGRAM/fuzzing_test/original_1_invariant  \
    --bic_invariant_output_path /experiment_data/$TARGET_PROGRAM/fuzzing_test/original_2_invariant  \
    --stored_invariant_output_file /experiment_data/$TARGET_PROGRAM/fuzzing_test/distance_cross_version_original/invariant_object \
    --stored_invariant_score_text /experiment_data/$TARGET_PROGRAM/fuzzing_test/distance_cross_version_original/invariant_distance

# UNUSED compare traces
# python3 /script/analyzer/analyze_traces_thread_cross_version.py \
#     --bfc_trace_output_path /experiment_data/$TARGET_PROGRAM/fuzzing_test/original_1_trace  \
#     --bic_trace_output_path /experiment_data/$TARGET_PROGRAM/fuzzing_test/original_2_trace  \
#     --stored_trace_output_file /experiment_data/$TARGET_PROGRAM/fuzzing_test/distance_cross_version_original/trace_object \
#     --stored_trace_score_text /experiment_data/$TARGET_PROGRAM/fuzzing_test/distance_cross_version_original/trace_distance



# TODO collect resulting distance from fuzzing_test/distance_cross_version_*

# return to sample_set root
cd /experiment_data