from typing import List
from modules.parameters import ParameterData
from modules.data import InstanceData
from .entities_sol import Solution


def depot_flow_and_precedence_const(
    inst: InstanceData, sol: Solution, jobs_completed: List[tuple[bool, int]]
) -> bool:
    for k in inst.K:
        rt = sol.vehicles[k]
        fstop = rt[0]
        lstop = rt[-1]
        if fstop.job.id != 0:
            print("Vehicle ", inst.vehicles[k].id, " doesn't start at depot")
            return False
        jobs_completed[fstop.node] = [True, k]
        if lstop.job.id != 0:
            print("Vehicle ", inst.vehicles[k].id, " doesn't end at depot")
            return False
        jobs_completed[lstop.node] = [True, k]

        for i in range(1, len(rt) - 1):
            cstop = rt[i]
            if jobs_completed[cstop.node][0]:
                print(
                    "Task was already done by vehicle ", jobs_completed[cstop.node][1]
                )
                return False
            if cstop.job.did == 0:
                if (
                    jobs_completed[cstop.node - inst.n][1] == k
                    and not jobs_completed[cstop.node - inst.n][0]
                ):
                    print(
                        "Delivery job ",
                        cstop.job.id,
                        " was done before pickup ",
                        cstop.job.pid,
                    )
                    return False
                if (
                    jobs_completed[cstop.node - inst.n][1] != k
                    and jobs_completed[cstop.node - inst.n][0]
                ):
                    print(
                        "Pickup job ",
                        cstop.job.pid,
                        " was done by another vehicle (pv=",
                        jobs_completed[cstop.node - inst.n][1],
                        ") != (dv=",
                        k,
                        ")",
                    )
                    return False
            jobs_completed[cstop.node] = [True, k]
    return True


def all_jobs_completed_const(
    inst: InstanceData, jobs_completed: List[tuple[bool, int]]
) -> bool:
    for i in inst.Vprime:
        if not jobs_completed[i][0]:
            print("Task ", inst.jobs[inst.refs[i]].id, " was not done")
            return False
    return True


def capacity_const(inst: InstanceData, sol: Solution, params: ParameterData) -> bool:
    for k in inst.K:
        rt = sol.vehicles[k]
        for i in range(1, len(rt)):
            expected_load = rt[i - 1].load + rt[i].job.dem
            if abs(rt[i].load - expected_load) > params.epsilon_cap:
                print(
                    "Vehicle load just after leaving node ",
                    rt[i].job.id,
                    " is different than the expected (",
                    rt[i - 1].load + rt[i].job.dem,
                    ")",
                    sep="",
                )
                return False
            if (
                rt[i].load + params.epsilon_cap < 0
                or rt[i].load > inst.vehicles[k].cap + params.epsilon_cap
            ):
                print(
                    "Vehicle capacity was violated at position ",
                    i,
                    " of vehicle ",
                    inst.vehicles[k].id,
                    ". Curr load: ",
                    rt[i - 1].load,
                    "; Next demand: ",
                    rt[i].job.dem,
                    "; Vehicle capacity: ",
                    inst.vehicles[k].cap,
                    sep="",
                )
                return False
    return True


def consecutive_stops_vehicles_const(
    inst: InstanceData, sol: Solution, params: ParameterData
) -> bool:
    for k in inst.K:
        rt = sol.vehicles[k]
        for i in range(1, len(rt)):
            cur, nxt = rt[i - 1], rt[i]
            if (
                nxt.job.point.z == cur.job.point.z
                and nxt.servST + params.epsilon
                < cur.servST + inst.s[cur.node] + inst.d[cur.node][nxt.node][k]
            ):
                print(
                    "It's impossible to start the service time of request ",
                    cur.job.id,
                    " at ",
                    cur.servST,
                    " and arrive at ",
                    nxt.servST,
                    " in job ",
                    nxt.job.id,
                    sep="",
                )
                return False
    return True


