import math
from typing import List, Optional

import numpy as np
from hexaly.optimizer import (
    HexalyOptimizer,
    HxParam,
    HxSolution,
    HxSolutionStatus,
    HxStatistics,
    HxCallbackType,
    HxExpression,
    HxCollection,
)

from modules.parameters import ParameterData
from modules.data import InstanceData, Job
from modules.solutions import (
    Solution,
    VehicleStop,
    MachineTravel,
    BarloHxSolution,
    BarloHxStats,
    BarloHxVarsSolution,
    create_solution_hexaly,
)
from .create_barlogon_hexaly_model import create_barlogon_hexaly_model
from .entities_barlogon_hexaly_formulation import (
    BarlogonHxModel,
    BarlogonHxRoutingVars,
    BarlogonHxSchedulingVars,
)


class SolutionCounterCallback:
    def __init__(self, max_solutions, obj_expr):
        self.max_solutions = max_solutions
        self.solution_count = 0
        self.last_solution_value = math.inf
        self.obj_expr = obj_expr

    def callback(self, optimizer: HexalyOptimizer, event_type):
        # Check if a new solution has been found
        if optimizer.solution is not None:
            sol: HxSolution = optimizer.solution
            if (
                sol.get_status()
                in (
                    HxSolutionStatus.FEASIBLE,
                    HxSolutionStatus.OPTIMAL,
                )
                and sol.get_value(self.obj_expr) + 0.005 < self.last_solution_value
            ):
                print(f"New solution found.")
                self.last_solution_value = sol.get_value(self.obj_expr)
                self.solution_count += 1
                if self.solution_count >= self.max_solutions:
                    print(
                        f"Reached {self.max_solutions} solutions. Stopping the solver."
                    )
                    optimizer.stop()


def print_node_details(node: int, job: Job, servST: float, inst: InstanceData):
    print(f"\tnode: {node}")
    print(f"\t\tpoint: {job.point}")
    print(f"\t\tearl: {inst.e[node]}")
    print(f"\t\tlat: {inst.l[node]}")
    print(f"\t\tservt: {inst.s[node]}")
    print(f"\t\tservST: {servST}")


def inject_initial_solution(
    sol: Solution,
    barlo_hx_model: BarlogonHxModel,
    inst: InstanceData,
    params: ParameterData,
) -> None:
    rtvars = barlo_hx_model.rtvars
    schvars = barlo_hx_model.schvars
    routes: List[HxExpression] = rtvars.routes
    trajectories: List[HxExpression] = rtvars.trajectories
    tstart: List[HxExpression] = schvars.tstart
    tfinal: List[HxExpression] = schvars.tfinal
    waiting_times: List[HxExpression] = schvars.waiting_times
    C: List[HxExpression] = schvars.C
    offset: int = 1

    for k in inst.K:
        vehi = sol.vehicles[k]
        values_route: HxCollection = routes[k].value
        depot_begin_stop: VehicleStop = vehi[0]
        tstart[k].value = depot_begin_stop.servST
        print(f"Vehicle {k}:", end=" ")
        for i in range(1, len(vehi) - 1):
            stop: VehicleStop = vehi[i]
            values_route.add(stop.node - offset)
            print(stop.node - offset, end=" ")
        print()
        print(values_route)
        print()
        depot_end_stop: VehicleStop = vehi[-1]
        tfinal[k].value = depot_end_stop.servST
        C[k].value = sol.completion_times[k]

    for h in inst.H:
        mach = sol.machines[h]
        values_traj: HxCollection = trajectories[h].value
        print(f"Machine {h}:")
        prev = 0
        for i in range(len(mach)):
            mtrv: MachineTravel = mach[i]
            orig, dest = mtrv.orig, mtrv.dest
            idx_A_m = inst.idx_A_m[orig, dest]
            print(f"({orig}, {dest}): {idx_A_m} ", end=" ")
            values_traj.add(idx_A_m)
            prev_orig, prev_dest = (
                (mach[i - 1].orig, mach[i - 1].dest) if i > 0 else (-1, -1)
            )
            prev_station_orig = (
                inst.f[prev_orig, h] if prev_orig >= 0 else inst.initial_station
            )
            prev_station_dest = (
                inst.f[prev_dest, h] if prev_dest >= 0 else inst.initial_station
            )
            station_orig = inst.f[orig, h]

            machine_arrival_time = (
                prev
                + inst.O_matrix[prev_station_orig, prev_station_dest, h]
                + inst.O_matrix[prev_station_dest, station_orig, h]
            )
            waiting_time = max(0, mtrv.st - machine_arrival_time)
            prev = machine_arrival_time + waiting_time
            print(f"waiting time: {waiting_time}")
            waiting_times[idx_A_m].set_value(waiting_time)

        print()
        print(values_traj)


