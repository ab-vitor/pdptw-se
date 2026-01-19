import os
import random

import numpy as np
from .entities import ParameterData
from .load_general_configuration import load_general_configuration


def parse_constraints_used_melo_mip(params: ParameterData) -> None:
    # Parse constraints_used_melo_mip_str into a list of ints
    constraints_used_melo_mip_int = []
    if params.constraints_used_melo_mip_str:
        parts = params.constraints_used_melo_mip_str.split(",")
        for part in parts:
            if "-" in part:
                start, end = map(int, part.split("-"))
                constraints_used_melo_mip_int.extend(range(start, end + 1))
            else:
                constraints_used_melo_mip_int.append(int(part))
    max_index = 100 # probably this will never happen
    params.constraints_used_melo_mip = np.zeros(max_index + 1, dtype=bool)
    for c in constraints_used_melo_mip_int:
        if c <= max_index:
            params.constraints_used_melo_mip[c] = True

    return None

def save_instance_full_name(params: ParameterData) -> None:
    path_splitted = os.path.normpath(params.inst_path).split(os.sep)
    params.name = path_splitted[-1]

    if path_splitted[-2][0] == "t":
        params.type = path_splitted[-2]
        params.group = path_splitted[-3]
    else:
        params.type = f"t{params.name[2]}"
        params.group = path_splitted[-2]

    if params.cut_off_machs <= 0:
        params.cut_off_machs = int(params.group[-3:-1])

    params.group = f"{params.group[:-3]}{params.cut_off_machs:02d}M"
    params.full_name = f"{params.name}_{params.type}_{params.group}"

    print(f"Instance: {params.full_name}")


