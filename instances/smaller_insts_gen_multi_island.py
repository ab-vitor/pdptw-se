import argparse
import copy
import math
import os
import random
import subprocess

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy
from scipy.spatial import ConvexHull
from sklearn.cluster import KMeans


def extract_inst_jobs(inst_lines):
    col_names = ["job_no", "x", "y", "dem", "earl", "lat", "servt", "pid", "did"]
    inst_jobs = pd.DataFrame(inst_lines[1:], columns=col_names, index=None)
    for col in inst_jobs.columns:
        inst_jobs[col] = inst_jobs[col].astype(int)
    return inst_jobs


def reduce_inst_jobs(inst_jobs):
    global n_jobs

    to_drop_1 = inst_jobs[inst_jobs["servt"] == 0].index[1:].tolist() # dummy nodes
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


def extract_points(df, with_z=False):
    if with_z:
        points = [
            [
                int(df.loc[i]["x"]),
                int(df.loc[i]["y"]),
                int(df.loc[i]["z"]),
            ]
            for i in df.index
        ]
    else:
        points = [[int(df.loc[i]["x"]), int(df.loc[i]["y"])] for i in df.index]
    return points


def kmeans_for_instance(points):
    global n_islands
    kmeans = KMeans(n_clusters=n_islands, n_init="auto").fit(points)
    if kmeans.labels_[0] != 0:
        point_0_label = kmeans.labels_[0]
        kmeans.labels_[kmeans.labels_ == point_0_label] = -1
        kmeans.labels_[kmeans.labels_ == 0] = point_0_label
        kmeans.labels_[kmeans.labels_ == -1] = 0

        aux = kmeans.cluster_centers_[0].copy()
        kmeans.cluster_centers_[0] = kmeans.cluster_centers_[point_0_label]
        kmeans.cluster_centers_[point_0_label] = aux

    return kmeans


def gen_z_values(kmeans):
    return kmeans.labels_


def gen_jobs(inst_jobs, kmeans):
    inst_jobs.insert(3, "z", gen_z_values(kmeans))
    return inst_jobs


def choose_capacity(base, variation, t):
    return base + np.random.randint(-math.floor(t / 2), math.ceil(t / 2)) * variation


def gen_vehicles(n_vehicles, max_demand_req):
    vehicles = []
    global var_cap, v_types
    base_cap = int(round(max_demand_req / 0.6))  # sartori (2020)
    var = int(round(base_cap * var_cap / 100))

    # Ensure that at least one vehicle of each type exists in the instance
    variations = [i*var for i in range(-math.floor(v_types / 2), math.ceil(v_types / 2))]
    for i in range(v_types):
        vehicles.append([i, base_cap + variations[i]])

    for i in range(v_types, n_vehicles):
        vehicles.append([i, choose_capacity(base_cap, var, v_types)])

    vehicles = pd.DataFrame(vehicles, columns=["v_no", "cap"], index=None)
    # print(vehicles)
    return vehicles


def gen_machine_point(z, z_points, centroid, distinct_points, kmeans):

    x = min(max(math.floor(centroid[0] + np.random.randint(-5, 5) * 3), 0), 100)
    y = min(max(math.floor(centroid[1] + np.random.randint(-5, 5) * 3), 0), 100)
    distinct_point = [x, y]
    while (
        distinct_point in z_points
        or distinct_point in distinct_points
        or kmeans.predict([distinct_point])[0] != z
    ):
        x = min(max(math.floor(centroid[0] + np.random.randint(-5, 5) * 3), 0), 100)
        y = min(max(math.floor(centroid[1] + np.random.randint(-5, 5) * 3), 0), 100)
        distinct_point = [x, y]

    return distinct_point


def get_sum_dists_to_clique_vertices(convex_hulls, islands, stations, new_point):
    i = 0
    sum_dists_to_clique_vertices = 0
    while i < len(stations):
        z = islands[i]
        hull = convex_hulls[z]
        pt = hull.points[stations[i]]
        sum_dists_to_clique_vertices += math.dist(pt, new_point)
        i += 1
    return sum_dists_to_clique_vertices


