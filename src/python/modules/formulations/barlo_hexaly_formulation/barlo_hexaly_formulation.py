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
from .create_barlo_hexaly_model import create_barlo_hexaly_model
from .entities_barlo_hexaly_formulation import (
    BarloHxModel,
    BarloHxRoutingVars,
    BarloHxSchedulingVars,
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
    barlo_hx_model: BarloHxModel,
    inst: InstanceData,
    params: ParameterData,
) -> None:
    rtvars = barlo_hx_model.rtvars
    schvars = barlo_hx_model.schvars
    routes: List[HxExpression] = rtvars.routes
    trajectories: List[HxExpression] = rtvars.trajectories
    tstart: List[HxExpression] = schvars.tstart
    tfinal: List[HxExpression] = schvars.tfinal
    t: List[HxExpression] = schvars.t
    alpha: List[HxExpression] = schvars.alpha
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
            t[stop.node-offset].value = stop.servST
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
        print(f"Machine {h}:", end=" ")
        for i in range(len(mach)):
            mtrv: MachineTravel = mach[i]
            orig, dest = mtrv.orig, mtrv.dest
            idx_A_m = inst.idx_A_m[orig, dest]
            print(f"({orig}, {dest}): {idx_A_m} {inst.A_m[idx_A_m]}", end=" ")
            values_traj.add(idx_A_m)
            alpha[idx_A_m].value = mtrv.st
        print()
        print(values_traj)


def analyze_restriction_violations(
    inst: InstanceData, params: ParameterData, barlo_hx_model: BarloHxModel
) -> None:
    rtvars = barlo_hx_model.rtvars
    schvars = barlo_hx_model.schvars
    t = schvars.t

    routes = rtvars.routes
    vehicles_used = rtvars.vehicles_used
    trajectories = rtvars.trajectories
    offset = 1

    for k in inst.K:
        route = routes[k].value
        print(route)

    for h in inst.H:
        trajectory = trajectories[h].value
        print(trajectory)


    for k in inst.K:
        route = routes[k].value
        c = len(route)  # number of customers in route k

        print(f"\n--- Vehicle {k}, route length = {c} ---")
        for i in range(c):
            print(f"time: {t[route[i]].get_value()}")

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
    return None


def get_hexaly_solution(
    barlo_hx_model: BarloHxModel, inst: InstanceData, params: ParameterData
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

    rtvars: BarloHxRoutingVars = barlo_hx_model.rtvars
    schvars: BarloHxSchedulingVars = barlo_hx_model.schvars

    routes = [None] * len(inst.K)
    routes_loads = [None] * len(inst.K)
    times = [None] * len(inst.K)
    service_start_times = [None] * len(inst.K)
    tstart = [None] * len(inst.K)
    tfinal = [None] * len(inst.K)
    C = [None] * len(inst.K)

    for k in inst.K:
        route: List[HxExpression] = rtvars.routes[k].get_value()
        routes[k] = [route[i] for i in range(len(route))]
        route_loads = rtvars.routes_loads[k].get_value()
        routes_loads[k] = [route_loads[i] for i in range(len(route_loads))]

        if not schvars.service_start_times[k] == None:
            service_start_times[k] = [
                schvars.service_start_times[k].get_value()[i]
                for i in range(len(route))
            ]
        times[k] = [
            schvars.t[route[i]].get_value() for i in range(len(route))
        ]

        tstart[k] = schvars.tstart[k].get_value()
        tfinal[k] = schvars.tfinal[k].get_value()
        C[k] = schvars.C[k].get_value()

        print(f"times[{k}]: {times[k]}")
        print(f"service_start_times[{k}]: {service_start_times[k]}")
        print(f"routes[{k}]:", routes[k])
        print(f"routes_loads[{k}]:", routes_loads[k])
        print(f"tstart[{k}]: {tstart[k]}")
        print(f"tfinal[{k}]: {tfinal[k]}")
        print(f"C[{k}]: {C[k]}")
        print()

    trajectories = [None] * len(inst.H)
    alphas = [None] * len(inst.H)
    machine_travels_start_times = [None] * len(inst.H)
    for h in inst.H:
        trajectory: List[HxExpression] = rtvars.trajectories[h].get_value()
        trajectories[h] = [trajectory[i] for i in range(len(trajectory))]
        alphas[h] = [
            schvars.alpha[trajectory[i]].get_value()
            for i in range(len(trajectory))
        ]
        if not schvars.machine_travels_start_times[h] == None:
            machine_travels_start_times[h] = [
                schvars.machine_travels_start_times[h].get_value()[i]
                for i in range(len(trajectory))
            ]
        print(f"trajectories[{h}]:", trajectories[h])
        print(f"alphas[{h}]:", alphas[h])
        print(f"machine_travels_start_times[{h}]:", machine_travels_start_times[h])
        print()

    if params.validate_synchronization:
        barlo_hx_vars_solution = BarloHxVarsSolution(
            routes=routes,
            routes_loads=routes_loads,
            trajectories=trajectories,
            machine_travels_start_times=alphas,
            service_start_times=times,
            tstart=tstart,
            tfinal=tfinal,
            C=C,
        )
    else:
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


def barlo_hexaly_formulation(
    inst: InstanceData, params: ParameterData, sol: Optional[Solution] = None
) -> None:
    barlo_hx_model: BarloHxModel = create_barlo_hexaly_model(inst, params)

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
        # analyze_restriction_violations(inst, params, barlo_hx_model)

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
    barlo_hx_model: BarloHxModel,
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
    alpha: List[HxExpression] = (
        schvars.alpha
    )
    t = schvars.t
    C = schvars.C
    offset: int = 1

    for k in inst.K:
        if len(routes[k].value) > 0:
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
                print_node_details(node, job, t[route[i]], inst)
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
        if len(trajectory) > 0:
            print(f"Machine {h}")
            for i in range(len(trajectory)):
                arc_id = trajectory[i]
                mtrv_st = alpha[trajectory[i]]

                i = inst.origins_A_m[arc_id]
                j = inst.destinies_A_m[arc_id]

                print(f"({i}, {j}): {mtrv_st}", end=" ")
            print()
