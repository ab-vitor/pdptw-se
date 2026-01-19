import math
import os
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from matplotlib import pyplot as plt
import pandas as pd
import numpy as np
import subprocess
import argparse

"""
    def extract_inst_jobs(inst_lines)
    
    Extracts job data from instance lines and returns a DataFrame.
"""
def extract_inst_jobs(inst_lines):
    col_names = ["job_no", "x", "y", "dem", "earl", "lat", "servt", "pid", "did"]
    inst_jobs = pd.DataFrame(inst_lines[1:], columns=col_names, index=None)
    for col in inst_jobs.columns:
        inst_jobs[col] = inst_jobs[col].astype(int)
    return inst_jobs


def reduce_inst_jobs(inst_jobs):
    global n_jobs

    to_drop_1 = inst_jobs[inst_jobs["servt"] == 0].index[1:].tolist()
    to_drop_2 = set()
    for idx in to_drop_1:
        row = inst_jobs.loc[idx]
        pid, did = row["pid"], row["did"]
        if pid == 0:
            to_drop_2.add(inst_jobs[inst_jobs["job_no"] == did].index.item())
        elif did == 0:
            to_drop_2.add(inst_jobs[inst_jobs["job_no"] == pid].index.item())

    inst_jobs.drop(to_drop_1 + list(to_drop_2), inplace=True)

    while len(inst_jobs) - 1 > n_jobs:
        chosen_idx = inst_jobs.index[-1]
        pid, did = inst_jobs.loc[chosen_idx]["pid"], inst_jobs.loc[chosen_idx]["did"]
        jumps = 1
        while did == 0:
            chosen_idx = inst_jobs.index[::-1][jumps]
            pid, did = (
                inst_jobs.loc[chosen_idx]["pid"],
                inst_jobs.loc[chosen_idx]["did"],
            )
            jumps += 1

        inst_jobs.drop(chosen_idx, inplace=True)
        if pid == 0:
            inst_jobs = inst_jobs[inst_jobs["job_no"] != did]

    return inst_jobs


def extract_points(inst_jobs):
    points = [
        [int(inst_jobs.loc[i]["x"]), int(inst_jobs.loc[i]["y"])]
        for i in inst_jobs.index
    ]
    return points


def gen_z_values():
    global n_floors, n_jobs
    z_values = [0] + [np.random.randint(0, n_floors) for _ in range(n_jobs)]
    return z_values


def gen_jobs(inst_jobs):
    inst_jobs.insert(3, "z", gen_z_values())
    return inst_jobs


def choose_capacity(base, variation, t):
    return base + np.random.randint(-math.floor(t / 2), math.ceil(t / 2)) * variation


def gen_vehicles(n_vehicles, max_demand_req):
    vehicles = []
    global var_cap, v_types
    base_cap = int(round(max_demand_req / 0.6))  # sartori (2020)
    var = int(round(base_cap * var_cap / 100))

    # Ensure that at least one vehicle of each type exists in the instance
    variations = [
        i * var for i in range(-math.floor(v_types / 2), math.ceil(v_types / 2))
    ]
    for i in range(v_types):
        vehicles.append([i, base_cap + variations[i]])

    for i in range(v_types, n_vehicles):
        vehicles.append([i, choose_capacity(base_cap, var, v_types)])

    vehicles = pd.DataFrame(vehicles, columns=["v_no", "cap"], index=None)
    return vehicles


def choose_point(central_point, min_x, max_x, points):
    point = np.array(
        [
            min(max_x, max(min_x, central_point[0] + np.random.randint(-100, 100) * 2)),
            central_point[1],
        ]
    )
    for i in range(0, 50):
        point = np.array(
            [min(max_x, max(min_x, central_point[0] + i * 2)), central_point[1]]
        )
        if not (points == point).all(axis=1).any():
            break
        point = np.array(
            [min(max_x, max(min_x, central_point[0] - i * 2)), central_point[1]]
        )
        if not (points == point).all(axis=1).any():
            break

    return point


def gen_machines(points):
    global mach_spd
    spd = mach_spd  # fixed by now

    # the first machine always attends all islands
    points = np.array([np.array(pt) for pt in points])
    min_x = min(points[:, 0])
    max_x = max(points[:, 0])
    central_point = np.array(
        [
            round((max_x - min_x) / 2),
            round((max(points[:, 1]) - min(points[:, 1])) / 2),
        ]
    )
    pt = choose_point(central_point, min_x, max_x, points)
    machines = []
    for i in range(0, n_floors):
        machines.append([0, pt[0], pt[1], i, spd])

    for i in range(1, n_machines):
        pt = choose_point(central_point, min_x, max_x, points)
        lz = np.random.randint(0, n_floors - 1)
        hz = np.random.randint(lz + 1, n_floors)
        for j in range(lz, hz + 1):
            machines.append([i, pt[0], pt[1], j, spd])
            points = np.vstack([points, pt])

    machines = pd.DataFrame(machines, columns=["id", "x", "y", "z", "spd"])
    machines.to_csv("machines.csv", header=False, index=False)
    return machines


