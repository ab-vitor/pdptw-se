from typing import List

from modules.parameters import ParameterData
from modules.data import InstanceData
from .entities_mip_hexaly_sol import MIPHxSolution
from .entities_sol import VehicleStop, MachineTravel, Solution, SolutionStats
from .statistics import save_stats_solution


def get_machine_attending_arc(
    i: int, j: int, inst: InstanceData, mip_hx_sol: MIPHxSolution, params: ParameterData
) -> int:
    for h in inst.H:
        if h in inst.H_e[i][j] and abs(mip_hx_sol.vars.phi[i, j, h] - 1) <= 0.1:
            return h
    
    return -1  # should never happen in a feasible solution


def get_next_node_route(
    i: int, k: int, inst: InstanceData, mip_hx_sol: MIPHxSolution, params: ParameterData
) -> int:
    for j in inst.Vprime:
        if (i, j) in inst.A and abs(mip_hx_sol.vars.x[i, j, k] - 1) <= 0.1:
            return j

    return -1  # should never happen in a feasible solution


def create_vehicles(
    inst: InstanceData, mip_hx_sol: MIPHxSolution, params: ParameterData
) -> tuple[List[int], dict]:
    vehicles = [[] for _ in inst.K]
    arcsh_kp = {}

    for k in inst.K:
        i = inst.depot_begin
        vehicles[k].append(
            VehicleStop(
                node=i,
                job=inst.jobs[inst.refs[i]],
                servST=mip_hx_sol.vars.tstart[k],
                mach=-1,
                mach_ind=-1,
                load=mip_hx_sol.vars.z[i, k],
            )
        )

        j = get_next_node_route(i, k, inst, mip_hx_sol, params)
        h = -1
        if (i, j) in inst.A_m:
            h = get_machine_attending_arc(i, j, inst, mip_hx_sol, params)
            arcsh_kp[(i, j, h)] = (k, len(vehicles[k]))

        while j != inst.depot_end:
            vehicles[k].append(
                VehicleStop(
                    node=j,
                    job=inst.jobs[inst.refs[j]],
                    servST=mip_hx_sol.vars.t[j],
                    mach=h,
                    mach_ind=-1,
                    load=mip_hx_sol.vars.z[j, k],
                )
            )

            i = j
            j = get_next_node_route(i, k, inst, mip_hx_sol, params)
            h = -1
            if (i, j) in inst.A_m:
                h = get_machine_attending_arc(i, j, inst, mip_hx_sol, params)
                arcsh_kp[(i, j, h)] = (k, len(vehicles[k]))

        vehicles[k].append(
            VehicleStop(
                node=j,
                job=inst.jobs[inst.refs[j]],
                servST=mip_hx_sol.vars.tfinal[k],
                mach=h,
                mach_ind=-1,
                load=mip_hx_sol.vars.z[j, k],
            )
        )

    return vehicles, arcsh_kp


def create_solution_mip_hexaly(
    inst: InstanceData, mip_hx_sol: MIPHxSolution, params: ParameterData
) -> Solution:
    vehicles, arcsh_kp = create_vehicles(inst, mip_hx_sol, params)

    machines = [[] for _ in inst.H]
    completion_times = []

    ordered_alpha = [[] for _ in inst.H]
    for h in inst.H:
        for i, j in inst.A_m:
            if h in inst.H_e[i][j] and abs(mip_hx_sol.vars.phi[i, j, h] - 1) <= 0.1:
                ordered_alpha[h].append((mip_hx_sol.vars.alpha[i, j, h], i, j))
        ordered_alpha[h].sort(key=lambda x: x[0])

    for h in inst.H:
        for st, i, j in ordered_alpha[h]:
            if abs(mip_hx_sol.vars.phi[i, j, h] - 1) <= 0.1:
                k, p = arcsh_kp[(i, j, h)]
                machines[h].append(MachineTravel(k, p, i, j, st, True))
                stop: VehicleStop = vehicles[k][p]
                stop.mach_ind = len(machines[h]) - 1

    for k in inst.K:
        completion_times.append(round(mip_hx_sol.vars.C[k], 5))

    sol = Solution(
        vehicles=vehicles,
        machines=machines,
        completion_times=completion_times,
        is_feasible=True,
        value=mip_hx_sol.stats.obj_value,
        stats=SolutionStats(),
    )
    sol.stats = save_stats_solution(inst, sol, params)
    return sol

