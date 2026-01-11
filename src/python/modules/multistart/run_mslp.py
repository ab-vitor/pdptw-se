import time
from datetime import datetime
from modules.formulations import run_lp_form_to_reschedule_sol
from .improvement import update_current_results
from .entities_mslp import AllParams, ExternalMSLPData
from .greedy_based_heuristics.greedy_heuristic import greedy_heuristic
from .greedy_based_heuristics.semi_greedy_heuristic import semi_greedy_heuristic


def continue_running_mslp(extmd: ExternalMSLPData, all_params: AllParams) -> bool:
    current_time_elapsed = time.time() - extmd.start_time

    stop = all_params.stop
    rule = stop.rule

    return not (
        current_time_elapsed >= stop.maximum_time
        or (rule == "ITERATIONS" and extmd.iteration >= stop.argument)
        or (rule == "FEASIBILITY" and extmd.best_sol.is_feasible)
        or (rule == "MAXTIME" and current_time_elapsed >= stop.argument)
        or (
            rule == "TARGET"
            and extmd.best_sol.value <= stop.argument + all_params.general.epsilon
        )
    )


def run_mslp(inst, extmd: ExternalMSLPData, all_params: AllParams) -> None:
    print("objValue;greedysol;iteration;time")

    extmd.curr_sol = greedy_heuristic(inst, all_params.general)

    if extmd.curr_sol.is_feasible:
        extmd.last_semi_greedy_sol = extmd.curr_sol
        extmd.best_sol = run_lp_form_to_reschedule_sol(
            extmd.env, extmd.curr_sol, inst, all_params.general
        )
        extmd.lp_runs += 1

        if (
            extmd.best_sol.is_feasible
            and extmd.best_sol.value < extmd.last_semi_greedy_sol.value
        ):
            extmd.lp_impr += 1
            extmd.sum_lp_impr_percentage += round(
                (extmd.last_semi_greedy_sol.value - extmd.best_sol.value)
                / extmd.last_semi_greedy_sol.value,
                4,
            )

        if extmd.best_sol.is_feasible:
            update_current_results(all_params)
        else:
            extmd.best_sol.value = float("inf")
    else:
        extmd.infeasible_sol += 1
        extmd.curr_sol.value = float("inf")
        # print("/!\\ First greedy heuristic solution was not feasible...")

    while continue_running_mslp(extmd, all_params):
        extmd.iteration += 1
        extmd.curr_sol = semi_greedy_heuristic(inst, all_params.general)

        if extmd.curr_sol.is_feasible:
            extmd.last_semi_greedy_sol = extmd.curr_sol
            extmd.curr_sol = run_lp_form_to_reschedule_sol(
                extmd.env, extmd.curr_sol, inst, all_params.general
            )
            extmd.lp_runs += 1

            if extmd.curr_sol.value < extmd.last_semi_greedy_sol.value:
                extmd.lp_impr += 1
                extmd.sum_lp_impr_percentage += round(
                    (extmd.last_semi_greedy_sol.value - extmd.curr_sol.value)
                    / extmd.last_semi_greedy_sol.value,
                    4,
                )

        if extmd.curr_sol.is_feasible and (
            extmd.curr_sol.value + all_params.general.epsilon < extmd.best_sol.value
        ):
            update_current_results(all_params)

    extmd.total_time_elapsed = time.time() - extmd.start_time
    print(f"\n[{datetime.now().time()}] Finished running MSLP")