def gen_machines_with_all_stations(points):
    global mach_spd, n_machines, n_floors
    spd = mach_spd  # fixed by now

    points = np.array([np.array(pt) for pt in points])
    min_x = min(points[:, 0])
    max_x = max(points[:, 0])
    min_y = min(points[:, 1])
    max_y = max(points[:, 1])
    central_point = np.array(
        [
            round((max_x + min_x) / 2),
            round((max_y + min_y) / 2),
        ]
    )

    # the first machine always attends all islands
    machines = []
    for i in range(0, n_machines):
        pt = choose_point(central_point, min_x, max_x, points)
        for j in range(n_floors):
            machines.append([i, pt[0], pt[1], j, spd])
            points = np.vstack([points, pt])

    machines = pd.DataFrame(machines, columns=["id", "x", "y", "z", "spd"])
    machines.to_csv("machines.csv", header=False, index=False)
    return machines


def savePltFigInstanceMap(jobs, machines, filename):
    fig = plt.figure()
    ax = fig.add_subplot(111, projection="3d")
    plt.plot(
        jobs.x[0],
        jobs.y[0],
        marker="s",
        linestyle="",
        markersize=10,
        label="Depot",
    )
    groups_jobs = jobs.iloc[1:].groupby("z")
    cmap = plt.colormaps["tab10"]
    colors = []
    global n_floors
    for i in range(n_floors):
        color = cmap((i + 1) % 10)
        colors.append(color)

    for name, group in groups_jobs:
        color = cmap((int(name) + 1) % 10)
        ax.scatter(
            group.x,
            group.y,
            group.z,
            marker="o",
            label=f"Floor {name}",
            color=color,
            depthshade=0,
        )

    groups_machines_by_id = machines.groupby("id")
    for name, group in groups_machines_by_id:
        color = cmap((int(name) + n_floors + 1) % 10)
        ax.scatter(
            group.x,
            group.y,
            group.z,
            marker="^",
            label=f"Machine {name} Station",
            color=color,
            depthshade=0,
        )

    ax.set_xlabel("X")
    ax.set_ylabel("Y")
    ax.set_zlabel("Z")

    ax.set_zticks(range(int(jobs["z"].min()), int(jobs["z"].max()) + 2))
    ax.set_box_aspect([1.5, 1.5, 1 + 0.2 * (1.71**n_floors)])

    xlim = ax.get_xlim()
    ylim = ax.get_ylim()

    verts = []
    for z in range(n_floors):
        points = np.array(
            [
                [xlim[0], ylim[0], z],
                [xlim[0], ylim[1], z],
                [xlim[1], ylim[0], z],
                [xlim[1], ylim[1], z],
                [xlim[0], ylim[0], z + 1],
                [xlim[0], ylim[1], z + 1],
                [xlim[1], ylim[0], z + 1],
                [xlim[1], ylim[1], z + 1],
            ]
        )
        edges = [
            (0, 1, 3, 2),  # bottom
            # (4, 5, 7, 6), # top
            # (0, 1, 5, 4), # side
            # (2, 3, 7, 6), # opposite side
            # (0, 2, 6, 4), # another side
            # (1, 3, 7, 5),  # opposite side
        ]
        for edge in edges:
            verts.append([points[i] for i in edge])

        ax.add_collection3d(
            Poly3DCollection(
                verts, facecolors=colors[z], linewidths=1, edgecolors="k", alpha=0.2
            )
        )
        verts = []

    plt.gcf().set_size_inches(plt.rcParams["figure.figsize"])
    # plt.gca().set_aspect(0.8)
    plt.subplots_adjust(left=0.0, right=0.7, top=1.0, bottom=0.1)
    plt.legend(loc="center left", bbox_to_anchor=(1.1, 0.5))
    legend = plt.gca().get_legend()
    legend_width = legend.get_window_extent().width / plt.gcf().dpi

    fig_size = plt.gcf().get_size_inches()
    fig_size[0] += legend_width

    plt.gcf().set_size_inches(fig_size)
    ax.view_init(elev=15, azim=-130)
    global n_requests, n_vehicles, n_machines
    figure_name = f"map_{n_requests:02}R_{n_vehicles:02}V_{n_floors:02}F_{n_machines:02}M_{filename}.pdf"
    plt.savefig(figure_name)
    plt.clf()


def read_inst_lines(filename, group):
    ifile = open(group + "/" + filename + ".txt", "r")
    print(group + "/" + filename + ".txt")
    inst_lines = ifile.read().splitlines()
    ifile.close()
    for i in range(len(inst_lines)):
        inst_lines[i] = inst_lines[i].split("\t")

    return inst_lines


