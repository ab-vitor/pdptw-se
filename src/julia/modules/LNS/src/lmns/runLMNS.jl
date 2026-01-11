function continueRunningLMNS(extld::ExternalLMNSData, allParams::AllParams)::Bool
	currentTimeElapsed = time() - extld.startTime
	@printf("## Current time elapsed: %.6f seconds\n\n", currentTimeElapsed)
	return !(
		currentTimeElapsed >= allParams.stop.maximum_time ||
		(allParams.stop.rule == ITERATIONS && extld.iteration >= allParams.stop.argument) ||
		(allParams.stop.rule == MAXTIME && currentTimeElapsed >= allParams.stop.argument) ||
		(allParams.stop.rule == TARGET && extld.bestSol.value <= allParams.stop.argument + allParams.general.epsilon) ||
		extld.provedOptimality
	)
end

function destroyPhase!(
	extld::ExternalLMNSData,
	inst::InstanceData,
	allParams::AllParams,
)::Nothing
	selectDestroyOperator!(extld, allParams.dgd)
	tbd = time()
	extld.destroyOperatorFunction!(extld, inst, allParams)
	timeToDestroy = time() - tbd
	@printf("Time to destroy: %.6f seconds\n", timeToDestroy)
	push!(extld.historyLMNSData.timeDestroy, timeToDestroy)
	return nothing
end

function repairPhase!(
	extld::ExternalLMNSData,
	allParams::AllParams,
)::Nothing
	tbr = time()
	extld.mipSolT = repair!(extld, allParams)
	timeToRepair = time() - tbr
	@printf("Time to repair: %.6f seconds\n", timeToRepair)
	push!(extld.historyLMNSData.timeRepair, timeToRepair)
	return nothing
end


function runLMNS!(
	inst::InstanceData,
	extld::ExternalLMNSData,
	allParams::AllParams,
)::Nothing
	extld.startTime = time()

	println("\n[$(Dates.Time(Dates.now()))] Generating initial solution")
	extld.bestSol = getInitialSolution(extld.env, inst, allParams.general)
	if !extld.bestSol.feasible
		println("Initial solution was not feasible...")
		return extld.bestSol
	end
	currentTimeElapsed = time() - extld.startTime
	println("\n[$(Dates.Time(Dates.now()))] Time elapsed for initial solution: ", currentTimeElapsed)

	# ------------------------------------------------------------------------------------------------ #

	println("\n[$(Dates.Time(Dates.now()))] Fixing initial solution in MIP model")
	fixSolutionInMIPModel!(extld.bestSol, extld, inst)
	println("\n[$(Dates.Time(Dates.now()))] Time elapsed for fixing solution in MIP model: ", extld.totalTimeFixingSolution)

	# ------------------------------------------------------------------------------------------------ #

	println("* objValue;iteration;time")
	currentTimeElapsed = time() - extld.startTime
	@printf(
		"* %.2f;%d;%.6f\n",
		extld.bestSol.value,
		extld.iteration,
		currentTimeElapsed
	)
	push!(extld.historyLMNSData.objValues, extld.bestSol.value)

	extld.mipSolB.stats.objValue = extld.bestSol.value
	
	run = continueRunningLMNS(extld, allParams)
	while run
		extld.iteration += 1
		tbi = time()

		destroyPhase!(extld, inst, allParams)
		repairPhase!(extld, allParams)

		if extld.mipSolT === nothing
			fixMIPSolutionInMIPModel(extld, inst)
			decreaseDegreeOfDestruction!(extld, allParams.dgd)
		else
			# Solution acceptance criteria: hill climbing
			if allParams.ac.acFunction(extld, allParams.ac.sparams)
				extld.mipSol = extld.mipSolT
			end

			fixMIPSolutionInMIPModel(extld, inst)

			if extld.mipSolT.stats.objValue + allParams.general.epsilon < extld.mipSolB.stats.objValue
				updateCurrentResults!(extld, inst, allParams)
			end

			evaluateDestroyRepair!(extld, inst, allParams)
		end

		timeToIteration = time() - tbi
		push!(extld.historyLMNSData.timeElapsed, timeToIteration)
		run = continueRunningLMNS(extld, allParams)
	end
	extld.totalTimeElapsed = time() - extld.startTime
	extld.totalNumIterations = extld.iteration
	if extld.mipSolB.stats.status != INFEASIBLE
		extld.bestSol = createSolutionMelo(inst, extld.mipSolB, allParams.general)
	end

	return nothing
end
