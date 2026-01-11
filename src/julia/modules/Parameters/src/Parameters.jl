module Parameters

using Random
using Printf
import Enumerations: SolverMethod

mutable struct ParameterData
	instPath::String
	name::String
	type::String
	group::String
	fullname::String
	methodType::String
	methodCode::String
	genconfigfile::String
	genconfigfilename::String
	greedy_service_order::String
	cutoff::Int
	cutoffmachs::Int
	num_machs::Int
	solver::String
	maxtime::Int64 # Maxtime of any approach
	gurobiCuts::Int # 0 -> no cut, 1 -> gurobi cuts
	typeUserCut::Int
	mipPresolve::Int # -1 -> automatic, 0 -> no presolve, 1 -> moderate, 2 -> agressive
	printsol::Int
	maxnodes::Int
	elevator::Int
	make_instance_feasible::Bool
	output::String
	suff_outputs::String
	suff_csv::String
	epsilon::Float64
	epsilonCap::Float64
	warmStart::Bool
	seed::Int
	rng::Random.MersenneTwister
	alpha::Float64
	maxiter::Int64
	outputFlagGrbMIP::Int64
	outputFlagGrbMSLP::Int64
	outputFlagGrbLMNS::Int64
	mslpr::String # stop rule Mulsti-Start LP (MSLP)
	mslpa::String # stop argument given mslpr
	lmnsr::String # stop rule large Large Multiple Neighborhood Search (LMNS)
	lmnsa::String # stop argument given lmnsr 
	lmnsRepairTime::Float64 # max time for repair operator
	lmnsMIPFocus::Int64 # 0 -> no focus, 1 -> focus on finding feasible solutions, 2 -> focus on proving optimality, 3 -> focus on improving the best bound
	lmnsGapToBiggerDestruction::Int64
	lmnsGapToSmallerDestruction::Int64
	lmnsWeightShawDistProx::Float64
	lmnsWeightShawEarlProx::Float64
	lmnsWeightShawSameRoute::Float64
	lmnsWeightShawDemandSim::Float64
	lmnsReqRApplyMIPStart::Bool
	lmnsAcceptanceCriteria::String
	lmnsMetropolisTemp::Float64
	lmnsSimulatedAnnealingTemp::Float64
	lmnsSimulatedAnnealingCool::Float64
	mipmaxtime::Int64 # max time for MIP solver
	csvfilename::String
	solfilename::String
	timelineFilename::String
	grbFilename::String
	threads::Int
	solverMethod::SolverMethod

	function ParameterData()
		instPath = "../../benchmark_multi_island_v5/instances/orig_ams_fg/12R_12V_04I_04M/t2/lr202/"
		name = ""
		type = ""
		group = ""
		fullname = ""
		# methodType = "form"
		# methodCode = "melo"
		methodType = "heur"
		methodCode = "mslp"
		genconfigfile = "configs/mslp/genconfig_mslp.conf"
		genconfigfilename = basename(genconfigfile)[1:end-5]
		greedy_service_order = "tightest_tw"
		solver = "Gurobi"
		maxtime = 999999999999999
		gurobiCuts = 1
		typeUserCut = 0
		mipPresolve = -1
		printsol = 0
		maxnodes = -1
		cutoff = 0
		cutoffmachs = 0
		num_machs = 0
		elevator = 0
		make_instance_feasible = false
		output = "./logs/"
		suff_outputs = ""
		suff_csv = ""
		# epsilon = 0.0001 # dealing with imprecision issues
		epsilon = 0.005 # dealing with imprecision issues
		# epsilon = 0.01 # dealing with imprecision issues
		epsilonCap = 0.5
		warmStart = false
		seed = 0
		alpha = 0.2
		maxiter = 1e6
		outputFlagGrbMIP = 0
		outputFlagGrbMSLP = 0
		outputFlagGrbLMNS = 0
		mslpr = "M" # check Enumerations Module
		mslpa = "60"
		lmnsr = "M" # check Enumerations Module
		lmnsa = "60"
		lmnsRepairTime = 30
		lmnsMIPFocus = 0
		lmnsGapToBiggerDestruction = 50
		lmnsGapToSmallerDestruction = 95
		mipmaxtime = 3600
		csvfilename = ""
		solfilename = ""
		timelineFilename = ""
		grbFilename = ""
		rng = Random.MersenneTwister(seed)
		lmnsWeightShawDistProx = 1
		lmnsWeightShawEarlProx = 1
		lmnsWeightShawSameRoute = 1
		lmnsWeightShawDemandSim = 1
		lmnsReqRApplyMIPStart = true
		lmnsAcceptanceCriteria = "H" # check Enumerations Module
		lmnsMetropolisTemp = 100
		lmnsSimulatedAnnealingTemp = 100
		lmnsSimulatedAnnealingCool = 0.95
		threads = 8
		solverMethod = parse(SolverMethod, "A")

		return new(
			instPath,
			name,
			type,
			group,
			fullname,
			methodType,
			methodCode,
			genconfigfile,
			genconfigfilename,
			greedy_service_order,
			cutoff,
			cutoffmachs,
			num_machs,
			solver,
			maxtime,
			gurobiCuts,
			typeUserCut,
			mipPresolve,
			printsol,
			maxnodes,
			elevator,
			make_instance_feasible,
			output,
			suff_outputs,
			suff_csv,
			epsilon,
			epsilonCap,
			warmStart,
			seed,
			rng,
			alpha,
			maxiter,
			outputFlagGrbMIP,
			outputFlagGrbMSLP,
			outputFlagGrbLMNS,
			mslpr,
			mslpa,
			lmnsr,
			lmnsa,
			lmnsRepairTime,
			lmnsMIPFocus,
			lmnsGapToBiggerDestruction,
			lmnsGapToSmallerDestruction,
			lmnsWeightShawDistProx,
			lmnsWeightShawEarlProx,
			lmnsWeightShawSameRoute,
			lmnsWeightShawDemandSim,
			lmnsReqRApplyMIPStart,
			lmnsAcceptanceCriteria,
			lmnsMetropolisTemp,
			lmnsSimulatedAnnealingTemp,
			lmnsSimulatedAnnealingCool,
			mipmaxtime,
			csvfilename,
			solfilename,
			timelineFilename,
			grbFilename,
			threads,
			solverMethod
		)
	end