def gen_inst_files(filename, group, new_group):
    inst_lines = read_inst_lines(filename, group)

    all_inst_jobs = extract_inst_jobs(inst_lines)
    inst_jobs = reduce_inst_jobs(all_inst_jobs)
    points = extract_points(inst_jobs)
    
    type_code = f"t{filename[2]}"

    os.chdir(new_group)
    if type_code == "t1" or type_code == "t2":
        if not os.path.isdir(type_code):
            os.mkdir(type_code)
        os.chdir(type_code)
    else:
        raise ValueError("Filename does not match expected pattern.")

    if not os.path.isdir(filename):
        os.mkdir(filename)
    os.chdir(filename)

    max_demand_req = inst_jobs["dem"].max()

    global n_vehicles
    vehicles = gen_vehicles(n_vehicles, max_demand_req)
    jobs = gen_jobs(inst_jobs)
    if ams:
        machines = gen_machines_with_all_stations(points)
    else:
        machines = gen_machines(points)

    jobs.to_csv("jobs.csv", header=False, index=False)
    vehicles.to_csv("vehicles.csv", header=False, index=False)
    machines.to_csv("machines.csv", header=False, index=False)

    # savePltFigInstanceMap(jobs, machines, filename) # uncomment to save instance map illustration

    if mf != "none":
        inst_location = os.getcwd()

        os.chdir("../../../../../../src/julia/")

        global min_n_machines
        cmd_str = f"julia pdptwse.jl --method_type heur --method_code {mf} --inst_path ../../instances/{new_group}/{type_code}/{filename}/ --make_instance_feasible --elevator --cut_off_machs {min_n_machines}"
        subprocess.run(cmd_str, shell=True)

        os.chdir(inst_location)

    os.chdir("../../../../../")


def main():
    # Define the parser
    parser = argparse.ArgumentParser(description="Your script description")

    # Define the arguments
    parser.add_argument(
        "--group", type=str, default="pdptw_100_li_lim", help="Group of instances"
    )
    parser.add_argument("--req", type=int, default=0, help="Number of requests")
    parser.add_argument("--vehi", type=int, default=0, help="Number of vehicles")
    parser.add_argument(
        "--v_types", type=int, default=3, help="Number of vehicle types"
    )
    parser.add_argument("--floors", type=int, default=0, help="Number of floors")
    parser.add_argument("--mach", type=int, default=0, help="Number of machines")
    parser.add_argument(
        "--min_mach", type=int, default=0, help="Minimum Number of machines"
    )
    parser.add_argument("--mach_spd", type=float, default=0.2, help="Machine speed")
    parser.add_argument(
        "--ams", action="store_true", help="Instances with all machine stations"
    )
    parser.add_argument(
        "--mf",
        choices=["gmutate", "none"],
        default="none",
        help="Instances with all machine stations",
    )
    parser.add_argument(
        "--var_cap",
        type=int,
        default=5,
        help="Vehicle Capacity variation from base capacity (%%). If base is 90%% and the variation is 5%%, the vehicles capacities will be 90%%, 95%%, and 100%%, if v_types is 3",
    )
    parser.add_argument(
        "--pre_folder",
        type=str,
        default="orig_ams",
        help="Folder before the new group folder",
    )

    # Parse the arguments
    args = parser.parse_args()

    # Set module-level globals used by helper functions
    global group, n_requests, n_jobs, n_vehicles, n_floors, n_machines
    global min_n_machines, v_types, var_cap, mach_spd, version, new_group, seed
    global mf, ams

    group = args.group
    n_requests = args.req
    n_jobs = n_requests * 2
    n_vehicles = args.vehi
    n_floors = args.floors
    n_machines = args.mach
    min_n_machines = args.min_mach
    v_types = args.v_types
    var_cap = args.var_cap
    mach_spd = args.mach_spd
    mf = args.mf
    ams = args.ams
    pre_folder = args.pre_folder

    version = "multi_floor"
    if not os.path.isdir(version):
        os.mkdir(version)

    if not os.path.isdir(f"{version}/{pre_folder}"):
        os.mkdir(f"{version}/{pre_folder}")

    new_group = f"{version}/{pre_folder}/{n_requests:02d}R_{n_vehicles:02d}V_{n_floors:02d}F_{n_machines:02d}M"

    if not os.path.isdir(new_group):
        os.mkdir(new_group)

    seed = 1

    filenames = os.listdir(group)
    filenames.sort()
    for filename in filenames:
        # skip files that don't match the instance patterns
        if (
            filename[0:2].lower() == "lc"
            or filename[0:3].lower() == "lrc"
            or filename[:-4:-1] != "txt"
        ):
            continue

        np.random.seed(seed)
        seed += 1

        filename = filename[:-4]
        gen_inst_files(filename, group, new_group)


if __name__ == "__main__":
    main()