def find_h_and_index(
    machines: List[List[int]], idx_A_m: int, inst: InstanceData
) -> tuple[int, int]:
    for h in inst.H:
        trajectory: List[int] = machines[h]
        for i in range(trajectory):
            arc = trajectory[i]
            if arc == idx_A_m:
                return h, i
    return -1, -1  # Not found


def find_orig_k_and_index(
    vehicles: List[List[int]], target: int, dest: int, inst: InstanceData
) -> tuple[int, int]:
    offset_idx = 0
    if target == inst.depot_begin:
        target = dest
        offset_idx = -1

    offset = 1
    for k in inst.K:
        route: List[int] = vehicles[k]
        if len(route) == 0:
            continue
        for i in range(len(route)):
            curr = route[i] + offset
            if curr == target:
                return k, i + offset_idx

    return -1, -1  # Not found


def find_k_and_index(
    vehicles: List[List[int]], idx_A_m: int, inst: InstanceData
) -> tuple[int, int]:
    offset = 1
    for k in inst.K:
        route: List[int] = vehicles[k]
        if len(route) == 0:
            continue
        arc_orig = inst.depot_begin
        arc_dest = route[0] + offset
        arc = inst.idx_A_m[arc_orig, arc_dest]
        if arc == idx_A_m:
            return k, 0

        for i in range(len(route) - 1):
            arc_orig = route[i] + offset
            arc_dest = route[i + 1] + offset
            arc = inst.idx_A_m[arc_orig, arc_dest]
            if arc == idx_A_m:
                return k, i + 1

        arc_orig = route[-1] + offset
        arc_dest = inst.depot_end
        arc = inst.idx_A_m[arc_orig, arc_dest]
        if arc == idx_A_m:
            return k, len(route)
    return -1, -1  # Not found


def analyze_restriction_violations(
    inst: InstanceData, params: ParameterData, barlo_hx_model: BarlogonHxModel
) -> None:
    rtvars = barlo_hx_model.rtvars
    schvars = barlo_hx_model.schvars

    routes = rtvars.routes
    trajectories = rtvars.trajectories
    offset = 1

    for k in inst.K:
        route = routes[k].value
        print(route)

    machines = []
    for h in inst.H:
        trajectory = trajectories[h].value
        machines.append(trajectory)
        print(trajectory)

    for k in inst.K:
        route = routes[k].value
        c = len(route)  # number of customers in route k

        print(f"\n--- Vehicle {k}, route length = {c} ---")
        for i in range(c):
            # Evaluate whether this is first/last
            is_first = i == 0
            is_last = i == c - 1

            # Compute u and v
            u_val = inst.depot_begin if is_first else route[i - 1] + offset
            v_val = route[i] + offset
            last_v_val = inst.depot_end

            arc_exists = inst.diff_region[u_val][v_val]
            last_arc_exists = inst.diff_region[v_val][last_v_val]

            arc_idx_val = inst.idx_A_m[u_val, v_val]
            last_arc_idx_val = inst.idx_A_m[v_val, last_v_val]

            arc_found = False
            for h in inst.H:
                traj_arr = trajectories[h].value
                arc_found = arc_idx_val in traj_arr
                if arc_found:
                    break

            last_arc_found = False
            for h in inst.H:
                traj_arr = trajectories[h].value
                last_arc_found = last_arc_idx_val in traj_arr
                if last_arc_found:
                    break

            print(
                f" u={u_val} -> v={v_val} | exists={arc_exists} idx={arc_idx_val} found={arc_found}"
                + (
                    f" u={u_val} -> v={last_v_val} | exists={last_arc_exists} idx={last_arc_idx_val} found={last_arc_found}\n"
                    if is_last
                    else ""
                )
            )

    tfinal: List[HxExpression] = schvars.tfinal
    tstart: List[HxExpression] = schvars.tstart
    services_start_times: List[HxExpression] = schvars.services_start_times
    machine_travels_start_times: List[HxExpression] = (
        schvars.machine_travels_start_times
    )

    offset: int = 1

    for k in inst.K:
        print(tstart[k].value, end=" ")
        print(services_start_times[k].value, end=" ")
        print(tfinal[k].value)

    print()
    for h in inst.H:
        print(machine_travels_start_times[h].value)

    for k in inst.K:
        route = [routes[k].value[i] for i in range(len(routes[k].value))]
        if len(route) == 0:
            print(f"Vehicle {k} has no route.")
            continue
        print(f"\n--- Vehicle {k} last arc ---")
        print(f"Route: {route}")
        print(type(route))
        service_start_times = services_start_times[k].value
        print(f"Service start times: {service_start_times}")
        print(type(service_start_times))
        last_orig = route[-1] + offset
        vehicle_arrival_time_at_station_using_machine = (
            service_start_times[-1] + inst.s[last_orig] + inst.d_bar[last_orig, h, k]
        )

        arc_orig = last_orig
        arc_dest = inst.depot_end
        idx_A_m = inst.idx_A_m[arc_orig, arc_dest]

        h, index_in_h = find_h_and_index(machines, idx_A_m, inst)

        machine_travel_start_time = max(
            machine_travels_start_times[h].value[index_in_h],
            vehicle_arrival_time_at_station_using_machine,
        )

        station_orig = inst.f[arc_orig, h]
        station_dest = inst.f[arc_dest, h]
        arrival_time_from_machine = (
            machine_travel_start_time
            + inst.O_matrix[station_orig, station_dest, h]
            + inst.d_bar[arc_dest, h, k]
        )

        arrival_time_no_machine = (
            service_start_times[-1] + inst.s[arc_orig] + inst.d[arc_orig, arc_dest, k]
        )

        arrival_time_last_arc = max(arrival_time_no_machine, arrival_time_from_machine)
        print(
            f"Vehicle {k} last arc: {arc_orig} -> {arc_dest} | "
            f"arrival time no machine: {arrival_time_no_machine}, "
            f"arrival time from machine: {arrival_time_from_machine}, "
            f"arrival time last arc: {arrival_time_last_arc}"
            f"tfinal: {tfinal[k].value}, "
        )
    return None


