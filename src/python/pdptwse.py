import sys
from modules.parameters import read_input_parameters
from modules.data import read_data
from modules.formulations import (
    melo_mip_formulation,
    melo_hexaly_formulation,
)
from modules.solutions import print_detail_melo_formulation_solution, validate_solution
from gurobipy import Env, Model


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

if sol is not None and params.print_sol == 1:
    print_detail_melo_formulation_solution(inst, sol)
    # if validate_solution(inst, sol, params):
    if validate_solution(inst, sol, params):
        print("Everything is awesome!")
    else:
        print("Infeasible solution :(")
