function getCandidateListByIncreaseInCompTime(
	inst::InstanceData,
	sol::Solution,
	pJob::Int64,
	dJob::Int64,
)::Vector{InsertionData}
	candList = InsertionData[]
	for k in inst.K
		for pPos in 2:length(sol.vehicles[k])
			for dPos in pPos:length(sol.vehicles[k])
				checkInsData = checkInsertion(sol, k, pPos, dPos, pJob, dJob, inst)
				if !checkInsData.feasible
					continue
				end

				push!(candList, InsertionData(true, checkInsData.cost, pPos, dPos, pJob, dJob, k, checkInsData.possibleMachineTravels))
			end
		end
	end
	return candList
end # function getCandidateListByIncreaseInCompTime()

function semiGreedyHeuristic(inst::InstanceData, params::ParameterData)::Solution
	sol = initSolution(inst)
	nonServicedReqs = copy(getServiceOrder(inst, params))
	idxReqToServe = 1
	jumpedRequest = false
	while idxReqToServe <= length(nonServicedReqs)
		pJob = nonServicedReqs[idxReqToServe]
		dJob = pJob + inst.n

		candList = getCandidateListByIncreaseInCompTime(inst, sol, pJob, dJob)
		chosen = chooseCandidate(candList, params)

		if chosen.feasible
			sol = updateSolution(sol, chosen, inst)
		else
			jumpedRequest = true
			idxReqToServe = length(nonServicedReqs)
		end
		idxReqToServe += 1
	end

	updateMachinesIndexes(sol)

	sol.feasible = !jumpedRequest

	# if  validate_solution(inst, sol, params)
	# 	sol.feasible = true
	# else
	# 	sol.feasible = false
	# end

	return sol
end # function semiGreedyHeuristic()