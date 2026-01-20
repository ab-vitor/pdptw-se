from typing import List

from modules.parameters import ParameterData
from modules.data import InstanceData
from .entities_sol import Solution, SolutionStats, VehicleStop, MachineTravel


def calculate_rate_machine_travel_time(
    inst: InstanceData, machines: List[List[MachineTravel]], with_vehicle: bool
) -> List[float]:
    machines_travel_times = [0.0 for _ in inst.H]
    for h in inst.H:
        mach = machines[h]
        previous_f = 1
        for travel in mach:
            machines_travel_times[h] += inst.O[(previous_f, inst.f[travel.orig, h], h)]
            previous_f = inst.f[travel.dest, h]
            if with_vehicle:
                machines_travel_times[h] += inst.O[
                    (inst.f[travel.orig, h], inst.f[travel.dest, h], h)
                ]
        if len(mach) > 0:
            machines_travel_times[h] /= inst.l[inst.depot_begin]
    return machines_travel_times


def calculate_rate_waiting_times_of_vehicles_for_a_machine_travel(
    inst: InstanceData,
    vehicles: List[List[VehicleStop]],
    machines: List[List[MachineTravel]],
    completionTimes: List[float],
) -> List[float]:
    vehicles_waiting_times = [0.0 for _ in inst.K]
    for k in inst.K:
        vehi: List[VehicleStop] = vehicles[k]
        for i in range(1, len(vehi)):
            cur: VehicleStop = vehi[i - 1]
            nxt: VehicleStop = vehi[i]
            if nxt.mach >= 0:
                v_arr = (
                    cur.servST + inst.s[cur.node] + inst.d_bar[(cur.node, nxt.mach, k)]
                )
                mtrv: MachineTravel = machines[nxt.mach][nxt.mach_ind]
                vehicles_waiting_times[k] += max(0, mtrv.st - v_arr)

        if len(vehi) > 2:
            vehicles_waiting_times[k] /= completionTimes[k]

    return vehicles_waiting_times


def calculate_rate_waiting_time_vehicles_for_a_service(
    inst: InstanceData, vehicles: List[List[VehicleStop]], completionTimes: List[float]
) -> List[float]:
    vehicles_waiting_times = [0.0 for _ in inst.K]
    for k in inst.K:
        vehi = vehicles[k]
        for i in range(1, len(vehi)):
            cur = vehi[i - 1]
            nxt = vehi[i]
            v_arr = cur.servST + inst.s[cur.node] + inst.d[(cur.node, nxt.node, k)]
            vehicles_waiting_times[k] += max(0, inst.e[nxt.node] - v_arr)
        if len(vehi) > 2:
            vehicles_waiting_times[k] /= completionTimes[k]
    return vehicles_waiting_times


def save_stats_solution(inst: InstanceData, bestSol: Solution, params: ParameterData) -> SolutionStats:
    vehicles = bestSol.vehicles
    machines = bestSol.machines
    completion_times = bestSol.completion_times

    n_vehicles = sum(1 for rt in vehicles if len(rt) > 2) / len(inst.K)
    n_machines = sum(1 for rt in machines if len(rt) > 0) / len(inst.H)

    min_ct = inst.l[inst.depot_begin]
    max_ct = 0.0
    mean_ct = 0.0
    max_load_vehicle = [0.0 for _ in inst.K]

    for k in inst.K:
        if completion_times[k] > params.epsilon:
            min_ct = min(min_ct, completion_times[k])
            max_ct = max(max_ct, completion_times[k])
            mean_ct += completion_times[k]
        max_load_vehicle[k] = max(
            stop.load / inst.vehicles[k].cap for stop in vehicles[k]
        )

    mean_ct /= sum(1 for rt in vehicles if len(rt) > 2)

    min_ct /= inst.l[inst.depot_begin]
    max_ct /= inst.l[inst.depot_begin]
    mean_ct /= inst.l[inst.depot_begin]

    mtw = calculate_rate_machine_travel_time(inst, machines, True)
    mtn = calculate_rate_machine_travel_time(inst, machines, False)

    avrg_mtwv = sum(mtw) / (n_machines * len(inst.H))
    avrg_mtov = avrg_mtwv - (sum(mtn) / (n_machines * len(inst.H)))
    avrg_mtnv = sum(mtn) / (n_machines * len(inst.H))

    vwmt = calculate_rate_waiting_times_of_vehicles_for_a_machine_travel(
        inst, vehicles, machines, completion_times
    )
    avrg_vwmt = sum(vwmt) / (n_vehicles * len(inst.K))

    vws = calculate_rate_waiting_time_vehicles_for_a_service(
        inst, vehicles, completion_times
    )
    avrg_vws = sum(vws) / (n_vehicles * len(inst.K))

    max_max_load = max(max_load_vehicle)
    min_max_load = min([load for load in max_load_vehicle if load > params.epsilon])
    mean_max_load = sum(max_load_vehicle) / (n_vehicles * len(inst.K))

    return SolutionStats(
        n_vehicles,
        n_machines,
        max_max_load,
        min_max_load,
        mean_max_load,
        min_ct,
        max_ct,
        mean_ct,
        mtw,
        mtn,
        max_load_vehicle,
        avrg_mtwv,
        avrg_mtov,
        avrg_mtnv,
        avrg_vwmt,
        avrg_vws,
    )
