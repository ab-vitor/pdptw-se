mutable struct StopParams
    rule::StopRule
    argument::Float64
    maximum_time::Int64 # any approach stop time
end

mutable struct AllParams
    general::ParameterData
    stop::StopParams
end

mutable struct ExternalMSLPData
    bestSol::Union{Solution, Nothing}
    currSol::Union{Solution, Nothing}
    lastSGreedySolValue::Float64

    env::Union{Gurobi.Env, Nothing}
    startTime::Float64
    iteration::Int64

    timeToBest::Float64
    iterationToBest::Int64
    largestUpdateOffset::Int64

    lpRuns::Int64
    lpImpr::Int64
    sumLPImprPercentage::Float64
    infeasibleSol::Int64
    totalTimeElapsed::Float64
    percentageInfeasibleSol::Float64
    percentageLPImpr::Float64
    meanLPImprPercentage::Float64

    countImprovements::Int64

    function ExternalMSLPData(
        bestSol::Union{Solution, Nothing} = nothing,
        currSol::Union{Solution, Nothing} = nothing,
        lastSGreedySolValue::Float64 = 0.0,
        env::Union{Gurobi.Env, Nothing} = nothing,
        startTime::Float64 = 0.0,
        iteration::Int64 = 0,
        timeToBest::Float64 = 0.0,
        iterationToBest::Int64 = 0,
        largestUpdateOffset::Int64 = 0,
        lpRuns::Int64 = 0,
        lpImpr::Int64 = 0,
        sumLPImprPercentage::Float64 = 0.0,
        infeasibleSol::Int64 = 0,
        totalTimeElapsed::Float64 = 0.0,
        percentageInfeasibleSol::Float64 = 0.0,
        percentageLPImpr::Float64 = 0.0,
        meanLPImprPercentage::Float64 = 0.0,
        countImprovements::Int64 = 0,
    )
        new(
            bestSol,
            currSol,
            lastSGreedySolValue,
            env,
            startTime,
            iteration,
            timeToBest,
            iterationToBest,
            largestUpdateOffset,
            lpRuns,
            lpImpr,
            sumLPImprPercentage,
            infeasibleSol,
            totalTimeElapsed,
            percentageInfeasibleSol,
            percentageLPImpr,
            meanLPImprPercentage,
            countImprovements
        )
    end
end


function load_stop_params(params::ParameterData)
	stop_rule = parse(StopRule, params.mslpr)
	if stop_rule == TARGET
		stop_argument = parse(Float64, params.mslpa)
	else
		stop_argument = parse(Int64, params.mslpa)
	end

	maximum_time = params.maxtime
	if maximum_time <= 0
		error("Maximum time must be larger than 0.0. Given $maximum_time.")
	end

	stopParams = StopParams(stop_rule, stop_argument, maximum_time)
	return stopParams
end

