import sys
from modules.parameters import read_input_parameters
from modules.data import read_data
from modules.formulations import (
    melo_mip_formulation,
    melo_hexaly_formulation,
    hexaly_no_machine_formulation,
    barlo_hexaly_formulation,
    barlogon_hexaly_formulation,
)
from modules.solutions import print_detail_melo_formulation_solution, validate_solution

# from modules.greedy_heuristic_mutate import greedyHeuristicMutate
# from modules.multistart import (
#     multistartlpinitialsetup,
#     multistart_semi_greedy,
#     multistartlp
# )
# from modules.solutions import printDetailMeloFormulationSolution, validateSolution
# from modules.lns import lmns
from gurobipy import Env, Model

from modules.multistart import multi_start_lp_initial_setup, multi_start_lp
from modules.data import write_preprocessingdata_to_csv


# Initialize Gurobi environment
try:
    GRB_ENV = Env()
except Exception as _:
    GRB_ENV = None  # or a dummy object

if GRB_ENV is not None:
    model = Model(env=GRB_ENV)

# Read the parameters from command line
params = read_input_parameters(sys.argv)

# # Read instance data
inst = read_data(params)

sol = None
if params.method_type == "form":
    if params.method_code == "melo":
        sol = melo_mip_formulation(GRB_ENV, inst, params)
    if params.method_code == "melo_hx":
        sol = melo_hexaly_formulation(inst, params)
    elif params.method_code == "hx_no_mach":
        sol = hexaly_no_machine_formulation(inst, params)
    elif params.method_code == "barlo_hx":
        sol = melo_mip_formulation(GRB_ENV, inst, params)
        sol = barlo_hexaly_formulation(inst, params, sol)
    elif params.method_code == "barlogon_hx":
        # sol = melo_mip_formulation(GRB_ENV, inst, params)
        # print_detail_melo_formulation_solution(inst, sol)
        sol = barlogon_hexaly_formulation(inst, params, sol)
    elif params.method_code == "barbosa":
        sol = None
        # sol = barbosaFormulation(GRB_ENV, inst, params)
elif params.method_type == "heur":
    if params.method_code == "greedy":
        sol = None
        # sol = greedyHeuristicMutate(inst, params)
    elif params.method_code == "lmns":
        sol = None
        # multistartlpinitialsetup(GRB_ENV, inst, params)
        # sol = lmns(GRB_ENV, inst, params)
    elif params.method_code == "mssg":
        sol = None
        # sol = multistart_semi_greedy(inst, params)
    elif params.method_code == "mslp":
        sol = None
        multi_start_lp_initial_setup(GRB_ENV, inst, params)
        sol = multi_start_lp(GRB_ENV, inst, params)
elif params.method_type == "preprocessing":
    write_preprocessingdata_to_csv(inst, params)

if sol is not None and params.print_sol == 1:
    print_detail_melo_formulation_solution(inst, sol)
    # if validate_solution(inst, sol, params):
    if validate_solution(inst, sol, params):
        print("Everything is awesome!")
    else:
        print("Infeasible solution :(")
