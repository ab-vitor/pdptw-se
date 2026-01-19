push!(LOAD_PATH, "modules/")

using Data
using Parameters
using Formulations
using Gurobi
using JuMP
using GreedyHeuristicMutate
using Multistart
using Solutions

# Check if Gurobi is available
const GRB_ENV = let
    try
        @eval using Gurobi
        Gurobi.Env()
    catch e
        nothing  # or a dummy object
    end
end
if GRB_ENV !== nothing
	Model(() -> Gurobi.Optimizer(GRB_ENV))
	# Model(Gurobi.Optimizer) # for debugging purposes
end

# Read the parameters from command line
params = read_input_parameters(ARGS)

# Read instance data
inst = read_data(params)

# Solve the problem according to the selected method
sol::Union{Nothing, Solution} = nothing
if params.method_type == "heur"
	if params.method_code == "gmutate"
		sol = GreedyHeuristicMutate.greedy_heuristic_mutate(inst, params)
	elseif params.method_code == "mslp"
		Multistart.multistart_LP_initial_setup(GRB_ENV, inst, params)
		sol = Multistart.multi_start_LP(GRB_ENV, inst, params)
	end
end

# Print solution details and validate solution
if sol !== nothing
	if params.print_sol == 1
		print_timeline_solution(inst, sol)
	end
	
	if validate_solution(inst, sol, params)
		println("Feasible solution! :D")
	else
		println("Infeasible solution! :(")
	end
end