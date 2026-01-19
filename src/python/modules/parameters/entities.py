import os
import random
from dataclasses import dataclass, field

import numpy as np

@dataclass
class ParameterData:
    inst_path: str = (
        "../../benchmark_multi_island_v5/instances/orig_ams_fg/12R_12V_04I_04M/t2/lr202/"
    )
    name: str = ""
    type: str = ""
    group: str = ""
    full_name: str = ""
    method_type: str = "heur"
    method_code: str = "mslp"
    gen_config_file_path: str = "configs/mslp/genconfig_mslp.conf"
    gen_config_file_name: str = field(init=False)
    greedy_service_order: str = "tightest_tw"
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
    warm_start: bool = False
    seed: int = 0
    rng: random.Random = field(init=False)
    alpha: float = 0.2
    max_iter: int = int(1e6)
    output_flag_grb_mip: int = 0
    output_flag_grb_mslp: int = 0
    output_flag_grb_lmns: int = 0
    mslp_r: str = "M"
    mslp_a: str = "60"
    lmns_r: str = "M"
    lmns_a: str = "60"
    lmns_repair_time: float = 30.0
    lmns_mip_focus: int = 0
    lmns_gap_to_bigger_destruction: int = 50
    lmns_gap_to_smaller_destruction: int = 95
    lmns_weight_shaw_dist_prox: float = 1.0
    lmns_weight_shaw_earl_prox: float = 1.0
    lmns_weight_shaw_same_route: float = 1.0
    lmns_weight_shaw_demand_sim: float = 1.0
    lmns_req_r_apply_mip_start: bool = True
    lmns_acceptance_criteria: str = "H"
    lmns_metropolis_temp: float = 100.0
    lmns_simulated_annealing_temp: float = 100.0
    lmns_simulated_annealing_cool: float = 0.95
    mip_max_time: int = 3600
    hx_max_time: int = 3600
    csv_file_name: str = ""
    sol_file_name: str = ""
    timeline_file_name: str = ""
    grb_file_name: str = ""
    validate_synchronization: bool = True
    constraints_used_melo_mip_str: str = "1-100"
    constraints_used_melo_mip: np.ndarray = None
    run_callback_melo_mip: bool = False
    mip_heuristics: float = 0.05 # default is 0.05 (according to docs)
    threads: int = 16

    def __post_init__(self):
        self.gen_config_file_name = os.path.basename(self.gen_config_file_path)[:-5]
        self.rng = random.Random(self.seed)
