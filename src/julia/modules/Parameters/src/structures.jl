mutable struct ParameterData
	inst_path::String # Path to the instance folder
	name::String # Instance name
	type::String # Instance type
	group::String # Instance group
	full_name::String # Full instance name
	method_type::String # Type of method: heur
	method_code::String # Code of the method: mslp, gmutate
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
	output_flag_grb_MSLP::Int64 # output flag for Gurobi in MSLP. 0 - no output, 1 - normal output
	mslpr::String # stop rule Mulsti-Start LP (MSLP). See Enumerations Module
	mslpa::String # stop argument given mslpr. See Enumerations Module
	csv_file_name::String # CSV file name
	sol_file_name::String # Solution file name
	timeline_file_name::String # Timeline file name
	threads::Int # Number of threads for the LP solver
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