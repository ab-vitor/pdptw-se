mutable struct StopParams
	rule::StopRule
	argument::Float64
	maximum_time::Int64 # any approach stop time
end

mutable struct ShawParams
	weightDistProx::Float64
	weightEarlProx::Float64
	weightSameRoute::Float64
	weightDemandSim::Float64
end

mutable struct ReqRParams
	applyMIPStart::Bool
end

mutable struct DegreeDestructionParams
	gapToSmallerDestruction::Int64
	gapToBiggerDestruction::Int64
	maxPsi::Vector{Int64}
	minPsi::Vector{Int64}
	psiOpt::Vector{Int64}
	rng::Random.MersenneTwister
	epsilon::Float64
end

mutable struct HillClimbingParams
	epsilon::Float64
end

mutable struct MetropolisParams
	temp::Float64
	epsilon::Float64
	rng::Random.MersenneTwister
end

mutable struct SimulatedAnnealingParams
	temp::Float64
	cool::Float64
	epsilon::Float64
	rng::Random.MersenneTwister
end

mutable struct AcceptanceCriteriaParams
	sparams::Union{HillClimbingParams, MetropolisParams, SimulatedAnnealingParams}
	acFunction::Function
end

mutable struct AllParams
	general::ParameterData
	stop::StopParams
	shaw::ShawParams
	reqr::ReqRParams
	dgd::DegreeDestructionParams
	ac::AcceptanceCriteriaParams
end

mutable struct HistoryLMNSData
	timeElapsed::Vector{Float64}
	timeRepair::Vector{Float64}
	timeDestroy::Vector{Float64}
	numDestroyedVars::Vector{Int64}
	timeFixingMIPSolution::Vector{Float64}
	objValues::Vector{Float64}
	mipStatus::Vector{TerminationStatusCode}
	psi::Vector{Vector{Int64}}

	function HistoryLMNSData(
		timeElapsed::Vector{Float64} = Float64[],
		timeRepair::Vector{Float64} = Float64[],
		timeDestroy::Vector{Float64} = Float64[],
		numDestroyedVars::Vector{Int64} = Int64[],
		timeFixingMIPSolution::Vector{Float64} = Float64[],
		objValues::Vector{Float64} = Float64[],
		mipStatus::Vector{TerminationStatusCode} = TerminationStatusCode[],
		psi::Vector{Vector{Int64}} = Vector{Int64}[],
	)
		psi = Vector{Int64}[[] for _ in 1:length(instances(DestroyOperator))]
		return new(timeElapsed, timeRepair, timeDestroy, numDestroyedVars, timeFixingMIPSolution, objValues, mipStatus, psi)
	end
end

