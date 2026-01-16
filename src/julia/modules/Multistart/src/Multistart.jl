module Multistart

import Base.parse
using Printf

using Gurobi
using Data
using Parameters
using Solutions
using Formulations
using Random
using Enumerations
using DataFrames
using CSVUtils
using Dates
using ProcUsage

include("structs.jl")
include("greedy_utils.jl")
include("choose_candidate.jl")
include("greedy_heuristic.jl")
include("semi_greedy_heuristic.jl")
include("structures.jl")
include("run_MSLP.jl")
include("statistics.jl")
include("csv_results.jl")
include("improvement.jl")
include("post_running_MSLP.jl")
include("print_configuration.jl")

function multistartlpinitialsetup(env::Union{Gurobi.Env, Nothing}, inst::InstanceData, params::ParameterData)::Nothing
	dummySol = greedyHeuristic(inst, params)
	Formulations.run_LP_to_reschedule_solution(env, dummySol, inst, params)
	return nothing
end

function multistartlp(env::Union{Gurobi.Env, Nothing}, inst::InstanceData, params::ParameterData)::Solution
	stopParams = load_stop_params(params)
	allParams = AllParams(params, stopParams)

	isMainMethod = params.methodType == "heur" && params.methodCode == "mslp"
	if isMainMethod
		println("\n[$(Dates.Time(Dates.now()))] Print configuration")
		printConfiguration(inst, allParams)
	end

	extmd = ExternalMSLPData()
	extmd.env = env
	println("\n[$(Dates.Time(Dates.now()))] Starting running MSLP")
	t0 = cpu_times()[2]
	# extmd.startTime = CPUtime_us()
	extmd.startTime = cpu_times()[1]
	extmd.iteration = 1

	runMSLP!(inst, extmd, allParams)
	t1 = cpu_times()[2]
	@printf("System CPU time: %.2f seconds\n", t1 - t0)

	if isMainMethod
		println("\n[$(Dates.Time(Dates.now()))] Post running MSLP")
		post_running_MSLP!(inst, extmd, allParams)
	end

	return extmd.bestSol
end # function multistartlp()

end # module Multistart