def get_hexaly_solution(
    barlo_hx_model: BarlogonHxModel, inst: InstanceData, params: ParameterData
) -> BarloHxSolution:
    optimizer: HexalyOptimizer = barlo_hx_model.optimizer
    hxsol: HxSolution = optimizer.get_solution()
    status: type[HxSolutionStatus] = hxsol.get_status()
    is_optimal = int(status == HxSolutionStatus.OPTIMAL)
    is_tle = int(status == HxSolutionStatus.FEASIBLE)

    sol_stats: HxStatistics = optimizer.get_statistics()
    obj_expr: HxExpression = barlo_hx_model.model.get_objective(0)
    obj_val: float = hxsol.get_value(obj_expr)
    best_bound: float = hxsol.get_objective_bound(0)
    iterations: int = sol_stats.get_nb_iterations()
    solve_time: float = sol_stats.get_running_time()
    gap: float = hxsol.get_objective_gap(0) * 100

    barlo_hx_status: BarloHxStats = BarloHxStats(
        status=status,
        optimal=is_optimal,
        tle=is_tle,
        obj_value=obj_val,
        best_bound=best_bound,
        iterations=iterations,
        time=solve_time,
        gap=gap,
    )

    rtvars: BarlogonHxRoutingVars = barlo_hx_model.rtvars
    schvars: BarlogonHxSchedulingVars = barlo_hx_model.schvars

    routes = [None] * len(inst.K)
    routes_loads = [None] * len(inst.K)
    service_start_times = [None] * len(inst.K)
    tstart = [None] * len(inst.K)
    tfinal = [None] * len(inst.K)
    C = [None] * len(inst.K)

    for k in inst.K:
        route: List[HxExpression] = rtvars.routes[k].get_value()
        routes[k] = [route[i] for i in range(len(route))]
        route_loads = rtvars.routes_loads[k].get_value()
        routes_loads[k] = [route_loads[i] for i in range(len(route_loads))]

        service_start_times[k] = [
            schvars.services_start_times[k].get_value()[i] for i in range(len(route))
        ]

        tstart[k] = schvars.tstart[k].get_value()
        tfinal[k] = schvars.tfinal[k].get_value()
        C[k] = schvars.C[k].get_value()

        print(f"service_start_times[{k}]: {service_start_times[k]}")
        print(f"routes[{k}]:", routes[k])
        print(f"routes_loads[{k}]:", routes_loads[k])
        print(f"tstart[{k}]: {tstart[k]}")
        print(f"tfinal[{k}]: {tfinal[k]}")
        print(f"C[{k}]: {C[k]}")
        print()

    trajectories = [None] * len(inst.H)
    machine_travels_start_times = [None] * len(inst.H)
    for h in inst.H:
        trajectory: List[HxExpression] = rtvars.trajectories[h].get_value()
        trajectories[h] = [trajectory[i] for i in range(len(trajectory))]
        print(f"Machine {h}:")
        machine_travels_start_times[h] = []
        prev = 0
        for i in range(len(trajectory)):
            arc = trajectory[i]
            arc_orig = inst.origins_A_m[arc]
            arc_dest = inst.destinies_A_m[arc]
            print(f"\tarc ({arc_orig}, {arc_dest})")
            k, idx_orig = find_orig_k_and_index(routes, arc_orig, arc_dest, inst)
            print(f"\tk = {k} | idx_orig = {idx_orig}")
            station_orig = inst.f[arc_orig, h]
            prev_station_orig = (
                inst.f[inst.origins_A_m[trajectory[i - 1]], h]
                if i > 0
                else inst.initial_station
            )
            prev_station_dest = (
                inst.f[inst.destinies_A_m[trajectory[i - 1]], h]
                if i > 0
                else inst.initial_station
            )
            serv_st_orig = (
                service_start_times[k][idx_orig] if idx_orig != -1 else tstart[k]
            )
            print(f"\tserv_st_orig {serv_st_orig}")
            k_arr = serv_st_orig + inst.s[arc_orig] + inst.d_bar[arc_orig, h, k]
            h_arr = (
                prev
                + inst.O_matrix[prev_station_orig, prev_station_dest, h]
                + inst.O_matrix[prev_station_dest, station_orig, h]
            )
            print("\twaiting_time:")
            print(
                f"\t\tExpected: {schvars.waiting_times[arc].value} | Calculated: {max(0, k_arr-h_arr)}"
            )
            print(
                f"\t\tk_arr: {k_arr} | h_arr: {h_arr}"
            )
            prev = max(k_arr, h_arr)  # should be h_arr + waiting time
            machine_travels_start_times[h].append(prev)
            print("\n")


        machine_travels_start_times[h] = [
            schvars.machine_travels_start_times[h].get_value()[i]
            + schvars.waiting_times[trajectory[i]].get_value()
            for i in range(len(trajectory))
        ]
        print(f"trajectories[{h}]:", trajectories[h])
        print(f"machine_travels_start_times[{h}]:", machine_travels_start_times[h])
        print()

    barlo_hx_vars_solution = BarloHxVarsSolution(
        routes=routes,
        routes_loads=routes_loads,
        trajectories=trajectories,
        machine_travels_start_times=machine_travels_start_times,
        service_start_times=service_start_times,
        tstart=tstart,
        tfinal=tfinal,
        C=C,
    )

    barlo_hx_solution = BarloHxSolution(
        vars=barlo_hx_vars_solution,
        stats=barlo_hx_status,
    )

    return barlo_hx_solution


