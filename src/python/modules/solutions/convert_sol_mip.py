from typing import List

from modules.parameters import ParameterData
from modules.data import InstanceData
from .entities_mip_sol import MIPSolution
from .entities_sol import VehicleStop, MachineTravel, Solution, StatsSolution
from .statistics import save_stats_solution
from .print_detailed import print_detail_melo_formulation_solution


def get_machine_attending_arc(
    i: int, j: int, inst: InstanceData, mip_sol: MIPSolution, params: ParameterData
) -> int:
    for h in inst.H:
        if h in inst.H_e[i][j] and abs(mip_sol.vars.phi[i, j, h] - 1) <= 0.1:
            return h

    print("opa opa opa")
    return -1  # should never happen in a feasible solution


def get_next_node_route(
    i: int, k: int, inst: InstanceData, mip_sol: MIPSolution, params: ParameterData
) -> int:
    for j in inst.Vprime:
        if (i, j) in inst.A and abs(mip_sol.vars.x[i, j, k] - 1) <= 0.1:
            return j

    print("opa opa opa")
    return -1  # should never happen in a feasible solution


def create_vehicles(
    inst: InstanceData, mip_sol: MIPSolution, params: ParameterData
) -> tuple[List[int], dict]:
    vehicles = [[] for _ in inst.K]
    arcsh_kp = {}

    for k in inst.K:
        load = 0
        i = inst.depot_begin
        vehicles[k].append(
            VehicleStop(
                node=i,
                job=inst.jobs[inst.refs[i]],
                servST=mip_sol.vars.tstart[k],
                mach=-1,
                mach_ind=-1,
                load=load,
            )
        )

        j = get_next_node_route(i, k, inst, mip_sol, params)
        load += inst.q[j]
        h = -1
        if (i, j) in inst.A_m:
            h = get_machine_attending_arc(i, j, inst, mip_sol, params)
            arcsh_kp[(i, j, h)] = (k, len(vehicles[k]))

        while j != inst.depot_end:
            vehicles[k].append(
                VehicleStop(
                    node=j,
                    job=inst.jobs[inst.refs[j]],
                    servST=mip_sol.vars.t[j],
                    mach=h,
                    mach_ind=-1,
                    load=load,
                )
            )

            i = j
            j = get_next_node_route(i, k, inst, mip_sol, params)
            load += inst.q[j]
            h = -1
            if (i, j) in inst.A_m:
                h = get_machine_attending_arc(i, j, inst, mip_sol, params)
                arcsh_kp[(i, j, h)] = (k, len(vehicles[k]))

        vehicles[k].append(
            VehicleStop(
                node=j,
                job=inst.jobs[inst.refs[j]],
                servST=mip_sol.vars.tfinal[k],
                mach=h,
                mach_ind=-1,
                load=load,
            )
        )

    return vehicles, arcsh_kp


def create_solution_melo(
    inst: InstanceData, mip_sol: MIPSolution, params: ParameterData
) -> Solution:
    vehicles, arcsh_kp = create_vehicles(inst, mip_sol, params)

    machines = [[] for _ in inst.H]
    completion_times = []

    ordered_alpha = [[] for _ in inst.H]
    for h in inst.H:
        for i, j in inst.A_m:
            if h in inst.H_e[i][j] and abs(mip_sol.vars.phi[i, j, h] - 1) <= 0.1:
                ordered_alpha[h].append((mip_sol.vars.alpha[i, j, h], i, j))
        ordered_alpha[h].sort(key=lambda x: x[0])

    for h in inst.H:
        for st, i, j in ordered_alpha[h]:
            if abs(mip_sol.vars.phi[i, j, h] - 1) <= 0.1:
                k, p = arcsh_kp[(i, j, h)]
                machines[h].append(MachineTravel(k, p, i, j, st, True))
                stop: VehicleStop = vehicles[k][p]
                stop.mach_ind = len(machines[h]) - 1

    for k in inst.K:
        completion_times.append(round(mip_sol.vars.C[k], 5))

    sol = Solution(
        vehicles=vehicles,
        machines=machines,
        completion_times=completion_times,
        is_feasible=True,
        value=mip_sol.stats.obj_value,
        stats=StatsSolution(),
    )
    sol.stats = save_stats_solution(inst, sol, params)
    return sol

