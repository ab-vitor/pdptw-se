push!(LOAD_PATH, "modules/")
# using Pkg
# Pkg.activate(".")
# Pkg.instantiate()
# Pkg.build()

using Data
using Parameters
using Formulations
using Gurobi
using JuMP
using GreedyHeuristicMutate
using Multistart
using Solutions

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
inst = readData(params)

sol::Union{Nothing, Solution} = nothing
if params.methodType == "form"
	if params.methodCode == "melo"
		sol = meloFormulation(GRB_ENV, inst, params)
	end
elseif params.methodType == "heur"
	if params.methodCode == "greedy"
		sol = GreedyHeuristicMutate.greedyHeuristicMutate(inst, params)
	elseif params.methodCode == "mslp"
		Multistart.multistartlpinitialsetup(GRB_ENV, inst, params)
		sol = Multistart.multistartlp(GRB_ENV, inst, params)
	end
end

if sol !== nothing
	if params.printsol == 1
		printDetailMeloFormulationSolution(inst, sol)
	end
	
	if validateSolution(inst, sol, params)
		println("Everything is awesome!")
	else
		println("Infeasible solution :(")
	end
end