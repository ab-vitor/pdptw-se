from datetime import datetime

from modules.data import InstanceData
from modules.solutions.statistics import save_stats_solution
from modules.enumerations.stop_rule import StopRule
from modules.csv_utils import write_csv_with_flock
from modules.solutions import save_solution_timeline, save_solution_to_file

from .csv_results import get_csv_results
from .statistics import calculate_stats, print_stats
from .entities_mslp import AllParams, ExternalMSLPData


def post_running_mslp(
    inst: InstanceData, extmd: ExternalMSLPData, all_params: AllParams
) -> None:
    calculate_stats(extmd)
    print_stats(extmd)

    # Save stats for the best solution
    stats_solution = save_stats_solution(inst, extmd.best_sol, all_params.general)
    extmd.best_sol.stats = stats_solution

    if all_params.stop.rule != StopRule.TARGET:
        print(
            f"[{datetime.now().time().strftime('%H:%M:%S')}] Writing results to CSV file: {all_params.general.csv_file_name}"
        )

        csv_row = get_csv_results(inst, extmd, all_params)

        # Write to CSV with file locking (needs implementation or placeholder)
        write_csv_with_flock(all_params.general.csv_file_name, csv_row)

        # Save the best solution and its timeline
        save_solution_to_file(extmd.best_sol, inst, all_params.general)
        save_solution_timeline(extmd.best_sol, inst, all_params.general)