def barlogon_hexaly_formulation(
    inst: InstanceData, params: ParameterData, sol: Optional[Solution] = None
) -> None:
    barlo_hx_model: BarlogonHxModel = create_barlogon_hexaly_model(inst, params)

    barlo_hx_model.model.close()

    hxparams: HxParam = barlo_hx_model.optimizer.param
    hxparams.time_limit = int(params.hx_max_time)
    # hxparams.time_limit = 0
    hxparams.set_verbosity(1)
    hxparams.set_nb_threads(7)
    hxparams.set_seed(params.seed)

    obj_expr = barlo_hx_model.model.get_objective(0)
    solution_counter = SolutionCounterCallback(
        max_solutions=math.inf, obj_expr=obj_expr
    )

    barlo_hx_model.optimizer.add_callback(
        HxCallbackType.DISPLAY, solution_counter.callback
    )

    if sol != None:
        inject_initial_solution(sol, barlo_hx_model, inst, params)

    barlo_hx_model.optimizer.solve()

    optimizer: HexalyOptimizer = barlo_hx_model.optimizer
    hxsol: HxSolution = optimizer.get_solution()
    status: HxSolutionStatus = hxsol.get_status()
    is_optimal = status == HxSolutionStatus.OPTIMAL
    is_tle = status == HxSolutionStatus.FEASIBLE

    if is_optimal:
        print("Solution is optimal")
    elif is_tle:
        print("Time limit reached, but a feasible solution is available")
    else:
        print(f"Model failed (status {status})")
        analyze_restriction_violations(inst, params, barlo_hx_model)

        # return None

    # --- extract statistics ---
    sol_stats: HxStatistics = optimizer.get_statistics()
    obj_val: float = hxsol.get_value(obj_expr)
    best_bound: float = hxsol.get_objective_bound(0)
    iterations: int = sol_stats.get_nb_iterations()
    solve_time: float = sol_stats.get_running_time()
    gap: float = hxsol.get_objective_gap(0) * 100

    print(f"  objective value = {obj_val} | objective bound = {best_bound}")
    print(
        f"  status = {status}, iterations = {iterations}, time = {solve_time:.2f}s, gap = {gap:.2f}%"
    )

    barlo_hx_solution = get_hexaly_solution(barlo_hx_model, inst, params)
    sol = create_solution_hexaly(
        inst=inst, barlo_hx_sol=barlo_hx_solution, params=params
    )

    print_simplified_solution_from_model_variables(barlo_hx_model, inst)
    return sol


