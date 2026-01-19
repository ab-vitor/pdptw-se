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
include("heuristic/heuristic.jl")
include("structures.jl")
include("run_MSLP.jl")
include("statistics.jl")
include("csv_results.jl")
include("improvement.jl")
include("post_running_MSLP.jl")
include("print_configuration.jl")

"""
	function multistart_LP_initial_setup(env::Union{Gurobi.Env, Nothing}, inst::InstanceData, params::ParameterData)::Nothing
	
	Performs an initial setup for the Multi-Start LP heuristic by generating a dummy solution 
	using a greedy heuristic and rescheduling it using LP.
	This enables a faster execution of the Multi-Start LP heuristic in subsequent runs.
"""
function multistart_LP_initial_setup(env::Union{Gurobi.Env, Nothing}, inst::InstanceData, params::ParameterData)::Nothing
	dummy_sol = greedy_heuristic(inst)
	Formulations.run_LP_to_reschedule_solution(env, dummy_sol, inst, params)
	return nothing
end

"""
	function multi_start_LP(env::Union{Gurobi.Env, Nothing}, inst::InstanceData, params::ParameterData)::Solution
	
	Executes the Multi-Start heuristic with LP improvement procedure on the given instance with the specified parameters.
	Returns the best solution found during the execution.
"""
function multi_start_LP(env::Union{Gurobi.Env, Nothing}, inst::InstanceData, params::ParameterData)::Solution
	stop_params = load_stop_params(params)
	all_params = AllParams(params, stop_params)

	is_main_method = params.method_type == "heur" && params.method_code == "mslp"
	if is_main_method
		println("\n[$(Dates.Time(Dates.now()))] Print configuration")
		print_configuration(inst, all_params)
	end

	extmd = ExternalMSLPData()
	extmd.env = env
	println("\n[$(Dates.Time(Dates.now()))] Starting running MSLP")
	t0 = cpu_times()[2]
	extmd.start_time = cpu_times()[1]
	extmd.iteration = 1

	run_MSLP!(inst, extmd, all_params)
	t1 = cpu_times()[2]
	@printf("System CPU time: %.2f seconds\n", t1 - t0)

	if is_main_method
		println("\n[$(Dates.Time(Dates.now()))] Post running MSLP")
		post_running_MSLP!(inst, extmd, all_params)
	end

	return extmd.best_sol
end # function multi_start_LP()

end # module Multistart
