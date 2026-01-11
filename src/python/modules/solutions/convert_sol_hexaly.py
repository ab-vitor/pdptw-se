from typing import List

from modules.parameters import ParameterData
from modules.data import InstanceData
from .entities_barlo_hexaly_sol import BarloHxSolution
from .entities_sol import VehicleStop, MachineTravel, Solution, StatsSolution
from .statistics import save_stats_solution
from .print_detailed import print_detail_melo_formulation_solution


def get_machine_attending_arc(
    i: int,
    j: int,
    inst: InstanceData,
    barlo_hx_sol: BarloHxSolution,
    params: ParameterData,
) -> int:
    for h in inst.H:
        if h in inst.H_e[i][j] and abs(barlo_hx_sol.vars.phi[i, j, h] - 1) <= 0.1:
            return h

    print("opa opa opa")
    return -1  # should never happen in a feasible solution


def get_next_node_route(
    i: int,
    k: int,
    inst: InstanceData,
    barlo_hx_sol: BarloHxSolution,
    params: ParameterData,
) -> int:
    for j in inst.Vprime:
        if (i, j) in inst.A and abs(barlo_hx_sol.vars.x[i, j, k] - 1) <= 0.1:
            return j

    print("opa opa opa")
    return -1  # should never happen in a feasible solution


def find_machine_travel_indices_in_trajectories(
    i: int,
    hx_route: List[int],
    inst: InstanceData,
    barlo_hx_sol: BarloHxSolution,
    params: ParameterData,
) -> tuple[int, int]:
    trajectories = barlo_hx_sol.vars.trajectories
    offset = 1
    mach, mach_ind = -1, -1

    if len(hx_route) == 0:
        return mach, mach_ind

    if i == 0:
        orig = inst.depot_begin
    else:
        orig = hx_route[i - 1] + offset

    if i == len(hx_route):
        dest = inst.depot_end
    else:
        dest = hx_route[i] + offset

    if not inst.diff_region[orig][dest]:
        return mach, mach_ind

    for h in inst.H:
        trajectory = trajectories[h]
        for j in range(len(trajectory)):
            index_A_m = trajectory[j]
            if (
                inst.origins_A_m[index_A_m] == orig
                and inst.destinies_A_m[index_A_m] == dest
            ):
                mach, mach_ind = h, j
                return mach, mach_ind

    return mach, mach_ind


def create_vehicles(
    inst: InstanceData, barlo_hx_sol: BarloHxSolution, params: ParameterData
) -> List[int]:
    hx_routes = barlo_hx_sol.vars.routes
    hx_routes_loads = barlo_hx_sol.vars.routes_loads
    hx_service_start_times = barlo_hx_sol.vars.service_start_times

    vehicles = [[] for _ in inst.K]
    offset: int = 1
    for k in inst.K:
        node = inst.depot_begin
        vehicles[k].append(
            VehicleStop(
                node=node,
                job=inst.jobs[inst.refs[node]],
                servST=barlo_hx_sol.vars.tstart[k],
                mach=-1,
                mach_ind=-1,
                load=0,
            )
        )
        hx_route = hx_routes[k]
        hx_route_loads = hx_routes_loads[k]
        hx_service_start_times_k = hx_service_start_times[k]
        for i in range(len(hx_route)):
            node = hx_route[i] + offset
            mach, mach_ind = find_machine_travel_indices_in_trajectories(
                i=i,
                hx_route=hx_route,
                inst=inst,
                barlo_hx_sol=barlo_hx_sol,
                params=params,
            )

            vehicles[k].append(
                VehicleStop(
                    node=node,
                    job=inst.jobs[inst.refs[node]],
                    servST=hx_service_start_times_k[i],
                    mach=mach,
                    mach_ind=mach_ind,
                    load=hx_route_loads[i],
                )
            )

        mach, mach_ind = find_machine_travel_indices_in_trajectories(
            i=len(hx_route),
            hx_route=hx_route,
            inst=inst,
            barlo_hx_sol=barlo_hx_sol,
            params=params,
        )
        node = inst.depot_end
        vehicles[k].append(
            VehicleStop(
                node=node,
                job=inst.jobs[inst.refs[node]],
                servST=barlo_hx_sol.vars.tfinal[k],
                mach=mach,
                mach_ind=mach_ind,
                load=0,
            )
        )

    return vehicles


def get_next_node_route(
    i: int,
    k: int,
    inst: InstanceData,
    barlo_hx_sol: BarloHxSolution,
    params: ParameterData,
) -> int:
    for j in inst.Vprime:
        if (i, j) in inst.A and abs(barlo_hx_sol.vars.x[i, j, k] - 1) <= 0.1:
            return j

    print("opa opa opa")
    return -1  # should never happen in a feasible solution


def find_vehicle_customers_indices_in_routes(
    i: int,
    hx_trajectory: List[int],
    inst: InstanceData,
    vehicles: List[List[VehicleStop]],
    params: ParameterData,
) -> tuple[int, int]:

    vehicle, vehicle_ind = -1, -1

    index_A_m = hx_trajectory[i]
    orig = inst.origins_A_m[index_A_m]
    dest = inst.destinies_A_m[index_A_m]

    for k in inst.K:
        vehi = vehicles[k]
        for j in range(1, len(vehi)):
            curr = vehi[j].node
            prev = vehi[j - 1].node

            if prev == orig and curr == dest:
                vehicle, vehicle_ind = k, j
                return vehicle, vehicle_ind

    # should never happen
    return vehicle, vehicle_ind


def create_machines(
    inst: InstanceData,
    barlo_hx_sol: BarloHxSolution,
    vehicles: List[List[VehicleStop]],
    params: ParameterData,
) -> List[int]:
    hx_trajectories = barlo_hx_sol.vars.trajectories
    hx_machine_travels_start_times = barlo_hx_sol.vars.machine_travels_start_times

    machines = [[] for _ in inst.H]
    for h in inst.H:
        hx_trajectory = hx_trajectories[h]
        hx_machine_travels_start_times_h = hx_machine_travels_start_times[h]
        for i in range(len(hx_trajectory)):
            index_A_m = hx_trajectory[i]
            orig = inst.origins_A_m[index_A_m]
            dest = inst.destinies_A_m[index_A_m]
            vehicle, vehicle_ind = find_vehicle_customers_indices_in_routes(
                i=i,
                hx_trajectory=hx_trajectory,
                inst=inst,
                vehicles=vehicles,
                params=params,
            )

            machines[h].append(
                MachineTravel(
                    vehicle=vehicle,
                    vehicle_ind=vehicle_ind,
                    orig=orig,
                    dest=dest,
                    st=hx_machine_travels_start_times_h[i],
                    active=True,
                )
            )

    return machines


def create_completion_times(
    inst: InstanceData, barlo_hx_sol: BarloHxSolution
) -> List[float]:
    completion_times = []

    for k in inst.K:
        completion_times.append(round(barlo_hx_sol.vars.C[k], 2))

    return completion_times


def create_solution_hexaly(
    inst: InstanceData, barlo_hx_sol: BarloHxSolution, params: ParameterData
) -> Solution:
    vehicles = create_vehicles(inst, barlo_hx_sol, params)
    machines = create_machines(inst, barlo_hx_sol, vehicles, params)
    completion_times = create_completion_times(inst, barlo_hx_sol)

    sol = Solution(
        vehicles=vehicles,
        machines=machines,
        completion_times=completion_times,
        is_feasible=True,
        value=barlo_hx_sol.stats.obj_value,
        stats=StatsSolution(),
    )
    sol.stats = save_stats_solution(inst, sol, params)
    return sol
