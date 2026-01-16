function getCandidateListByIncreaseInCompTime(
	inst::InstanceData,
	sol::Solution,
	pJob::Int64,
	d_job::Int64,
)::Vector{InsertionData}
	cand_list = InsertionData[]
	for k in inst.K
		for p_pos in 2:length(sol.vehicles[k])
			for dPos in p_pos:length(sol.vehicles[k])
				check_ins_data = checkInsertion(sol, k, p_pos, dPos, pJob, d_job, inst)
				if !check_ins_data.feasible
					continue
				end

				push!(cand_list, InsertionData(true, check_ins_data.cost, p_pos, dPos, pJob, d_job, k, check_ins_data.possibleMachineTravels))
			end
		end
	end
	return cand_list
end # function getCandidateListByIncreaseInCompTime()

function semiGreedyHeuristic(inst::InstanceData, params::ParameterData)::Solution
	sol = initSolution(inst)
	nonServicedReqs = copy(getServiceOrder(inst, params))
	idxReqToServe = 1
	jumpedRequest = false
	while idxReqToServe <= length(nonServicedReqs)
		pJob = nonServicedReqs[idxReqToServe]
		d_job = pJob + inst.n

		cand_list = getCandidateListByIncreaseInCompTime(inst, sol, pJob, d_job)
		chosen = choose_candidate(cand_list, params)

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