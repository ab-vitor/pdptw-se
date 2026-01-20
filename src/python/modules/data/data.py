import csv
import math
import os
from copy import deepcopy

from .auxiliary_functions import euclidean_dist
from .preprocessing import build_eprime_lprime, is_arc_infeasible, is_precede_possible_ppd, preprocess_H_e
from .entities import InstanceData, Point, Vehicle, Machine, Job, PreprocessingData
from modules.parameters.entities import ParameterData
import numpy as np


def read_files(inst: InstanceData, params: ParameterData) -> None:
    # file paths
    veh_file = os.path.join(params.inst_path, "vehicles.csv")
    job_file = os.path.join(params.inst_path, "jobs.csv")
    mach_file = os.path.join(params.inst_path, "machines.csv")

    # read CSVs
    with open(veh_file) as f:
        raw_vehicles = list(csv.reader(f))
    with open(job_file) as f:
        raw_jobs = list(csv.reader(f))
    with open(mach_file) as f:
        raw_machines = list(csv.reader(f))

    # parse vehicles
    inst.vehicles = [Vehicle.from_list(row) for row in raw_vehicles if row]
    print("vehicles:", inst.vehicles)
    vehicle_types = deepcopy(inst.vehicles)
    # unique by capacity
    inst.vehicle_types = sorted(
        {v.cap: v for v in vehicle_types}.values(), key=lambda v: v.cap
    )
    print("vehicle_types:", inst.vehicle_types)

    # parse inst.jobs
    inst.jobs = [Job.from_list(row) for row in raw_jobs if row]

    # parse inst.machines and aggregate points
    inst.machines = []
    for row in raw_machines:
        if not row:
            continue
        mid = int(row[0])
        existing = next((m for m in inst.machines if m.id == mid), None)
        if existing:
            existing.points.append(Point.from_list(row[1:4]))
        else:
            inst.machines.append(Machine.from_list(row))
    # cut_off inst.machines
    while len(inst.machines) > params.cut_off_machs:
        inst.machines.pop()

    print("machines:", inst.machines)
    return None


def build_refs(inst: InstanceData, params: ParameterData) -> None:
    # determine cut_off for inst.jobs
    cut_off = params.cut_off or (len(inst.jobs) - 1) // 2
    inst.n = cut_off

    # build inst.refs
    inst.refs = [0]  # zero-based index for depot
    # pickup inst.refs
    for i, job in enumerate(inst.jobs):
        if job.dem > 0:
            inst.refs.append(i)
        if len(inst.refs) - 1 == cut_off:
            break

    prefs = inst.refs[1:].copy()
    # delivery inst.refs
    for pid in prefs:
        for i, job in enumerate(inst.jobs):
            if job.id == inst.jobs[pid].did:
                inst.refs.append(i)
                break
    inst.refs.append(0)  # return to depot
    print("refs:", inst.refs)
    return None


def build_constants(inst: InstanceData) -> None:
    inst.depot_begin = 0
    inst.depot_end = 2 * inst.n + 1
    inst.initial_station = 0
    inst.first_pickup = 1
    inst.last_pickup = inst.n
    inst.first_delivery = inst.n + 1
    inst.last_delivery = 2 * inst.n
    return None


def build_vertice_sets(inst: InstanceData) -> None:
    # build node sets
    inst.V = list(range(2 * inst.n + 1))
    inst.V_p = list(range(1, inst.n + 1))
    inst.V_d = list(range(inst.n + 1, 2 * inst.n + 1))
    inst.V_p_d = inst.V[1 : 2 * inst.n + 1]
    inst.Vprime = inst.V + [2 * inst.n + 1]

    print("V:", inst.V)
    print("V_p:", inst.V_p)
    print("V_d:", inst.V_d)
    print("V_p_d:", inst.V_p_d)
    print("Vprime:", inst.Vprime)
    return None


def build_vehicle_sets(inst: InstanceData) -> None:
    # inst.vehicles indices
    inst.K = list(range(len(inst.vehicles)))
    inst.Q = [v.cap for v in inst.vehicles]
    inst.max_Q = max(inst.Q)
    return None


def build_H(inst: InstanceData) -> None:
    # inst.machines indices
    inst.H = list(range(len(inst.machines)))
    print("H:", inst.H)

    print("Machine points:")
    for mach in inst.machines:
        print(f"# Machine {mach.id}")
        print("\t", end="")
        print(*mach.points, sep="\n\t")
        print()

    return None


