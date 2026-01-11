import time

from .entities_mslp import ExternalMSLPData

def update_current_results(extmd: ExternalMSLPData, _) -> None:
    extmd.time_to_best = time.time() - extmd.start_time
    extmd.iteration_to_best = extmd.iteration
    extmd.best_sol = extmd.curr_sol
    update_offset = extmd.iteration - extmd.iteration_to_best
    extmd.largest_update_offset = max(extmd.largest_update_offset, update_offset)

    print(
        f"{extmd.best_sol.value:.2f};"
        f"{extmd.curr_sol.value:.2f};"
        f"{extmd.iteration};"
        f"{extmd.time_to_best:.6f}"
    )
