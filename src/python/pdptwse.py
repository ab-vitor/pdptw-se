import sys
from modules.parameters import read_input_parameters
from modules.data import read_data
from modules.formulations import (
    mip_gurobi_formulation,
    mip_hexaly_formulation,
)
from modules.solutions import print_timeline_solution, validate_solution
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
    if params.method_code == "mip_grb":
        sol = mip_gurobi_formulation(GRB_ENV, inst, params)
    if params.method_code == "mip_hx":
        sol = mip_hexaly_formulation(inst, params)

if sol is not None:
    if params.print_sol == 1:
        print_timeline_solution(inst, sol)
    
    if validate_solution(inst, sol, params):
        print("Feasible solution! :D")
    else:
        print("Infeasible solution! :(")