def build_d_bar(inst: InstanceData) -> None:
    # inst.d_bar initialization
    inst.d_bar = np.zeros((len(inst.Vprime), len(inst.H), len(inst.K)))
    for i in inst.Vprime:
        for h in inst.H:
            for k in inst.K:
                pos = next(
                    (
                        idx
                        for idx, p in enumerate(inst.machines[h].points)
                        if p.z == inst.jobs[inst.refs[i]].point.z
                    ),
                    None,
                )
                if pos is not None:
                    inst.d_bar[i, h, k] = euclidean_dist(
                        inst.jobs[inst.refs[i]].point, inst.machines[h].points[pos], 0
                    )
                else:
                    inst.d_bar[i, h, k] = float("inf")

    inst.d_bar_min = np.zeros((len(inst.Vprime), len(inst.H)), dtype=float)
    inst.d_bar_max = np.zeros((len(inst.Vprime), len(inst.H)), dtype=float)
    for i in inst.Vprime:
        for h in inst.H:
            inst.d_bar_min[i, h] = np.min(inst.d_bar[i, h, :])
            inst.d_bar_max[i, h] = np.max(inst.d_bar[i, h, :])
    return None


def build_station_point_mapper(inst: InstanceData) -> None:
    # inst.f initialization
    inst.f = np.zeros((len(inst.Vprime), len(inst.H)), dtype=int)
    for i in inst.Vprime:
        for h in inst.H:
            pos = next(
                (
                    idx
                    for idx, p in enumerate(inst.machines[h].points)
                    if p.z == inst.jobs[inst.refs[i]].point.z
                ),
                -1,
            )
            inst.f[i, h] = pos

    print("f:", inst.f)
    return None


def build_O(inst: InstanceData, params: ParameterData) -> None:
    # inst.O initialization
    max_points_all_h = max([len(inst.machines[h].points) for h in inst.H])
    inst.O_matrix = np.zeros((max_points_all_h, max_points_all_h, len(inst.H)))

    inst.O = {}
    for h in inst.H:
        for i in range(len(inst.machines[h].points)):
            for j in range(len(inst.machines[h].points)):
                dist = (
                    euclidean_dist(
                        inst.machines[h].points[i],
                        inst.machines[h].points[j],
                        params.elevator,
                    )
                    / inst.machines[h].spd
                )
                inst.O[(i, j, h)] = dist
                inst.O_matrix[i, j, h] = dist

    for o, v in inst.O.items():
        print(o, v)
    return None


def can_be_used_to_traverse_the_arc(i: int, j: int, h: int, inst: InstanceData) -> bool:
    # check if machine h has stations for both jobs i and j
    job_i_z = inst.jobs[inst.refs[i]].point.z
    job_j_z = inst.jobs[inst.refs[j]].point.z
    has_station_for_i = any(p.z == job_i_z for p in inst.machines[h].points)
    has_station_for_j = any(p.z == job_j_z for p in inst.machines[h].points)

    if has_station_for_i and has_station_for_j:
        return True
    return False


def build_H_e(inst: InstanceData) -> None:
    # inst.H_e initialization
    inst.H_e = [[[] for _ in inst.Vprime] for _ in inst.Vprime]
    for i in inst.Vprime:
        for j in inst.Vprime:
            for h in inst.H:
                if can_be_used_to_traverse_the_arc(i, j, h, inst):
                    inst.H_e[i][j].append(h)
    # print("H_e ", inst.H_e)

    return None

def build_H_eprime(inst: InstanceData) -> None:
    # inst.H_eprime initialization
    if inst.n > 20:
        print("Skipping H_eprime construction for large instances (n > 20)")
        inst.H_eprime = None
        return None
    inst.H_eprime = [
        [
            [
                [
                    set(inst.H_e[i][j]).intersection(inst.H_e[iprime][jprime])
                    for jprime in inst.Vprime
                ]
                for iprime in inst.Vprime
            ]
            for j in inst.Vprime
        ]
        for i in inst.Vprime
    ]
    return None


def build_d(inst: InstanceData) -> None:
    # inst.d matrix
    inst.d = np.zeros((len(inst.Vprime), len(inst.Vprime), len(inst.K)), dtype=float)
    for i in inst.Vprime:
        for j in inst.Vprime:
            for k in inst.K:
                if inst.jobs[inst.refs[i]].point.z == inst.jobs[inst.refs[j]].point.z:
                    inst.d[i, j, k] = euclidean_dist(
                        inst.jobs[inst.refs[i]].point, inst.jobs[inst.refs[j]].point, 0
                    )
                else:
                    inst.d[i, j, k] = min(
                        [
                            inst.d_bar[i, h, k]
                            + inst.d_bar[j, h, k]
                            + inst.O[(inst.f[i, h], inst.f[j, h], h)]
                            for h in inst.H_e[i][j]
                        ]
                    )

    return None


