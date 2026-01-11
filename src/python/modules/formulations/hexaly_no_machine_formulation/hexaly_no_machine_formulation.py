import math
from hexaly.optimizer import (
    HexalyOptimizer,
    HxParam,
    HxSolution,
    HxSolutionStatus,
    HxStatistics,
    HxCallbackType,
)

from modules.parameters import ParameterData
from modules.data import InstanceData
from .create_hexaly_no_machine_model import create_melo_hexaly_model
from .entities_hexaly_no_machine_formulation import MeloHxModel


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


def hexaly_no_machine_formulation(inst: InstanceData, params: ParameterData) -> None:

    melo_hx_model: MeloHxModel = create_melo_hexaly_model(inst, params)

    melo_hx_model.model.close()

    hxparams: HxParam = melo_hx_model.optimizer.param
    hxparams.time_limit = int(params.mip_max_time)
    hxparams.set_verbosity(1)
    hxparams.set_nb_threads(4)

    obj_expr = melo_hx_model.model.get_objective(0)
    solution_counter = SolutionCounterCallback(
        max_solutions=math.inf, obj_expr=obj_expr
    )

    melo_hx_model.optimizer.add_callback(
        HxCallbackType.DISPLAY, solution_counter.callback
    )

    melo_hx_model.optimizer.solve()

    optimizer: HexalyOptimizer = melo_hx_model.optimizer
    hxsol: HxSolution = optimizer.get_solution()
    status: HxSolutionStatus = hxsol.get_status()
    is_optimal = status == HxSolutionStatus.OPTIMAL
    is_tle = status == HxSolutionStatus.FEASIBLE

    if is_optimal:
        print("Solution is optimal")
    elif is_tle:
        print("Time limit reached, but a feasible solution is available")
    else:
        print(f"Model failed (status {status}), writing partial results to CSV")
        return None

    # --- extract statistics ---
    sol_stats: HxStatistics = optimizer.get_statistics()
    obj_val = hxsol.get_value(obj_expr)
    best_bound = hxsol.get_objective_bound(0)
    iterations = sol_stats.get_nb_iterations()
    solve_time = sol_stats.get_running_time()
    gap = hxsol.get_objective_gap(0) * 100

    print(f"  objective value = {obj_val} | objective bound = {best_bound}")
    print(
        f"  status = {status}, iterations = {iterations}, time = {solve_time:.2f}s, gap = {gap:.2f}%"
    )

    rtvars = melo_hx_model.rtvars
    schvars = melo_hx_model.schvars
    routes = rtvars.routes
    vehicles_used = rtvars.vehicles_used
    tstart = schvars.tstart
    tfinal = schvars.tfinal
    # depot_lateness = schvars.depot_lateness
    # lateness = schvars.lateness
    service_start_time = schvars.service_start_time
    C = schvars.C
    offset = 1

    for k in inst.K:
        if vehicles_used[k].value:
            print(f"Vehicle {k} :")
            route = routes[k].value
            servST = service_start_time[k].value
            print(f"\t node: {inst.depot_begin}")
            print(f"\t\t earl: {inst.e[inst.depot_begin]}")
            print(f"\t\t lat: {inst.l[inst.depot_begin]}")
            print(f"\t\t servt: {inst.s[inst.depot_begin]}")
            print(f"\t\t servST: {tstart[k].value}")
            first_node = route[0] + offset
            print(
                f"\tDistance from {inst.depot_begin} to {first_node}: {inst.d[inst.depot_begin, first_node, k]}"
            )
            for i in range(len(route)):
                node = route[i] + offset
                print(f"\t node: {node}")
                print(f"\t\t earl: {inst.e[node]}")
                print(f"\t\t lat: {inst.l[node]}")
                print(f"\t\t servt: {inst.s[node]}")
                print(f"\t\t servST: {servST[i]}")
                if i < len(route) - 1:
                    next_node = route[i + 1] + offset
                    print(
                        f"\tDistance from {node} to {next_node}: {inst.d[node, next_node, k]}"
                    )

            last_node = route[len(route) - 1] + offset
            print(
                f"\tDistance from {last_node} to {inst.depot_end}: {inst.d[last_node, inst.depot_end, k]}"
            )
            print(f"\t node: {inst.depot_end}")
            print(f"\t\t earl: {inst.e[inst.depot_end]}")
            print(f"\t\t lat: {inst.l[inst.depot_end]}")
            print(f"\t\t servt: {inst.s[inst.depot_end]}")
            print(f"\t\t servST: {tfinal[k].value}")

        print(f"\tCompletion time: {C[k].value}")
        print()
    
    print(f"Completion time: {obj_val}")

    return None
