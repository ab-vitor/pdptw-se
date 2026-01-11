function continueRunningMSLP(extmd::ExternalMSLPData, allParams::AllParams)::Bool
	# currentTimeElapsed = (CPUtime_us() - extmd.startTime)/1e6
	currentTimeElapsed = cpu_times()[1] - extmd.startTime
	return !(
		currentTimeElapsed >= allParams.stop.maximum_time ||
		(allParams.stop.rule == ITERATIONS && extmd.iteration >= allParams.stop.argument) ||
		(allParams.stop.rule == FEASIBILITY && extmd.bestSol.feasible) ||
		(allParams.stop.rule == MAXTIME && currentTimeElapsed >= allParams.stop.argument) ||
		(allParams.stop.rule == TARGET && extmd.bestSol.value <= allParams.stop.argument + allParams.general.epsilon)
	)
end

function runMSLP!(inst::InstanceData, extmd::ExternalMSLPData, allParams::AllParams)::Nothing
	println("objValue;greedysol;iteration;time")
	extmd.currSol = greedyHeuristic(inst, allParams.general)

	if extmd.currSol.feasible
		extmd.lastSGreedySolValue = extmd.currSol.value
		extmd.currSol = Formulations.runLPFormToReScheduleSol(extmd.env, extmd.currSol, inst, allParams.general)
		extmd.lpRuns += 1

		if extmd.currSol.feasible && extmd.currSol.value < extmd.lastSGreedySolValue
			extmd.lpImpr += 1
			extmd.sumLPImprPercentage += round(
				(extmd.lastSGreedySolValue - extmd.currSol.value) / extmd.lastSGreedySolValue,
				digits = 4,
			)
		end
		if extmd.currSol.feasible
			updateCurrentResults!(extmd, allParams)
		else
			extmd.bestSol = extmd.currSol
			extmd.bestSol.value = Inf64
		end
	else
		extmd.infeasibleSol += 1
		extmd.bestSol = extmd.currSol
		extmd.bestSol.value = Inf64
		# println("/!\\ First greedy heuristic solution was not feasible...")
	end

	run = continueRunningMSLP(extmd, allParams)
	while run
		extmd.iteration += 1
		extmd.currSol = semiGreedyHeuristic(inst, allParams.general)
		if extmd.currSol.feasible
			extmd.lastSGreedySolValue = extmd.currSol.value
			extmd.currSol = Formulations.runLPFormToReScheduleSol(extmd.env, extmd.currSol, inst, allParams.general)
			extmd.lpRuns += 1

			if extmd.currSol.value < extmd.lastSGreedySolValue
				extmd.lpImpr += 1
				extmd.sumLPImprPercentage += round(
					(extmd.lastSGreedySolValue - extmd.currSol.value) / extmd.lastSGreedySolValue,
					digits = 4,
				)
			end
		else
			extmd.infeasibleSol += 1
		end

		if extmd.currSol.feasible && extmd.currSol.value + allParams.general.epsilon < extmd.bestSol.value
			updateCurrentResults!(extmd, allParams)
		end

		run = continueRunningMSLP(extmd, allParams)
	end
	# extmd.totalTimeElapsed = (CPUtime_us() - extmd.startTime)/1e6
	extmd.totalTimeElapsed = cpu_times()[1] - extmd.startTime
	println("\n[$(Dates.Time(Dates.now()))] Finished running MSLP")
end