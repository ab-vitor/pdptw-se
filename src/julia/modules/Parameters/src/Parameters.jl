module Parameters

using Random
using Printf
import Enumerations: SolverMethod

include("structures.jl")
include("load_general_configuration.jl")

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

function read_input_parameters(ARGS::Vector{String})::ParameterData
	println("Running Parameters.read_input_parameters")

	### Set standard values for the parameters ###

	params = ParameterData()
	### Read the parameters and set correct values whenever provided ###
	for param in eachindex(ARGS)
		if ARGS[param] == "--inst_path"
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
