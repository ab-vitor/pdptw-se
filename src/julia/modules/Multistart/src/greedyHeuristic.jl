function getInsertionWithLessIncreaseInCompTime(
	inst::InstanceData,
	sol::Solution,
	pJob::Int64,
	dJob::Int64,
)::InsertionData
	bestInsData = InsertionData(false, Inf64, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	for k in inst.K
		for pPos in 2:length(sol.vehicles[k])
			for dPos in pPos:length(sol.vehicles[k])
				checkInsData = checkInsertion(sol, k, pPos, dPos, pJob, dJob, inst)
				if checkInsData.feasible
					if checkInsData.cost < bestInsData.cost
						bestInsData = InsertionData(
							checkInsData.feasible,
							checkInsData.cost,
							pPos,
							dPos,
							pJob,
							dJob,
							k,
							checkInsData.possibleMachineTravels,
						)
					end
				end
			end
		end
	end
	return bestInsData
end # function getInsertionWithLessIncreaseInCompTime()

function greedyHeuristic(inst::InstanceData, params::ParameterData)::Solution
	sol = initSolution(inst)
	nonServicedReqs = copy(tightestTimeWindows(inst))
	idxReqToServe = 1
	reqNotInserted = false
	while idxReqToServe <= length(nonServicedReqs)
		pJob = nonServicedReqs[idxReqToServe]
		dJob = pJob + inst.n

		bestInsData = getInsertionWithLessIncreaseInCompTime(inst, sol, pJob, dJob)

		if bestInsData.feasible
			sol = updateSolution(sol, bestInsData, inst)
		else
			reqNotInserted = true
			idxReqToServe = length(nonServicedReqs)
		end
		idxReqToServe += 1
	end

	updateMachinesIndexes(sol)

	sol.feasible = !reqNotInserted

	# printDetailMeloFormulationSolution(inst, sol)
	# if validate_solution(inst, sol, params)
	# 	sol.feasible = true
	# else
	# 	sol.feasible = false
	# end
	return sol
end # function greedyHeuristic()