def read_input_parameters(args: list[str]) -> ParameterData:
    params = ParameterData()

    i = 0
    while i < len(args):
        if args[i] == "--inst":
            params.inst_path = args[i + 1]
            i += 1
        elif args[i] == "--gen_config_file_path":
            params.gen_config_file_path = args[i + 1]
            params.gen_config_file_name = os.path.basename(params.gen_config_file_path)[:-5]
            load_general_configuration(params.gen_config_file_path, params)
            i += 1
        elif args[i] == "--solver":
            params.solver = args[i + 1]
            i += 1
        elif args[i] == "--max_time":
            params.max_time = int(args[i + 1])
            i += 1
        elif args[i] == "--print_sol":
            params.print_sol = int(args[i + 1])
            i += 1
        elif args[i] == "--method_type":
            params.method_type = args[i + 1]
            i += 1
        elif args[i] == "--method_code":
            params.method_code = args[i + 1]
            i += 1
        elif args[i] == "--greedy_service_order":
            params.greedy_service_order = args[i + 1]
            i += 1
        elif args[i] == "--cut_off":
            params.cut_off = int(args[i + 1])
            i += 1
        elif args[i] == "--cut_off_machs":
            params.cut_off_machs = int(args[i + 1])
            i += 1
        elif args[i] == "--elevator":
            params.elevator = 1
        elif args[i] == "--max_nodes":
            params.max_nodes = int(args[i + 1])
            i += 1
        elif args[i] == "--make_instance_feasible":
            params.make_instance_feasible = True
        elif args[i] == "--epsilon":
            params.epsilon = float(args[i + 1])
            i += 1
        elif args[i] == "--warm_start":
            params.warm_start = True
        elif args[i] == "--output":
            params.output = args[i + 1]
            i += 1
        elif args[i] == "--seed":
            params.seed = int(args[i + 1])
            i += 1
        elif args[i] == "--alpha":
            params.alpha = float(args[i + 1])
            i += 1
        elif args[i] == "--max_iter":
            params.max_iter = int(args[i + 1])
            i += 1
        elif args[i] == "--output_flag_grb_mip":
            params.output_flag_grb_mip = int(args[i + 1])
            i += 1
        elif args[i] == "--output_flag_grb_mslp":
            params.output_flag_grb_mslp = int(args[i + 1])
            i += 1
        elif args[i] == "--output_flag_grb_lmns":
            params.output_flag_grb_lmns = int(args[i + 1])
            i += 1
        elif args[i] == "--mslp_r":
            params.mslp_r = args[i + 1]
            i += 1
        elif args[i] == "--mslp_a":
            params.mslp_a = args[i + 1]
            i += 1
        elif args[i] == "--lmns_r":
            params.lmns_r = args[i + 1]
            i += 1
        elif args[i] == "--lmns_a":
            params.lmns_a = args[i + 1]
            i += 1
        elif args[i] == "--lmns_repair_time":
            params.lmns_repair_time = float(args[i + 1])
            i += 1
        elif args[i] == "--lmns_mip_focus":
            params.lmns_mip_focus = int(args[i + 1])
            i += 1
        elif args[i] == "--lmns_gap_to_bigger_destruction":
            params.lmns_gap_to_bigger_destruction = int(args[i + 1])
            i += 1
        elif args[i] == "--lmns_gap_to_smaller_destruction":
            params.lmns_gap_to_smaller_destruction = int(args[i + 1])
            i += 1
        elif args[i] == "--lmns_weight_shaw_dist_prox":
            params.lmns_weight_shaw_dist_prox = float(args[i + 1])
            i += 1
        elif args[i] == "--lmns_weight_shaw_earl_prox":
            params.lmns_weight_shaw_earl_prox = float(args[i + 1])
            i += 1
        elif args[i] == "--lmns_weight_shaw_same_route":
            params.lmns_weight_shaw_same_route = float(args[i + 1])
            i += 1
        elif args[i] == "--lmns_weight_shaw_demand_sim":
            params.lmns_weight_shaw_demand_sim = float(args[i + 1])
            i += 1
        elif args[i] == "--lmns_req_r_apply_mip_start":
            params.lmns_req_r_apply_mip_start = True
        elif args[i] == "--lmns_acceptance_criteria":
            params.lmns_acceptance_criteria = args[i + 1]
            i += 1
        elif args[i] == "--lmns_metropolis_temp":
            params.lmns_metropolis_temp = float(args[i + 1])
            i += 1
        elif args[i] == "--lmns_simulated_annealing_temp":
            params.lmns_simulated_annealing_temp = float(args[i + 1])
            i += 1
        elif args[i] == "--lmns_simulated_annealing_cool":
            params.lmns_simulated_annealing_cool = float(args[i + 1])
            i += 1
        elif args[i] == "--mip_max_time":
            params.mip_max_time = int(args[i + 1])
            i += 1
        elif args[i] == "--hx_max_time":
            params.hx_max_time = int(args[i + 1])
            i += 1
        elif args[i] == "--csv_file_name":
            params.csv_file_name = args[i + 1]
            i += 1
        elif args[i] == "--sol_file_name":
            params.sol_file_name = args[i + 1]
            i += 1
        elif args[i] == "--timeline_file_name":
            params.timeline_file_name = args[i + 1]
            i += 1
        elif args[i] == "--grb_file_name":
            params.grb_file_name = args[i + 1]
            i += 1
        elif args[i] == "--validate_synchronization":
            params.validate_synchronization = True
        elif args[i] == "--constraints_used_melo_mip_str":
            params.constraints_used_melo_mip_str = args[i + 1]
            i += 1
        elif args[i] == "--run_callback_melo_mip":
            params.run_callback_melo_mip = True
            i += 1
        elif args[i] == "--mip_heuristics":
            params.mip_heuristics = float(args[i + 1])
            i += 1
        elif args[i] == "--threads":
            params.threads = int(args[i + 1])
            i += 1
        # Add other parameters as needed
        i += 1

    if not params.inst_path.endswith("/"):
        params.inst_path += "/"

    params.gen_config_file_name = os.path.basename(params.gen_config_file_path)[:-5]
    params.rng = random.Random(params.seed)
    save_instance_full_name(params)
    print(params)
    if not params.output.endswith("/"):
        params.output += "/"
    params.csv_file_name = f"{params.output}{params.method_type}_{params.method_code}/outputs/csvresults_{params.method_type}_{params.method_code}.csv"
    params.sol_file_name = f"{params.output}{params.method_type}_{params.method_code}/solutions/{params.group}/{params.name}_sol_{params.gen_config_file_name}.txt"
    params.timeline_file_name = f"{params.output}{params.method_type}_{params.method_code}/timelines/{params.group}/{params.name}_timeline_{params.gen_config_file_name}.txt"
    params.grb_file_name = f"{params.output}{params.method_type}_{params.method_code}/gurobi/{params.group}/{params.name}_grb_{params.gen_config_file_name}.log"
    parse_constraints_used_melo_mip(params)
    print("Constraints active in melo MIP")
    for i in range(1,50):
        if params.constraints_used_melo_mip[i]:
            print(f"{i}", end=" ")
    return params