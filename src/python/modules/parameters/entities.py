import os
import random
from dataclasses import dataclass, field

import numpy as np

@dataclass
class ParameterData:
    inst_path: str = (
        "../../instances/multi_island/orig_ams_fg/06R_06V_02I_04M/t2/lr202/"
    )
    name: str = ""
    type: str = ""
    group: str = ""
    full_name: str = ""
    method_type: str = "form"
    method_code: str = "mip_grb"
    gen_config_file_path: str = "configs/mip_grb/genconfig_mip_grb.conf"
    gen_config_file_name: str = field(init=False)
    cut_off: int = 0
    cut_off_machs: int = 0
    solver: str = "Gurobi"
    max_time: int = 7200
    gurobi_cuts: int = 1
    type_user_cut: int = 0
    mip_presolve: int = -1
    print_sol: int = 0
    max_nodes: int = -1
    elevator: int = 0
    make_instance_feasible: bool = False
    output: str = "./logs/"
    epsilon: float = 0.005
    epsilon_cap: float = 0.5
    seed: int = 0
    rng: random.Random = field(init=False)
    output_flag_grb_mip: int = 0
    mip_max_time: int = 3600
    hx_max_time: int = 3600
    csv_file_name: str = ""
    sol_file_name: str = ""
    timeline_file_name: str = ""
    grb_file_name: str = ""
    validate_synchronization: bool = True
    constraints_used_mip_str: str = "1-100"
    constraints_used_mip: np.ndarray = None
    run_callback_mip_gurobi: bool = False
    mip_heuristics: float = 0.05 # default is 0.05 (according to Gurobi docs)
    threads: int = 16

    def __post_init__(self):
        self.gen_config_file_name = os.path.basename(self.gen_config_file_path)[:-5]
        self.rng = random.Random(self.seed)