def backtracking_best_clique(
    convex_hulls,
    islands,
    i,
    sum_dists_clique,
    curr_stations=None,
    best_stations=None,
    best_stations_value=math.inf,
):
    if curr_stations is None:
        curr_stations = []

    if best_stations is None:
        best_stations = []

    if i == len(islands):
        if sum_dists_clique < best_stations_value:
            return curr_stations, sum_dists_clique
        else:
            return best_stations, best_stations_value

    z = islands[i]
    hull = convex_hulls[z]

    for v in hull.vertices:
        sum_dists_to_clique_vertices = get_sum_dists_to_clique_vertices(
            convex_hulls, islands, curr_stations, hull.points[v]
        )

        if sum_dists_clique + sum_dists_to_clique_vertices < best_stations_value:
            curr_stations.append(v)
            sum_dists_clique += sum_dists_to_clique_vertices

            best_stations, best_stations_value = backtracking_best_clique(
                convex_hulls,
                islands,
                i + 1,
                sum_dists_clique,
                copy.deepcopy(curr_stations),
                best_stations,
                best_stations_value,
            )

            sum_dists_clique -= sum_dists_to_clique_vertices
            curr_stations.pop()

    return best_stations, best_stations_value


def get_random_simplex_point_close_to_vertex(
    hull, v, stations, curr_station, convex_hulls, islands, all_points
):
    adjacent_indices = np.where(np.any(hull.simplices == v, axis=1))[0]
    best_nearest_point = [0, 0]
    best_nearest_point_sum_dists = math.inf
    for adj_vertex in np.unique(hull.simplices[adjacent_indices]):
        if adj_vertex != v:
            t = 1.0
            rand_simplex_point = t * hull.points[v] + (1 - t) * hull.points[adj_vertex]
            rand_simplex_point[0] = round(rand_simplex_point[0])
            rand_simplex_point[1] = round(rand_simplex_point[1])
            while (all_points == rand_simplex_point).all(axis=1).any() or math.dist(
                rand_simplex_point, hull.points[v]
            ) <= 2:
                rand_simplex_point = (
                    t * hull.points[v] + (1 - t) * hull.points[adj_vertex]
                )
                rand_simplex_point[0] = round(rand_simplex_point[0])
                rand_simplex_point[1] = round(rand_simplex_point[1])
                t -= 0.05

            sum_dists_to_simplex_vertex = 0
            for i in range(len(stations)):
                if curr_station != i:
                    hull_2 = convex_hulls[islands[i]]
                    sum_dists_to_simplex_vertex += math.dist(
                        rand_simplex_point, hull_2.points[stations[i]]
                    )

            if sum_dists_to_simplex_vertex < best_nearest_point_sum_dists:
                best_nearest_point_sum_dists = sum_dists_to_simplex_vertex
                best_nearest_point = rand_simplex_point

    return best_nearest_point


def gen_machine_points(convex_hulls, islands, all_points, vertices):
    best_stations = np.array([])
    for i in range(len(islands)):
        z = islands[i]
        hull = convex_hulls[z]

        best_nearest_point = get_random_simplex_point_close_to_vertex(
            hull,
            vertices[i],
            vertices,
            i,
            convex_hulls=convex_hulls,
            islands=islands,
            all_points=all_points,
        )
        if len(best_stations) == 0:
            best_stations = np.array([best_nearest_point])
        else:
            best_stations = np.vstack([best_stations, best_nearest_point])

    return best_stations


def add_dummy_point_to_use_convex_hull_algorithm(z_points, centroid):
    x = min(max(math.floor(centroid[0] + np.random.randint(-5, 5) * 3), 0), 100)
    y = min(max(math.floor(centroid[1] + np.random.randint(-5, 5) * 3), 0), 100)
    distinct_point = [x, y]
    while distinct_point in z_points:
        x = min(max(math.floor(centroid[0] + np.random.randint(-5, 5) * 3), 0), 100)
        y = min(max(math.floor(centroid[1] + np.random.randint(-5, 5) * 3), 0), 100)
        distinct_point = [x, y]
    z_points = np.append(z_points, [distinct_point], axis=0)
    return z_points


def get_convex_hulls_for_each_island(islands, kmeans, points):
    labels = kmeans.labels_
    centroids = kmeans.cluster_centers_
    convex_hulls = []
    for z in islands:
        z_points = np.array([points[i] for i in range(len(labels)) if labels[i] == z])
        centroid = centroids[z]
        while len(z_points) < 3:
            z_points = add_dummy_point_to_use_convex_hull_algorithm(
                z_points,
                centroid,
            )

        while True:
            try:
                hull = ConvexHull(z_points)
            except scipy.spatial._qhull.QhullError:
                z_points = add_dummy_point_to_use_convex_hull_algorithm(
                    z_points,
                    centroid,
                )
                continue
            else:
                break

        convex_hulls.append(hull)

    return convex_hulls


