import os
import random
from dataclasses import dataclass, field

import numpy as np


@dataclass
class ParameterData:
    inst_path: str = (
        "../../instances/multi_island/orig_ams_fg/06R_06V_02I_04M/t2/lr202/"
    ) # path to instance file
    name: str = "" # instance name
    type: str = "" # instance type
    group: str = "" # instance group
    full_name: str = "" # full instance name
    method_type: str = "form" # method type
    method_code: str = "mip_grb" # method code
    gen_config_file_path: str = "configs/mip_grb/genconfig_mip_grb.conf" # path to general configuration file
    gen_config_file_name: str = field(init=False) # general configuration file name
    cut_off: int = 0 # cut-off value for the number of requests
    cut_off_machs: int = 0 # cut-off value for the number of machines (always the first machines)
    solver: str = "Gurobi" # solver name
    max_time: int = 7200 # maximum time allowed for the solver
    gurobi_cuts: int = 1 # use gurobi cuts. 0 -> no gurobi_cuts, 1 -> use gurobi cuts
    mip_grb_presolve: int = -1 # Presolve parameter in gurobi. -1 -> automatic, 0 -> off, 1 -> conservative, 2 -> aggressive
    print_sol: int = 0 # whether to print the timeline solution or not at the end. 1 -> print, 0 -> do not print
    max_nodes: int = -1 # maximum number of nodes to be explored by the solver. Negative values mean no limit.
    elevator: int = 0 # must be zero for multi-island instances, and one for multi-floor instances
    output: str = "./logs/" # path to output directory
    epsilon: float = 0.005 # precision level for general validation
    epsilon_cap: float = 0.5 # precision level for vehicle capacity validation
    seed: int = 0 # seed for the random number generator (rng)
    rng: random.Random = field(init=False) # random number generator
    output_flag_grb_mip: int = 0 # whether gurobi output is displayed or not
    mip_grb_max_time: int = 3600 # mip gurobi max time
    mip_hx_max_time: int = 3600 # mip hexaly max time
    csv_file_name: str = "" # path to csv file for results. Don't pass this parameter, because there is a default destination based on parameter output
    sol_file_name: str = "" # path to simple solution description file. Don't pass this parameter, because there is a default destination based on parameter output
    timeline_file_name: str = "" # path to timeline solution file. Don't pass this parameter, because there is a default destination based on parameter output
    grb_file_name: str = "" # path to gurobi solution file. Don't pass this parameter, because there is a default destination based on parameter output
    validate_synchronization: bool = True # flag to decide whether synchronization constraints should be validated or not
    constraints_used_mip_str: str = "1-100" # string to decide which constraints should be used in the MIP formulation, in string format
    constraints_used_mip: np.ndarray = None # array to decide which constraints should be used in the MIP formulation
    run_callback_mip_gurobi: bool = False # whether to run the gurobi callback for checking user cuts
    mip_grb_heuristics: float = 0.05  # default is 0.05 (according to Gurobi docs)
    threads: int = 16

    def __post_init__(self):
        self.gen_config_file_name = os.path.basename(self.gen_config_file_path)[:-5]
        self.rng = random.Random(self.seed)
