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
	# Model(Gurobi.Optimizer)
end

# Read the parameters from command line
params = readInputParameters(ARGS)

# Read instance data
inst = read_data(params)

# Solve the problem according to the selected method
sol::Union{Nothing, Solution} = nothing
if params.methodType == "heur"
	if params.methodCode == "greedy"
		sol = GreedyHeuristicMutate.greedyHeuristicMutate(inst, params)
	elseif params.methodCode == "mslp"
		Multistart.multistartlpinitialsetup(GRB_ENV, inst, params)
		sol = Multistart.multistartlp(GRB_ENV, inst, params)
	end
end

# Print solution details and validate solution
if sol !== nothing
	if params.printsol == 1
		printDetailMeloFormulationSolution(inst, sol)
	end
	
	if validate_solution(inst, sol, params)
		println("Feasible solution! :D")
	else
		println("Infeasible solution! :(")
	end
end