end

export ParameterData, readInputParameters

function saveInstanceFullName!(params::ParameterData)::Nothing
	pathSplitted = splitpath(params.instPath)
	params.name = pathSplitted[end]

	if pathSplitted[end-1][1] == 't'
		params.type = pathSplitted[end-1]
		params.group = pathSplitted[end-2]
	else
		# old format
 		params.type = string("t", params.name[3])
		params.group = pathSplitted[end-1]
	end

	if params.cutoffmachs <= 0
		params.cutoffmachs = parse(Int64, params.group[end-2:end-1])
	end
	params.group = string(params.group[1:end-3], @sprintf("%02d", params.cutoffmachs), "M")

	params.fullname = string(params.name, '_', params.type, '_', params.group)

	println("Instance: ", params.fullname)
	return nothing
end

include("LoadGenConfig.jl")

function readInputParameters(ARGS)
	#println("Running Parameters.readInputParameters")

	### Set standard values for the parameters ###

	params = ParameterData()
	### Read the parameters and set correct values whenever provided ###
	for param in eachindex(ARGS)
		if ARGS[param] == "--inst"
			params.instPath = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--genconfigfile"
			params.genconfigfile = ARGS[param+1]
			params.genconfigfilename = basename(params.genconfigfile)[1:end-5]
			load_general_configuration!(params.genconfigfile, params)
			param += 1
		elseif ARGS[param] == "--solver"
			params.solver = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--maxtime"
			params.maxtime = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--printsol"
			params.printsol = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--methodType"
			params.methodType = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--methodCode"
			params.methodCode = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--greedy_service_order"
			params.greedy_service_order = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--cutoff"
			params.cutoff = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--cutoffmachs"
			params.cutoffmachs = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--num_machs"
			params.num_machs = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--elevator"
			params.elevator = 1
		elseif ARGS[param] == "--maxnodes"
			params.maxnodes = parse(Float64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--make_instance_feasible"
			params.make_instance_feasible = true
		elseif ARGS[param] == "--epsilon"
			params.epsilon = parse(Float64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--warmStart"
			params.warmStart = true
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
		elseif ARGS[param] == "--epsilonCap"
			params.epsilonCap = parse(Float64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--seed"
			params.seed = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--alpha"
			params.alpha = parse(Float64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--maxiter"
			params.maxiter = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--outputFlagGrb"
			params.outputFlagGrb = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--mslpr"
			params.mslpr = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--mslpa"
			params.mslpa = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--lmnsr"
			params.lmnsr = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--lmnsa"
			params.lmnsa = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--lmnsGapToBiggerDestruction"
			params.lmnsGapToBiggerDestruction = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--lmnsGapToSmallerDestruction"
			params.lmnsGapToSmallerDestruction = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--mipmaxtime"
			params.mipmaxtime = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--gurobiCuts"
			params.gurobiCuts = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--typeUserCut"
			params.typeUserCut = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--lmnsRepairTime"
			params.lmnsRepairTime = parse(Float64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--lmnsMIPFocus"
			params.lmnsMIPFocus = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--csvfilename"
			params.csvfilename = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--solfilename"
			params.solfilename = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--timelineFilename"
			params.timelineFilename = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--grbFilename"
			params.grbFilename = ARGS[param+1]
			param += 1
		elseif ARGS[param] == "--outputFlagGrbMIP"
			params.outputFlagGrbMIP = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--outputFlagGrbMSLP"
			params.outputFlagGrbMSLP = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--outputFlagGrbLMNS"
			params.outputFlagGrbLMNS = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--mipPresolve"
			params.mipPresolve = parse(Int64, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--threads"
			params.threads = parse(Int, ARGS[param+1])
			param += 1
		elseif ARGS[param] == "--solverMethod"
			params.solverMethod = parse(SolverMethod, ARGS[param+1])
			param += 1
		elseif startswith(ARGS[param], "--")
			error("Unknown parameter ", ARGS[param])
		end
	end

	if !endswith(params.instPath, '/')
		params.instPath *= '/'
	end
	if endswith(params.output, '/')
		params.output = params.output[1:end-1]
	end
	params.rng = MersenneTwister(params.seed)
	saveInstanceFullName!(params)
	params.csvfilename = string(
		params.output, "/",
		params.methodType, "_",
		params.methodCode, "/",
		"outputs/csvresults",
		"_", params.methodType,
		"_", params.methodCode,
		params.suff_csv,
		".csv",
	)
	params.solfilename = string(
		params.output, "/",
		params.methodType, "_",
		params.methodCode, "/",
		"solutions/",
		params.group, "/",
		params.name, "_sol_",
		params.genconfigfilename,
		params.suff_outputs,
		".txt",
	)
	params.timelineFilename = string(
		params.output, "/",
		params.methodType, "_",
		params.methodCode, "/",
		"timelines/",
		params.group, "/",
		params.name, "_timeline_",
		params.genconfigfilename,
		params.suff_outputs,
		".txt",
	)
	params.grbFilename = string(
		params.output, "/",
		params.methodType, "_",
		params.methodCode, "/",
		"gurobi/",
		params.group, "/",
		params.name, "_grb_",
		params.genconfigfilename,
		params.suff_outputs,
		".log",
	)

	return params

end ### end readInputParameters

end ### end module
