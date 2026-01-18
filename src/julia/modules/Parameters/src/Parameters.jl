module Parameters

using Random
using Printf
import Enumerations: SolverMethod

mutable struct ParameterData
	inst_path::String # Path to the instance folder
	name::String # Instance name
	type::String # Instance type
	group::String # Instance group
	full_name::String # Full instance name
	method_type::String # Type of method: heur
	method_code::String # Code of the method: mslp, greedy
	gen_config_file_path::String # Path to the general configuration file
	gen_config_file_name::String # Name of the general configuration file without extension
	greedy_service_order::String # Service order in greedy heuristic: tightest_tw, random
	cut_off::Int # Cut-off value for the instance
	cut_off_machs::Int # Cut-off value for the number of machines
	solver::String # Solver to be used: Gurobi
	max_time::Float64 # Maxtime of any approach
	print_sol::Int # Print solution flag
	elevator::Int # Elevator constraint flag
	make_instance_feasible::Bool # Make instance feasible flag
	output::String # Output folder
	suff_outputs::String # Suffix for output files
	suff_csv::String # Suffix for csv files
	epsilon::Float64 # dealing with imprecision issues
	epsilon_cap::Float64 # dealing with imprecision issues for capacities
	seed::Int # Seed for random number generator
	rng::Random.MersenneTwister # Random number generator
	alpha::Float64 # Alpha parameter for semi-greedy heuristic
	output_flag_grb_MSLP::Int64 # output flag for Gurobi in MSLP
	mslpr::String # stop rule Mulsti-Start LP (MSLP)
	mslpa::String # stop argument given mslpr
	csv_file_name::String # CSV file name
	sol_file_name::String # Solution file name
	timeline_file_name::String # Timeline file name
	threads::Int # Number of threads for the solver
	solver_method::SolverMethod # Solver method for Gurobi

	function ParameterData()
		inst_path = "../../benchmark_multi_island_v5/instances/orig_ams_fg/12R_12V_04I_04M/t2/lr202/"
		name = ""
		type = ""
		group = ""
		full_name = ""
		method_type = "heur"
		method_code = "mslp"
		gen_config_file_path = "configs/mslp/genconfig_mslp.conf"
		gen_config_file_name = basename(gen_config_file_path)[1:end-5]
		greedy_service_order = "tightest_tw"
		solver = "Gurobi"
		max_time = Inf64
		print_sol = 0
		cut_off = 0
		cut_off_machs = 0
		elevator = 0
		make_instance_feasible = false
		output = "./logs/"
		suff_outputs = ""
		suff_csv = ""
		epsilon = 0.005 # dealing with imprecision issues
		epsilon_cap = 0.5 # dealing with imprecision issues
		seed = 0
		alpha = 0.2
		output_flag_grb_MSLP = 0
		mslpr = "M" # check Enumerations Module
		mslpa = "60"
		csv_file_name = ""
		sol_file_name = ""
		timeline_file_name = ""
		rng = Random.MersenneTwister(seed)
		threads = 8
		solver_method = parse(SolverMethod, "A")

		return new(
			inst_path,
			name,
			type,
			group,
			full_name,
			method_type,
			method_code,
			gen_config_file_path,
			gen_config_file_name,
			greedy_service_order,
			cut_off,
			cut_off_machs,
			solver,
			max_time,
			print_sol,
			elevator,
			make_instance_feasible,
			output,
			suff_outputs,
			suff_csv,
			epsilon,
			epsilon_cap,
			seed,
			rng,
			alpha,
			output_flag_grb_MSLP,
			mslpr,
			mslpa,
			csv_file_name,
			sol_file_name,
			timeline_file_name,
			threads,
			solver_method
		)
	end
end

export ParameterData, read_input_parameters

function save_instance_full_name!(params::ParameterData)::Nothing
	pathSplitted = splitpath(params.inst_path)

	params.name = pathSplitted[end] # e.g.: lr202
	params.type = pathSplitted[end-1] # t1 or t2
	params.group = pathSplitted[end-2] # e.g.: 60R_60V_04I_06M

	if params.cut_off_machs <= 0
		params.cut_off_machs = parse(Int64, params.group[end-2:end-1]) # take the last two digits before 'M', e.g.: 06 from 60R_60V_04I_06M
	end
	params.group = string(params.group[1:end-3], @sprintf("%02d", params.cut_off_machs), "M")

	params.full_name = string(params.name, '_', params.type, '_', params.group)

	println("Instance: ", params.full_name)
	return nothing
end

include("load_general_configuration.jl")

function read_input_parameters(ARGS::Vector{String})::ParameterData
	println("Running Parameters.read_input_parameters")

	### Set standard values for the parameters ###

	params = ParameterData()
	### Read the parameters and set correct values whenever provided ###
	for param in eachindex(ARGS)
		if ARGS[param] == "--inst"
			params.inst_path = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--gen_config_file_path"
			params.gen_config_file_path = ARGS[param+1]
			params.gen_config_file_name = basename(params.gen_config_file_path)[1:end-5]
			load_general_configuration!(params.gen_config_file_path, params)
			param += 1
		elseif ARGS[param] == "--solver"
			params.solver = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--max_time"
			params.max_time = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--print_sol"
			params.print_sol = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--method_type"
			params.method_type = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--method_code"
			params.method_code = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--greedy_service_order"
			params.greedy_service_order = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--cut_off"
			params.cut_off = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--cut_off_machs"
			params.cut_off_machs = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--elevator"
			params.elevator = 1
		elseif ARGS[param] == "--make_instance_feasible"
			params.make_instance_feasible = true
		elseif ARGS[param] == "--epsilon"
			params.epsilon = parse(Float64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--output"
			params.output = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--suff_outputs"
			params.suff_outputs = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--suff_csv"
			params.suff_csv = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--epsilon_cap"
			params.epsilon_cap = parse(Float64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--seed"
			params.seed = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--alpha"
			params.alpha = parse(Float64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--output_flag_grb"
			params.output_flag_grb = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--mslpr"
			params.mslpr = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--mslpa"
			params.mslpa = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--csv_file_name"
			params.csv_file_name = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--sol_file_name"
			params.sol_file_name = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--timeline_file_name"
			params.timeline_file_name = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--output_flag_grb_MSLP"
			params.output_flag_grb_MSLP = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--threads"
			params.threads = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--solver_method"
			params.solver_method = parse(SolverMethod, ARGS[param+1])
			param += 1
		elseif startswith(ARGS[param], "--")
			error("Unknown parameter ", ARGS[param])
		end
	end

	if !endswith(params.inst_path, '/')
		params.inst_path *= '/'
	end
	if endswith(params.output, '/')
		params.output = params.output[1:end-1]
	end
	params.rng = MersenneTwister(params.seed)
	save_instance_full_name!(params)
	params.csv_file_name = string(
		params.output, "/",
		params.method_type, "_",
		params.method_code, "/",
		"outputs/csvresults",
		"_", params.method_type,
		"_", params.method_code,
		params.suff_csv,
		".csv",
	)
	params.sol_file_name = string(
		params.output, "/",
		params.method_type, "_",
		params.method_code, "/",
		"solutions/",
		params.group, "/",
		params.name, "_sol_",
		params.gen_config_file_name,
		params.suff_outputs,
		".txt",
	)
	params.timeline_file_name = string(
		params.output, "/",
		params.method_type, "_",
		params.method_code, "/",
		"timelines/",
		params.group, "/",
		params.name, "_timeline_",
		params.gen_config_file_name,
		params.suff_outputs,
		".txt",
	)

	return params

end ### end read_input_parameters

end ### end module