def build_requests(inst: InstanceData) -> None:
    # inst.s array and inst.max_s
    inst.s = [inst.jobs[r].servt for r in inst.refs]
    inst.max_s = max(inst.s)

    # early and late value
    inst.e = [inst.jobs[r].earl for r in inst.refs]
    inst.l = [inst.jobs[r].lat for r in inst.refs]

    # demands
    inst.q = [inst.jobs[r].dem for r in inst.refs]
    inst.max_q = max(inst.q)
    print("q:", inst.q)

    return None


def build_arcs(inst: InstanceData) -> None:
    # is i,j in inst.Vprime in same region
    inst.diff_region = [
        [
            inst.jobs[inst.refs[i]].point.z != inst.jobs[inst.refs[j]].point.z
            for j in inst.Vprime
        ]
        for i in inst.Vprime
    ]

    inst.A = []
    inst.ppd.arcs = len(inst.Vprime) * len(inst.Vprime)
    for i in inst.Vprime:
        for j in inst.Vprime:
            if not is_arc_infeasible(i, j, inst):
                inst.A.append((i, j))

    print(f"Number of arcs: {len(inst.A)}")

    # inst.A_m and inst.A_s
    inst.A_m = [
        (i, j)
        for (i, j) in inst.A
        if inst.jobs[inst.refs[i]].point.z != inst.jobs[inst.refs[j]].point.z
    ]
    inst.A_s = [
        (i, j)
        for (i, j) in inst.A
        if inst.jobs[inst.refs[i]].point.z == inst.jobs[inst.refs[j]].point.z
    ]

    inst.idx_A_m = np.zeros((len(inst.Vprime), len(inst.Vprime)), dtype=int)
    for i in inst.Vprime:
        for j in inst.Vprime:
            try:
                inst.idx_A_m[i, j] = inst.A_m.index((i, j))
            except ValueError:
                inst.idx_A_m[i, j] = -1

    inst.origins_A_m = [i for (i, _) in inst.A_m]
    inst.destinies_A_m = [j for (_, j) in inst.A_m]


    inst.in_A = np.zeros((len(inst.Vprime), len(inst.Vprime)))
    for i, j in inst.A:
        inst.in_A[i, j] = 1

    inst.in_A_m = np.zeros((len(inst.Vprime), len(inst.Vprime)))
    for i, j in inst.A_m:
        inst.in_A_m[i, j] = 1

    inst.in_A_s = np.zeros((len(inst.Vprime), len(inst.Vprime)))
    for i, j in inst.A_s:
        inst.in_A_s[i, j] = 1

def build_feas_gamma(inst: InstanceData) -> None:
    # inst.feas_gamma initialization
    if inst.n > 20:
        print("Skipping feas_gamma construction for large instances (n > 20)")
        inst.feas_gamma = None
        for i,j in inst.A_m:
            for ip, jp in inst.A_m:
                common_h = set(inst.H_e[i][j]).intersection(set(inst.H_e[ip][jp]))
                for h in common_h:
                    inst.ppd.gamma_vars += 1
                    if is_precede_possible_ppd(i, j, ip, jp, h, inst):
                        inst.ppd.feas_gamma_vars += 1
        return None
    inst.feas_gamma = np.zeros(
        (
            len(inst.Vprime),
            len(inst.Vprime),
            len(inst.Vprime),
            len(inst.Vprime),
            len(inst.H),
        )
    )
    for i, j in inst.A_m:
        for ip, jp in inst.A_m:
            for h in inst.H_eprime[i][j][ip][jp]:
                inst.ppd.gamma_vars += 1
                if is_precede_possible_ppd(i, j, ip, jp, h, inst):
                    inst.feas_gamma[i, j, ip, jp, h] = 1
                    inst.ppd.feas_gamma_vars += 1
                    
    return None

def build_minimums_and_maximums(inst: InstanceData) -> None:
    # inst.dmax_vehicle and inst.dmin_vehicle
    inst.dmax_vehicle = np.max(inst.d, axis=2)
    inst.dmin_vehicle = np.min(inst.d, axis=2)
    
    return None