def gen_machines(kmeans, points):
    global mach_spd
    spd = mach_spd
    all_islands = [i for i in range(n_islands)]
    convex_hulls = get_convex_hulls_for_each_island(all_islands, kmeans, points)
    # the first machine always attends all islands
    dict_clique_vertices = {}
    best_vertices, _ = backtracking_best_clique(
        convex_hulls=convex_hulls,
        islands=all_islands,
        i=0,
        sum_dists_clique=0,
    )
    all_islands_key = "".join(str(e) for e in all_islands)
    dict_clique_vertices[all_islands_key] = best_vertices

    pts = gen_machine_points(
        convex_hulls, all_islands, points, dict_clique_vertices[all_islands_key]
    )
    machines = []
    for z in range(n_islands):
        machines.append([0, int(pts[z][0]), int(pts[z][1]), z, spd])
        points.append(pts[z])

    global n_machines
    for i in range(1, n_machines):
        islands = random.sample(all_islands, np.random.randint(2, n_islands + 1))
        islands.sort()
        islands_key = "".join(str(e) for e in islands)
        if islands_key not in dict_clique_vertices.keys():
            best_vertices, best_stations_value = backtracking_best_clique(
                convex_hulls=convex_hulls,
                islands=islands,
                i=0,
                sum_dists_clique=0,
            )
        else:
            best_vertices = dict_clique_vertices[islands_key]

        pts = gen_machine_points(
            convex_hulls=convex_hulls,
            islands=islands,
            all_points=points,
            vertices=dict_clique_vertices[islands_key],
        )
        for j in range(len(islands)):
            machines.append([i, int(pts[j][0]), int(pts[j][1]), islands[j], spd])
            points.append(pts[j])

    machines = pd.DataFrame(machines, columns=["id", "x", "y", "z", "spd"], index=None)
    return machines, convex_hulls


def gen_machines_with_all_stations(kmeans, points):
    global mach_spd, n_islands
    spd = mach_spd
    all_islands = [i for i in range(n_islands)]
    convex_hulls = get_convex_hulls_for_each_island(all_islands, kmeans, points)
    best_vertices, _ = backtracking_best_clique(
        convex_hulls=convex_hulls,
        islands=all_islands,
        i=0,
        sum_dists_clique=0,
    )

    pts = gen_machine_points(convex_hulls, all_islands, points, best_vertices)
    machines = []

    global n_machines
    for i in range(0, n_machines):
        pts = gen_machine_points(
            convex_hulls=convex_hulls,
            islands=all_islands,
            all_points=points,
            vertices=best_vertices,
        )
        for j in range(len(all_islands)):
            machines.append([i, int(pts[j][0]), int(pts[j][1]), all_islands[j], spd])
            points.append(pts[j])

    machines = pd.DataFrame(machines, columns=["id", "x", "y", "z", "spd"], index=None)
    return machines, convex_hulls


def savePltFigInstanceMap(jobs, machines, convex_hulls):
    plt.plot(
        jobs.x[0], jobs.y[0], marker="s", linestyle="", markersize=10, label="Depot"
    )
    groups_jobs = jobs.iloc[1:].groupby("z")
    cmap = plt.colormaps["tab10"]
    for name, group in groups_jobs:
        color = cmap((int(name) + 1) % 10)
        plt.plot(
            group.x,
            group.y,
            marker="o",
            linestyle="",
            markersize=7,
            label=f"Island {name}",
            color=color,
        )

        hull = convex_hulls[int(name)]
        for simplex in hull.simplices:
            plt.plot(hull.points[simplex, 0], hull.points[simplex, 1], "k-")

        plt.fill(
            hull.points[hull.vertices, 0],
            hull.points[hull.vertices, 1],
            alpha=0.2,
            color=color,
        )

    global n_islands
    groups_machines_by_id = machines.groupby("id")
    for name, group in groups_machines_by_id:
        color = cmap((int(name) + n_islands + 1) % 10)
        plt.plot(
            group.x,
            group.y,
            marker="^",
            linestyle="",
            markersize=7,
            label=f"Machine {name} Station",
            color=color,
        )

    plt.gcf().set_size_inches(plt.rcParams["figure.figsize"])
    plt.gca().set_aspect(0.8)
    plt.subplots_adjust(left=0.1, right=0.75, top=0.98, bottom=0.07)
    plt.legend(loc="center left", bbox_to_anchor=(1, 0.5))
    legend = plt.gca().get_legend()
    legend_width = legend.get_window_extent().width / plt.gcf().dpi

    fig_size = plt.gcf().get_size_inches()
    fig_size[0] += legend_width

    plt.gcf().set_size_inches(fig_size)

    global n_requests, n_vehicles, n_machines, filename
    figure_name = f"map_{n_requests:02}R_{n_vehicles:02}V_{n_islands:02}I_{n_machines:02}M_{filename}.pdf"
    plt.savefig(figure_name)
    plt.clf()
    plt.gcf().set_size_inches((0, 0))

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
    kmeans = kmeans_for_instance(points)
    
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

    global n_vehicles, args
    vehicles = gen_vehicles(n_vehicles, max_demand_req)
    jobs = gen_jobs(inst_jobs, kmeans)
    if ams:
        machines, convex_hulls = gen_machines_with_all_stations(kmeans, points)
    else:
        machines, convex_hulls = gen_machines(kmeans, points)

    jobs.to_csv("jobs.csv", header=False, index=False)
    vehicles.to_csv("vehicles.csv", header=False, index=False)
    machines.to_csv("machines.csv", header=False, index=False)

    # savePltFigInstanceMap(jobs, machines, convex_hulls) # uncomment to save instance map illustration

    if mf != "none":
        inst_location = os.getcwd()

        os.chdir("../../../../../../src/julia/")

        global min_n_machines
        cmd_str = f"julia pdptwse.jl --method_type heur --method_code {mf} --inst_path ../../instances/{new_group}/{type_code}/{filename}/ --make_instance_feasible --cut_off_machs {min_n_machines}"
        subprocess.run(cmd_str, shell=True)

        os.chdir(inst_location)


    os.chdir("../../../../../")