def consecutive_travels_machines_const(
    inst: InstanceData, sol: Solution, params: ParameterData
) -> bool:
    for h in inst.H:
        mach = sol.machines[h]
        if mach:
            fmtrv = mach[0]
            if (
                h in inst.H_e[inst.depot_begin][fmtrv.orig]
                and fmtrv.st + params.epsilon
                < inst.O[(inst.initial_station, inst.f[fmtrv.orig, h], h)]
            ):
                print(
                    "Start time of travel 1 (",
                    fmtrv.st,
                    ") in machine ",
                    h,
                    " was before the machine arrives at the travel's origin (",
                    inst.O[(inst.initial_station, inst.f[fmtrv.orig, h], h)],
                    ")",
                    sep="",
                )
                return False

    for h in inst.H:
        mach = sol.machines[h]
        for i in range(1, len(mach)):
            cur, nxt = mach[i - 1], mach[i]
            if (
                h in inst.H_e[cur.orig][cur.dest]
                and h in inst.H_e[cur.dest][nxt.orig]
                and nxt.st + params.epsilon
                < cur.st
                + inst.O[(inst.f[cur.orig, h], inst.f[cur.dest, h], h)]
                + inst.O[(inst.f[cur.dest, h], inst.f[nxt.orig, h], h)]
            ):
                print(
                    "Start time of travel ",
                    i,
                    " (",
                    nxt.st,
                    ") in machine ",
                    inst.machines[h].id,
                    " was before the machine arrives at the travel's origin (",
                    cur.st
                    + inst.O[(inst.f[cur.orig, h], inst.f[cur.dest, h], h)]
                    + inst.O[(inst.f[cur.dest, h], inst.f[nxt.orig, h], h)],
                    ")",
                    sep="",
                )
                return False
    return True


def time_window_const(inst: InstanceData, sol: Solution, params: ParameterData) -> bool:
    for k in inst.K:
        for stop in sol.vehicles[k]:
            if stop.servST > stop.job.lat + params.epsilon:
                print(
                    "Vehicle ",
                    k,
                    " arrived at job ",
                    stop.job.id,
                    " after (",
                    stop.servST,
                    ") the end of time window (",
                    stop.job.lat,
                    ")",
                    sep="",
                )
                return False
    return True


def vehicle_machine_travel_synchronization_const(
    inst: InstanceData, sol: Solution, params: ParameterData
) -> bool:
    for h in inst.H:
        for travel in sol.machines[h]:
            cStop = sol.vehicles[travel.vehicle][travel.vehicle_ind - 1]
            nStop = sol.vehicles[travel.vehicle][travel.vehicle_ind]
            start_bound = (
                cStop.servST
                + inst.s[travel.orig]
                + inst.d_bar[travel.orig, h, travel.vehicle]
            )
            if travel.st + params.epsilon < start_bound:
                print(
                    "Start time of the travel ",
                    (cStop.job.id, nStop.job.id),
                    " is before vehicle ",
                    inst.vehicles[travel.vehicle].id,
                    " arrives at the machine ",
                    inst.machines[h].id,
                    ". (",
                    travel.st,
                    ") < (",
                    cStop.servST
                    + inst.s[travel.orig]
                    + inst.d_bar[travel.orig, h, travel.vehicle],
                    ")",
                    sep="",
                )
                return False
            end_bound = (
                travel.st
                + inst.O[(inst.f[travel.orig, h], inst.f[travel.dest, h], h)]
                + inst.d_bar[travel.dest, h, travel.vehicle]
            )
            if nStop.servST + params.epsilon < end_bound:
                print(
                    "Arrival time of vehicle ",
                    inst.vehicles[travel.vehicle].id,
                    " after the travel ",
                    (cStop.job.id, nStop.job.id),
                    " at machine ",
                    inst.machines[h].id,
                    " is after the given arrival time. (",
                    end_bound,
                    ") >= (",
                    nStop.servST,
                    ")",
                    sep="",
                )
                return False
    return True


def completion_times_const(
    inst: InstanceData, sol: Solution, params: ParameterData
) -> bool:
    for k in inst.K:
        completion_time_computed = (
            sol.vehicles[k][-1].servST - sol.vehicles[k][0].servST
        )
        if abs(completion_time_computed - sol.completion_times[k]) > params.epsilon:
            print(
                "Completion time computed (",
                completion_time_computed,
                ") is different from expected (",
                sol.completion_times[k],
                ")",
            )
            return False
    return True


def validate_solution(
    inst: InstanceData,
    sol: Solution,
    params: ParameterData,
    partial_validation: bool = False,
) -> bool:
    jobs_completed: List[tuple[bool, int]] = [[False, 0] for _ in inst.Vprime]

    if not depot_flow_and_precedence_const(inst, sol, jobs_completed):
        return False

    if not partial_validation and not all_jobs_completed_const(inst, jobs_completed):
        return False

    if not capacity_const(inst, sol, params):
        return False

    if not consecutive_stops_vehicles_const(inst, sol, params):
        return False

    if not consecutive_travels_machines_const(inst, sol, params):
        return False

    if not time_window_const(inst, sol, params):
        return False

    if params.validate_synchronization and not vehicle_machine_travel_synchronization_const(inst, sol, params):
        return False

    if not completion_times_const(inst, sol, params):
        return False

    return True
