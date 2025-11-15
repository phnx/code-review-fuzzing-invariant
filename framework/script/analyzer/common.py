import statistics

import numpy as np
from sklearn.model_selection import GridSearchCV
from sklearn.neighbors import KernelDensity
from scipy.signal import find_peaks


def test_func():
    print("ok")


def get_max_diff_in_list(data: list) -> float:
    if len(data) == 0:
        return -1

    return abs(max(data) - min(data))


# collection of one-dimension tests - how different are the values?
# look from various angles e.g., value / distribution / etc.
def run_kde(data_list: list) -> dict:
    data_list = np.array(data_list).reshape(-1, 1)

    # estimate bandwidth - cross validation
    bandwidths = np.linspace(0.1, 1.0, 100)
    grid = GridSearchCV(
        KernelDensity(kernel="gaussian"),
        param_grid={"bandwidth": bandwidths},
        cv=5,
        error_score="raise",
    )
    grid.fit(data_list)

    # best model
    # print(f"Best bandwidth: {grid.best_params_['bandwidth']}")
    best_estimator = grid.best_estimator_

    # fit the model as usual
    kde = best_estimator.fit(data_list)

    # small margin to support polar distance 0 and 1
    x_vals = np.linspace(-0.01, 1.01, 1000)[:, None]
    log_dens = kde.score_samples(x_vals)
    dens = np.exp(log_dens)

    # debug
    # import matplotlib.pyplot as plt
    # plt.plot(x_vals, dens)
    # plt.title("KDE Curve")
    # plt.show()

    peaks, _ = find_peaks(dens)
    peak_x_vals = x_vals[peaks][:, 0]

    # # sanity check for x=0, does it converge to a small value i.e., 0.00021
    # print(peak_x_vals[peak_x_vals < 0.00022])
    # # more artificial test
    # test_points = np.array([[0.0], [0.0001], [0.00021], [0.0005]])
    # dens_test = np.exp(kde.score_samples(test_points))
    # for x, d in zip(test_points[:, 0], dens_test):
    #     print(f"x = {x:.5f}, KDE = {d:.6f}")

    peak_x = x_vals[peaks].flatten()
    peak_y = dens[peaks]
    peaks = {"x": [], "y": []}

    for x, y in zip(peak_x, peak_y):
        peaks["x"].append(x)
        peaks["y"].append(y)

    return peaks


def run_standard_variation(data_list: list) -> dict:
    mean = statistics.mean(data_list)
    sd = statistics.stdev(data_list)

    return {"mean": mean, "sd": sd}


def run_interquartile_range(data_list: list) -> dict:
    q1 = np.percentile(data_list, 25)
    q3 = np.percentile(data_list, 75)
    iqr = q3 - q1

    return {"iqr": iqr, "q1": q1, "q3": q3}