mutable struct ExternalLMNSData
	bestSol::Union{Solution, Nothing}
	mipModel::Union{MIPModel, Nothing}
	# MIP solutions
	mipSol::Union{MIPSolution, Nothing}
	mipSolB::Union{MIPSolution, Nothing}
	mipSolT::Union{MIPSolution, Nothing}

	# ENV for Gurobi
	env::Union{Gurobi.Env, Nothing}

	# Auxiliary variables
	startTime::Float64
	iteration::Int64

	# Improvement stats
	timeToBest::Float64
	iterationToBest::Int64
	largestUpdateOffset::Int64

	# Iteration stats
	totalNumIterations::Int64

	# Time elapsed stats
	totalTimeElapsed::Float64
	meanTimeElapsed::Float64
	stdTimeElapsed::Float64
	maxTimeElapsed::Float64
	minTimeElapsed::Float64

	# Degree of destruction
	psi::Vector{Int64}
	delta::Vector{Int64}
	lastActiveRoutes::Int64

	# Destroy operator
	destroyOptions::Vector{Tuple{Function, DestroyOperator}}
	destroyOperator::DestroyOperator
	destroyOperatorFunction!::Function

	# Repair stats
	totalTimeRepair::Float64
	meanTimeRepair::Float64
	stdTimeRepair::Float64
	maxTimeRepair::Float64
	minTimeRepair::Float64

	# Destroy stats
	totalTimeDestroy::Float64
	meanTimeDestroy::Float64
	stdTimeDestroy::Float64
	maxTimeDestroy::Float64
	minTimeDestroy::Float64

	# Num destroyed vars stats
	meanNumDestroyedVars::Float64
	stdNumDestroyedVars::Float64
	maxNumDestroyedVars::Int64
	minNumDestroyedVars::Int64

	# Fixing MIP solution stats
	totalTimeFixingMIPSolution::Float64
	meanTimeFixingMIPSolution::Float64
	stdTimeFixingMIPSolution::Float64
	maxTimeFixingMIPSolution::Float64
	minTimeFixingMIPSolution::Float64

	# Fixing solution stats
	totalTimeFixingSolution::Float64

	# Counts
	countImprovements::Int64
	countImprovementsPerOperator::Vector{Int64}
	countExecutionsPerOperator::Vector{Int64}
	countExecutionsPerOperatorAndPsi::Vector{Dict{Int64, Int64}}

	# Flags
	provedOptimality::Bool

	# Acceptance criteria
	acceptanceCriteriaFunction::Function

	# History
	historyLMNSData::HistoryLMNSData

	# Tabu List
	tabuList::Vector{Dict{Int64, Vector{Int64}}}

	function ExternalLMNSData(
		bestSol::Union{Solution, Nothing} = nothing,
		mipModel::Union{MIPModel, Nothing} = nothing,
		# MIP solutions
		mipSol::Union{MIPSolution, Nothing} = MIPSolution(),
		mipSolB::Union{MIPSolution, Nothing} = MIPSolution(),
		mipSolT::Union{MIPSolution, Nothing} = MIPSolution(),
		# ENV for Gurobi
		env::Union{Gurobi.Env, Nothing} = nothing,
		# Auxiliary variables
		startTime::Float64 = 0.0,
		iteration::Int64 = 0,
		# Improvement stats
		timeToBest::Float64 = 0.0,
		iterationToBest::Int64 = 0,
		largestUpdateOffset::Int64 = 0,
		# Iteration stats
		totalNumIterations::Int64 = 0,
		# Time elapsed stats
		totalTimeElapsed::Float64 = 0.0,
		meanTimeElapsed::Float64 = 0.0,
		stdTimeElapsed::Float64 = 0.0,
		maxTimeElapsed::Float64 = 0.0,
		minTimeElapsed::Float64 = Inf64,
		# Degree of destruction
		psi::Vector{Int64} = Int64[],
		delta::Vector{Int64} = Int64[],
		lastActiveRoutes::Int64 = 1,
		# Destroy operator
		destroyOptions::Vector{Tuple{Function, DestroyOperator}} = Tuple{Function, DestroyOperator}[],
		destroyOperator::DestroyOperator = RANDOM_REQUEST_REMOVAL,
		destroyOperatorFunction!::Function = randomRequestRemoval!,
		# Repair stats
		totalTimeRepair::Float64 = 0.0,
		meanTimeRepair::Float64 = 0.0,
		stdTimeRepair::Float64 = 0.0,
		maxTimeRepair::Float64 = 0.0,
		minTimeRepair::Float64 = Inf64,
		# Destroy stats
		totalTimeDestroy::Float64 = 0.0,
		meanTimeDestroy::Float64 = 0.0,
		stdTimeDestroy::Float64 = 0.0,
		maxTimeDestroy::Float64 = 0.0,
		minTimeDestroy::Float64 = Inf64,
		# Destroyed vars stats
		meanNumDestroyedVars::Float64 = 0.0,
		stdNumDestroyedVars::Float64 = 0.0,
		maxNumDestroyedVars::Int64 = 0,
		minNumDestroyedVars::Int64 = typemax(Int64),
		# Fixing MIP solution stats
		totalTimeFixingMIPSolution::Float64 = 0.0,
		meanTimeFixingMIPSolution::Float64 = 0.0,
		stdTimeFixingMIPSolution::Float64 = 0.0,
		maxTimeFixingMIPSolution::Float64 = 0.0,
		minTimeFixingMIPSolution::Float64 = Inf64,
		# Fixing solution stats
		totalTimeFixingSolution::Float64 = 0.0,
		# Counts
		countImprovements::Int64 = 0,
		countImprovementsPerOperator::Vector{Int64} = Int64[],
		countExecutionsPerOperator::Vector{Int64} = Int64[],
		countExecutionsPerOperatorAndPsi::Vector{Dict{Int64, Int64}} = Dict{Int64, Int64}[],
		# Flags
		provedOptimality::Bool = false,
		# Acceptance Criteria
		acceptanceCriteriaFunction::Function = hillClimbing,
		# History
		historyLMNSData::HistoryLMNSData = HistoryLMNSData(),
		# Tabu list
		tabuList::Vector{Vector{Dict{Int64, Vector{Int64}}}} = Vector{Dict{Int64, Vector{Int64}}}[],
	)
		destroyOptions = Tuple{Function, DestroyOperator}[
		# (randomRequestRemoval!, RANDOM_REQUEST_REMOVAL),
		# (randomRouteRemoval!, RANDOM_ROUTE_REMOVAL),
			(shawRemoval!, SHAW_REMOVAL),
		# (proximityBasedRemoval!, PROXIMITY_BASED_REMOVAL),
		# (timeBasedRemoval!, TIME_BASED_REMOVAL),
		# (demandBasedRemoval!, DEMAND_BASED_REMOVAL),
		]
		countImprovementsPerOperator = zeros(length(instances(DestroyOperator)))
		countExecutionsPerOperator = zeros(length(instances(DestroyOperator)))
		psi = ones(length(instances(DestroyOperator)))
		delta = ones(length(instances(DestroyOperator)))
		countExecutionsPerOperatorAndPsi = Dict{Int64, Int64}[Dict{Int64, Int64}() for _ in 1:length(instances(DestroyOperator))]
		tabuList = Dict{Int64, Vector{Int64}}[Dict{Int64, Vector{Int64}}() for _ in 1:length(instances(DestroyOperator))]
		return new(
			bestSol,
			mipModel,
			# MIP solutions 
			mipSol,
			mipSolB,
			mipSolT,
			# ENV for Gurobi
			env,
			# Auxiliary variables
			startTime,
			iteration,
			# Improvement stats
			timeToBest,
			iterationToBest,
			largestUpdateOffset,
			# Iteration Stats
			totalNumIterations,
			# Time elapsed stats
			totalTimeElapsed,
			meanTimeElapsed,
			stdTimeElapsed,
			maxTimeElapsed,
			minTimeElapsed,
			# Degree of destruction
			psi,
			delta,
			lastActiveRoutes,
			# Destroy operator
			destroyOptions,
			destroyOperator,
			destroyOperatorFunction!,
			# Repair stats
			totalTimeRepair,
			meanTimeRepair,
			stdTimeRepair,
			maxTimeRepair,
			minTimeRepair,
			# Destroy stats
			totalTimeDestroy,
			meanTimeDestroy,
			stdTimeDestroy,
			maxTimeDestroy,
			minTimeDestroy,
			# Destroyed vars stats
			meanNumDestroyedVars,
			stdNumDestroyedVars,
			maxNumDestroyedVars,
			minNumDestroyedVars,
			# Fixing MIP solution stats
			totalTimeFixingMIPSolution,
			meanTimeFixingMIPSolution,
			stdTimeFixingMIPSolution,
			maxTimeFixingMIPSolution,
			minTimeFixingMIPSolution,
			# Fixing solution stats
			totalTimeFixingSolution,
			# Counts
			countImprovements,
			countImprovementsPerOperator,
			countExecutionsPerOperator,
			countExecutionsPerOperatorAndPsi,
			# Flags
			provedOptimality,
			# AcceptanceCriteria,
			acceptanceCriteriaFunction,
			# History
			historyLMNSData,
			# Tabu list,
			tabuList,
		)
	end
