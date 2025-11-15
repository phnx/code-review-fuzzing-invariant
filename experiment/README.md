# Experiment Replication Package

We recommend running the experiments in interactive mode by using a `fuzzing-inv` container which points to specific experiment path using commands shown in the following sections.

The instructions for installing fuzzing tools of choice and DIG or customizing framework parameters can be seen in framework's [README](../framework/README.md) in section **Fuzzing Tool Integration** and **Customization**, respectively.

Default setup for RQ1 and RQ2 experiments are as follows:
- **RQ1:** 
  - fuzzing: 36 core-hours
  - execution trace: 1 minute timeout, maximum 10 variables per breakpoint
  - likely invariant analysis: maximum 1,500 traces
- **RQ2:** 
  - fuzzing: 36 core-hours
  - execution trace: 5 minute timeout
  - likely invariant analysis: maximum 1,500 traces

## Experiment Results
The results of our experiments for each RQ are stored in following paths:
- Motivating Example: `motivating_example/[subject_name]/fuzzing_test`
- RQ1: `rq1/experiment_data_result/[subject_name]/[fuzzing_tool_name]`
- RQ2: `rq2/experiment_data_result/[subject_name]/[fuzzing_tool_name]`
- RQ3: `rq1/experiment_data_sast/[subject_name]/sast/[sast_name]`


## Replicating Experiments

### Motivating example set replication
Note that the motivating example set contains non-crashing fuzzing inputs, debug script and result, execution traces, and likely invariants. Replication script only re-analyzes the likely invariant sets between two versions (buggy-clean and clean-clean) of seven example programs without fuzzing them.

*Likely Invariant Analysis*

```shell
docker run --rm -it --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
    -v ${PWD}/motivating_example:/experiment_data \
    -v ${PWD}/../framework/script:/script:ro \
    -v ${PWD}/../program:/program \
    -w /workdir \
    fuzzing-inv \
    bash
```


Start batch analysis on a subject in container:
```shell
source /experiment_data/motivating-example-entrypoint.sh
```



### RQ1 replication - Magma Invariant Analysis
*Fuzzing -> Execution Trace -> Likely Invariant Analysis*
```shell
docker run --rm -it --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
    -v ${PWD}/rq1/experiment_data:/experiment_data \
    -v ${PWD}/rq1/magma:/magma:ro \
    -v ${PWD}/../framework/script:/script:ro \
    -v ${PWD}/../program:/program \
    -w /workdir \
    fuzzing-inv \
    bash
```


Start an experiment on a subject in container:
```shell
export TARGET=lua # see target names in rq1/experiment_data
export FUZZING_TOOL=aflplusplus # one of: aflplusplus, honggfuzz, libfuzzer
source /experiment_data/rq1-entrypoint.sh
```

### RQ2 replication - BugOSS Invariant Analysis
*Change-Aware Seed Reuse (CSR) -> Fuzzing -> Execution Trace -> Likely Invariant Analysis*

```shell
docker run --rm -it --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
    -v ${PWD}/rq2/experiment_data:/experiment_data \
    -v ${PWD}/../framework/script:/script:ro \
    -v ${PWD}/../program:/program \
    -w /workdir \
    fuzzing-inv \
    bash
```

Start an experiment on a subject in container:
```shell
export TARGET=file-30222 # see target names in rq1/experiment_data
export FUZZING_TOOL=aflplusplus # one of: aflplusplus, honggfuzz, libfuzzer
source /experiment_data/rq2-entrypoint.sh
```

### RQ3 replication - SAST detection BugOSS
*SAST Execution -> HIT Rate Analysis*
```shell
docker run --rm -it --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
    -v ${PWD}/rq3/experiment_data_sast:/experiment_data_sast \
    -v ${PWD}/rq3/script:/script:ro \
    -v ${PWD}/../program:/program \
    -w /workdir \
    fuzzing-inv \
    bash
```
Start batch experiment in container
```shell
# install SASTs,
source /script/sast/install-sast.sh
# start batch experiments
source /experiment_data_sast/rq3-entrypoint.sh
```

## References
- Magma - [https://hexhive.epfl.ch/magma/](https://hexhive.epfl.ch/magma/)
- BugOSS - [https://github.com/sdevlab/BugOss/](https://github.com/sdevlab/BugOss/)