def print_simplified_solution_from_model_variables(
    barlo_hx_model: BarlogonHxModel,
    inst: InstanceData,
) -> None:
    obj_expr = barlo_hx_model.model.get_objective(0)
    optimizer: HexalyOptimizer = barlo_hx_model.optimizer
    hxsol: HxSolution = optimizer.get_solution()
    obj_val = hxsol.get_value(obj_expr)

    rtvars = barlo_hx_model.rtvars
    schvars = barlo_hx_model.schvars
    routes = rtvars.routes
    trajectories = rtvars.trajectories

    tstart = schvars.tstart
    tfinal = schvars.tfinal
    services_start_times = schvars.services_start_times
    machine_travels_start_times = schvars.machine_travels_start_times
    waiting_times = schvars.waiting_times
    C = schvars.C
    offset: int = 1

    for h in inst.H:
        trajectory = trajectories[h].value
        if len(trajectory) == 0:
            print(f"Machine {h} has no trajectory.")
            continue
        print(f"Machine {h} trajectory: {trajectory}")
        machine_travel_start_times = machine_travels_start_times[h].value
        print(f"Machine {h} travel start times: {machine_travel_start_times}")
        for arc in trajectory:
            print(f"waiting time: {waiting_times[arc].value}")

    print()
    for k in inst.K:
        route = routes[k].value
        if len(route) == 0:
            print(f"Vehicle {k} has no route.")
            continue
        print(f"Vehicle {k} route: {route}")
        print(f"Vehicle {k} service start times: {services_start_times[k].value}")

    for k in inst.K:
        if len(routes[k].value) > 0:
            service_start_times = services_start_times[k].value
            print(service_start_times)
            print(f"Vehicle {k} :")
            route = routes[k].value
            job: Job = inst.jobs[inst.refs[inst.depot_begin]]
            print_node_details(inst.depot_begin, job, tstart[k].value, inst)

            first_node = route[0] + offset
            print()
            print(
                f"\tDistance from {inst.depot_begin} to {first_node}: {inst.d[inst.depot_begin, first_node, k]}"
            )
            if inst.diff_region[inst.depot_begin][first_node]:
                print("\tUsing machine")
            print()

            for i in range(len(route)):
                node = route[i] + offset
                job: Job = inst.jobs[inst.refs[node]]
                print_node_details(node, job, service_start_times[i], inst)
                if i < len(route) - 1:
                    next_node = route[i + 1] + offset
                    print()
                    print(
                        f"\tDistance from {node} to {next_node}: {inst.d[node, next_node, k]}"
                    )
                    if inst.diff_region[node][next_node]:
                        print("\tUsing machine")
                    print()

            last_node = route[len(route) - 1] + offset
            print()
            print(
                f"\tDistance from {last_node} to {inst.depot_end}: {inst.d[last_node, inst.depot_end, k]}"
            )
            if inst.diff_region[last_node][inst.depot_end]:
                print("\tUsing machine")
            print()
            job: Job = inst.jobs[inst.refs[inst.depot_end]]
            print_node_details(inst.depot_end, job, tfinal[k].value, inst)
            print(f"\tCompletion time: {C[k].value}")
            print()

    print(f"Completion time: {obj_val}")

    print()
    for h in inst.H:
        trajectory = trajectories[h].value
        if len(trajectory) == 0:
            continue
        print(f"Trajectory for machine {h}: {trajectory}")
        machine_travel_start_times = machine_travels_start_times[h].value
        if len(trajectory) > 0:
            print(f"Machine {h}")
            for i in range(len(trajectory)):
                arc_id = trajectory[i]
                mtrv_st = machine_travel_start_times[i]

                i = inst.origins_A_m[arc_id]
                j = inst.destinies_A_m[arc_id]

                print(f"({i}, {j}): {mtrv_st}", end=" ")
            print()
