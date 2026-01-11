import time
from datetime import datetime

from modules.data import InstanceData
from modules.solutions import Solution
from modules.formulations import run_lp_form_to_reschedule_sol

from .entities_mslp import ParameterData, load_stop_params, AllParams, ExternalMSLPData
from .run_mslp import run_mslp
from .post_running_mslp import post_running_mslp
from .print_configuration import print_configuration
from .greedy_based_heuristics.greedy_heuristic import greedy_heuristic

def multi_start_lp_initial_setup(env, inst: InstanceData, params: ParameterData):
    dummy_sol = greedy_heuristic(inst, params)
    run_lp_form_to_reschedule_sol(env, dummy_sol, inst, params)

def multi_start_lp(env, inst: InstanceData, params: ParameterData) -> Solution:
    stop_params = load_stop_params(params)
    all_params = AllParams(general=params, stop=stop_params)

    is_main_method = params.method_type == "heur" and params.method_code == "mslp"
    if is_main_method:
        print(f"\n[{datetime.now().time()}] Print configuration")
        print_configuration(inst, all_params)

    extmd = ExternalMSLPData()
    extmd.env = env
    extmd.start_time = time.time()
    extmd.iteration = 1

    run_mslp(inst, extmd, all_params)

    if is_main_method:
        print(f"\n[{datetime.now().time()}] Post running MSLP")
        post_running_mslp(inst, extmd, all_params)

    return extmd.best_sol