def build_big_M(inst: InstanceData) -> None:
    # big M constants initialization
    # inst.max_d
    inst.max_d = max(inst.d[i, j, k] for (i, j) in inst.A for k in inst.K)
    
    # inst.M vector
    inst.M = np.zeros(
        9, dtype=int
    )  # ignore first, just to make inst.M[1] = M_1 of the paper
    inst.M[1] = math.ceil(inst.max_Q + inst.max_q + 1)

    inst.M[2] = math.ceil(
        inst.jobs[inst.refs[inst.depot_begin]].lat + inst.max_s + inst.max_d + 1
    )

    inst.M[3] = math.ceil(inst.jobs[inst.refs[inst.depot_begin]].lat + inst.max_d + 1)

    max_d_bar = max(
        inst.d_bar[i, h, k]
        for i in inst.Vprime
        for h in inst.H
        for k in inst.K
        if inst.f[i, h] != -1
    )
    inst.M[4] = math.ceil(
        inst.jobs[inst.refs[inst.depot_begin]].lat + inst.max_s + max_d_bar + 1
    )

    inst.M[5] = math.ceil(inst.jobs[inst.refs[inst.depot_begin]].lat + max_d_bar + 1)

    max_O = max(
        inst.O[(i, j, h)]
        for h in inst.H
        for i in range(len(inst.machines[h].points))
        for j in range(len(inst.machines[h].points))
    )
    inst.M[6] = math.ceil(
        inst.jobs[inst.refs[inst.depot_begin]].lat + max_O + max_d_bar + 1
    )

    inst.M[7] = math.ceil(inst.jobs[inst.refs[inst.depot_begin]].lat + 2 * max_O + 1)

    inst.M[8] = math.ceil(max_O + 1)
    print("M: ", *enumerate(inst.M))
    return None



def print_jobs(inst: InstanceData) -> None:
    print("JOBS in the order of refs (Vprime)")
    for i in inst.Vprime:
        ref = inst.refs[i]
        print(f"Node {i}: {inst.jobs[ref]}")
    return None


def print_preprocessingdata(ppd: PreprocessingData) -> None:
    print()
    print("### Preprocessing Data ###")
    for field in vars(ppd):
        if "arc" in field:
            value = getattr(ppd, field)
            try:
                perc = round(100 * value / ppd.arcs, 2)
            except Exception:
                perc = 0
            print(f"\t-> {field}: {value} ({perc}%)")
        elif "gamma" in field:
            value = getattr(ppd, field)
            try:
                perc = round(100 * value / ppd.gamma_vars, 2)
            except Exception:
                perc = 0
            print(f"\t-> {field}: {value} ({perc}%)")
        elif "machine" in field:
            value = getattr(ppd, field)
            print(f"\t-> {field}: {value}")
    print("##########################")
    return None


def read_data(params: ParameterData) -> InstanceData:
    print(f"\n[Reading Data] Using files at {params.inst_path}")
    inst = InstanceData()

    read_files(inst, params)
    build_refs(inst, params)
    build_constants(inst)
    build_vertice_sets(inst)
    build_vehicle_sets(inst)
    build_requests(inst)
    build_H(inst)
    build_d_bar(inst)
    build_station_point_mapper(inst)
    build_O(inst, params)
    build_H_e(inst)
    build_H_eprime(inst)
    build_d(inst)
    build_minimums_and_maximums(inst)
    build_eprime_lprime(inst)
    build_arcs(inst)
    build_big_M(inst)
    
    preprocess_H_e(inst)
    build_H_eprime(inst)
    build_feas_gamma(inst)
    
    inst.name = params.name
    inst.group = params.group
    inst.type = params.type
    inst.full_name = params.full_name

    print_jobs(inst)
    print_preprocessingdata(inst.ppd)

    return inst


def write_preprocessingdata_to_csv(inst: InstanceData, params: ParameterData) -> None:
    ppd = inst.ppd
    output_dir = os.path.join(params.output, "preprocessing")
    os.makedirs(output_dir, exist_ok=True)
    file_path = os.path.join(output_dir, "preprocessing.csv")

    # Add instance metadata fields
    instance_info = {
        "name": getattr(inst, "name", ""),
        "group": getattr(inst, "group", ""),
        "type": getattr(inst, "type", ""),
    }

    fieldnames = list(instance_info.keys()) + list(vars(ppd).keys())
    write_header = False

    if not os.path.exists(file_path):
        write_header = True
    else:
        with open(file_path, "r", newline="") as f:
            try:
                first_line = f.readline()
                if not first_line:
                    write_header = True
            except Exception:
                write_header = True

    with open(file_path, "a", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        if write_header:
            writer.writeheader()
        row = {**instance_info, **{k: getattr(ppd, k) for k in vars(ppd).keys()}}
        writer.writerow(row)
