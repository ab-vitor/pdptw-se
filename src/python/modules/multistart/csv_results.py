from dataclasses import asdict, is_dataclass
import pandas as pd

from modules.data import InstanceData
from modules.csv_utils import struct_to_key_dict

from .entities_mslp import AllParams, ExternalMSLPData

def get_csv_results(inst: InstanceData, extmd: ExternalMSLPData, all_params: AllParams) -> pd.DataFrame:
    gp = all_params.general
    best_sol = extmd.best_sol
    stats = best_sol.stats

    exclude_fields_gp = {
        "maxtime", "printsol", "maxnodes"
    }

    exclude_fields_extmd = {
        "start_time", "env", "best_sol", "curr_sol", "last_semi_greedy_sol"
    }

    exclude_fields_i = {
        "vehicles", "vehicle_types", "jobs", "machines", "refs", "V", "V_p",
        "V_d", "V_p_d", "Vprime", "q", "K", "Q", "d", "dmax_vehicle",
        "dmin_vehicle", "A", "A_m", "A_s", "H", "H_e", "d_bar", "f", "O", "s",
        "M", "L_K", "L_H", "F_h", "S_h", "Sprime_h"
    }

    exclude_fields_stats = {
        "machines_travel_times_with_vehicle",
        "machines_travel_times_no_vehicle",
        "max_load_vehicle"
    }

    exclude_fields_sol = {
        "vehicles", "machines", "completion_times", "stats"
    }

    result_data = {}
    result_data.update(struct_to_key_dict(inst, exclude_fields_i))
    result_data.update(struct_to_key_dict(extmd, exclude_fields_extmd))
    result_data.update(struct_to_key_dict(gp, exclude_fields_gp))
    result_data.update(struct_to_key_dict(stats, exclude_fields_stats))
    result_data.update(struct_to_key_dict(best_sol, exclude_fields_sol))

    df = pd.DataFrame([result_data])

    # Round float columns (except maybe excluded column like 'best_cost')
    for col in df.columns:
        if pd.api.types.is_float_dtype(df[col]):
            df[col] = df[col].round(2)

    return df
