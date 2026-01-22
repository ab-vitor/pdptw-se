from typing import Optional
import pandas as pd

from modules.parameters import ParameterData
from modules.data import InstanceData
from modules.solutions import Solution, MIPGrbStats, SolutionStats
from modules.csv_utils import struct_to_key_dict, parse_field

from .entities import MIPGrbModelStats


def get_csv_results(
    inst: InstanceData,
    params: ParameterData,
    mip_model_stats: MIPGrbModelStats,
    sol: Optional[Solution] = None,
    mip_sol_stats: Optional[MIPGrbStats] = None,
) -> pd.DataFrame:

    exclude_fields_i = {
        "vehicles",
        "vehicle_types",
        "jobs",
        "machines",
        "refs",
        "V",
        "V_p",
        "V_d",
        "V_p_d",
        "Vprime",
        "diff_region",
        "q",
        "max_q",
        "K",
        "Q",
        "d",
        "dmax_vehicle",
        "dmin_vehicle",
        "max_d",
        "d_bar",
        "d_bar_min",
        "d_bar_max",
        "e",
        "l",
        "eprime",
        "lprime",
        "A",
        "A_m",
        "A_s",
        "in_A",
        "in_A_m",
        "in_A_s",
        "feas_gamma",
        "idx_A_m",
        "origins_A_m",
        "destinies_A_m",
        "H",
        "H_e",
        "H_eprime",
        "f",
        "O",
        "O_matrix",
        "s",
        "max_s",
        "depot_begin",
        "depot_end",
        "initial_station",
        "first_pickup",
        "last_pickup",
        "first_delivery",
        "last_delivery",
        "ppd",
    }

    exclude_fields_params = {"constraints_used_mip_gurobi", "rng"}

    exclude_fields_stats = {
        "machines_travel_times_with_vehicle",
        "machines_travel_times_no_vehicle",
        "max_load_vehicle",
    }

    exclude_fileds_mip_stats = {"cuts"}


    result_data = {}
    result_data.update(struct_to_key_dict(inst, exclude_fields_i))
    result_data.update(struct_to_key_dict(params, exclude_fields_params))

    if mip_sol_stats is not None:
        result_data.update(struct_to_key_dict(mip_sol_stats))
    else:
        result_data.update({key: parse_field(value) for key, value in vars(MIPGrbStats()).items()})

    result_data.update(
        struct_to_key_dict(mip_model_stats, exclude_fileds_mip_stats)
    )
    cuts = mip_model_stats.cuts
    result_data.update(cuts)

    if sol is not None:
        result_data.update(struct_to_key_dict(sol.stats, exclude_fields_stats))
    else:
        result_data.update({key: parse_field(value) for key, value in vars(SolutionStats()).items() if key not in exclude_fields_stats})


    df = pd.DataFrame([result_data])

    # Round float columns
    for col in df.columns:
        if pd.api.types.is_float_dtype(df[col]):
            df[col] = df[col].round(6)

    return df
