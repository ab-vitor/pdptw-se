import os
import random

import numpy as np
from .entities import ParameterData
from .load_general_configuration import load_general_configuration

"""
    def parse_constraints_used_mip(params: ParameterData) -> None:
    
    Parse constraints_used_mip_str into a list of bools indicating which constraints are used in the MIP model.
    The input string can contain individual indices or ranges (e.g., "1,2,5-7").
"""
def parse_constraints_used_mip(params: ParameterData) -> None:
    constraints_used_mip_int = []
    if params.constraints_used_mip_str:
        parts = params.constraints_used_mip_str.split(",")
        for part in parts:
            if "-" in part:
                start, end = map(int, part.split("-"))
                constraints_used_mip_int.extend(range(start, end + 1))
            else:
                constraints_used_mip_int.append(int(part))
    max_index = 100 # probably this will never be insufficient
    params.constraints_used_mip = np.zeros(max_index + 1, dtype=bool)
    for c in constraints_used_mip_int:
        if c <= max_index:
            params.constraints_used_mip[c] = True

    return None

def save_instance_full_name(params: ParameterData) -> None:
    path_splitted = os.path.normpath(params.inst_path).split(os.sep)
    params.name = path_splitted[-1]
    params.type = path_splitted[-2]
    params.group = path_splitted[-3]

    if params.cut_off_machs <= 0:
        params.cut_off_machs = int(params.group[-3:-1])

    params.group = f"{params.group[:-3]}{params.cut_off_machs:02d}M"
    params.full_name = f"{params.name}_{params.type}_{params.group}"

    print(f"Instance: {params.full_name}")


def read_input_parameters(args: list[str]) -> ParameterData:
    params = ParameterData()

    i = 1
    while i < len(args):
        if args[i] == "--inst_path":
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
        elif args[i] == "--epsilon":
            params.epsilon = float(args[i + 1])
            i += 1
        elif args[i] == "--output":
            params.output = args[i + 1]
            i += 1
        elif args[i] == "--seed":
            params.seed = int(args[i + 1])
            i += 1
        elif args[i] == "--output_flag_grb_mip":
            params.output_flag_grb_mip = int(args[i + 1])
            i += 1
        elif args[i] == "--mip_grb_max_time":
            params.mip_grb_max_time = int(args[i + 1])
            i += 1
        elif args[i] == "--mip_hx_max_time":
            params.mip_hx_max_time = int(args[i + 1])
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
        elif args[i] == "--constraints_used_mip_str":
            params.constraints_used_mip_str = args[i + 1]
            i += 1
        elif args[i] == "--run_callback_mip_gurobi":
            params.run_callback_mip_gurobi = True
            i += 1
        elif args[i] == "--mip_grb_heuristics":
            params.mip_grb_heuristics = float(args[i + 1])
            i += 1
        elif args[i] == "--threads":
            params.threads = int(args[i + 1])
            i += 1
        # Add other parameters as needed
        elif args[i].startswith("--"):
            raise ValueError(f"Parameter {args[i]} does not exist")
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
    parse_constraints_used_mip(params)
    print("Constraints active in MIP")
    for i in range(1,50):
        if params.constraints_used_mip[i]:
            print(f"{i}", end=" ")
            
    print()
    return params