def main():
    # Define the parser
    parser = argparse.ArgumentParser(description="Your script description")

    # Define the arguments
    parser.add_argument("--group", type=str, default="pdptw_100_li_lim", help="Group of instances")
    parser.add_argument("--req", type=int, default=0, help="Number of requests")
    parser.add_argument("--vehi", type=int, default=0, help="Number of vehicles")
    parser.add_argument("--v_types", type=int, default=3, help="Number of vehicle types")
    parser.add_argument("--isl", type=int, default=0, help="Number of islands")
    parser.add_argument("--mach", type=int, default=0, help="Number of machines")
    parser.add_argument("--min_mach", type=int, default=0, help="Minimum Number of machines")
    parser.add_argument("--mach_spd", type=float, default=1, help="Machine speed")
    parser.add_argument(
        "--ams",
        action="store_true",
        help="Instances with all machine stations",
    )
    parser.add_argument(
        "--mf",
        choices=["gmutate", "none"],
        default="none",
        help="Heuristic to make instance feasible after generation",
    )
    parser.add_argument(
        "--var_cap",
        type=int,
        default=5,
        help="Vehicle Capacity variation from base capacity (%%). If base is 100 and the variation is 20%%, the vehicles capacities will be 80, 100%%, and 120, if v_types is 3",
    )
    parser.add_argument(
        "--pre_folder",
        type=str,
        default="orig_ams",
        help = "Folder before the new group folder"
    )

    # Parse the arguments
    args = parser.parse_args()

    # Set module-level globals used by helper functions
    global group, n_requests, n_jobs, n_vehicles, n_islands, n_machines
    global min_n_machines, v_types, var_cap, mach_spd, version, new_group, seed, filename
    global mf, ams

    group = args.group
    n_requests = args.req
    n_jobs = n_requests * 2
    n_vehicles = args.vehi
    n_islands = args.isl
    n_machines = args.mach
    min_n_machines = args.min_mach
    v_types = args.v_types
    var_cap = args.var_cap
    mach_spd = args.mach_spd
    mf = args.mf
    ams = args.ams
    pre_folder = args.pre_folder
    
    version = "multi_island"
    if not os.path.isdir(version):
        os.mkdir(version)
        
    if not os.path.isdir(f"{version}/{pre_folder}"):	
        os.mkdir(f"{version}/{pre_folder}")

    new_group = f"{version}/{pre_folder}/{n_requests:02d}R_{n_vehicles:02d}V_{n_islands:02d}I_{n_machines:02d}M"
    if not os.path.isdir(new_group):
        os.mkdir(new_group)

    seed = 1

    filenames = os.listdir(group)
    filenames.sort()
    for fname in filenames:
        if fname[0:2].lower() == "lc" or fname[0:3].lower() == "lrc" or fname[:-4:-1] != "txt":
            continue

        np.random.seed(seed)
        random.seed(seed)
        seed += 1

        filename = fname[:-4]
        gen_inst_files(filename, group, new_group)


if __name__ == "__main__":
    main()