end

function ExternalLMNSDataConstructor(; kwargs...)::ExternalLMNSData
	obj = ExternalLMNSData()  # Create an instance with default values
	for (key, value) in kwargs
		if hasfield(ExternalLMNSData, key)
			setfield!(obj, key, value)
		else
			error("Field $key does not exist in ExternalLMNSData.")
		end
	end
	return obj
end


function load_stop_params(params::ParameterData)
	stop_rule = parse(StopRule, params.lmnsr)
	if stop_rule == TARGET
		stop_argument = parse(Float64, params.lmnsa)
	else
		stop_argument = parse(Int64, params.lmnsa)
	end

	maximum_time = params.maxtime
	if maximum_time <= 0
		error("Maximum time must be larger than 0.0. Given $maximum_time.")
	end

	stopParams = StopParams(stop_rule, stop_argument, maximum_time)
	return stopParams
end

function load_shaw_params(params::ParameterData)
	return ShawParams(
		params.lmnsWeightShawDistProx,
		params.lmnsWeightShawEarlProx,
		params.lmnsWeightShawSameRoute,
		params.lmnsWeightShawDemandSim,
	)
end

function load_reqr_params(params::ParameterData)
	return ReqRParams(
		params.lmnsReqRApplyMIPStart,
	)
end

function load_dgd_params(inst::InstanceData, params::ParameterData)::DegreeDestructionParams
	nr = inst.n
	npd = 2 * inst.n
	nk = length(inst.K)
	lastActiveRoutes = 0
	maxPsi = Int64[nr, nk, npd, npd, npd, npd]
	minPsi = ones(length(instances(DestroyOperator)))
	psiOpt = Int64[nr, nk, npd, npd, npd, npd]
	return DegreeDestructionParams(
		params.lmnsGapToSmallerDestruction,
		params.lmnsGapToBiggerDestruction,
		maxPsi,
		minPsi,
		psiOpt,
		params.rng,
		params.epsilon,
	)
end


function load_ac_params(params::ParameterData)::AcceptanceCriteriaParams
	criteria = parse(AcceptanceCriteria, params.lmnsAcceptanceCriteria)
	sparams = nothing
	acFunction = function () end
	if criteria == HILL_CLIMBING
		sparams = HillClimbingParams(params.epsilon)
		acFunction = hillClimbing
	elseif criteria == METROPOLIS
		sparams = MetropolisParams(params.lmnsMetropolisTemp, params.epsilon, params.rng)
		acFunction = metropolis
	elseif criteria == SIMULATED_ANNEALING
		sparams = SimulatedAnnealingParams(params.lmnsSimulatedAnnealingTemp, params.lmnsSimulatedAnnealingCool, params.epsilon, params.rng)
		acFunction = simulatedAnnealing!
	else
		error("Acceptance criteria $(string(criteria)) not implemented.")
	end

	return AcceptanceCriteriaParams(sparams, acFunction)
end
