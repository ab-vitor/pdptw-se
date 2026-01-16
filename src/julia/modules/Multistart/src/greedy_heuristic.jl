function getInsertionWithLessIncreaseInCompTime(
	inst::InstanceData,
	sol::Solution,
	p_job::Int64,
	d_job::Int64,
)::InsertionData
	best_ins_data = InsertionData(false, Inf64, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	for k in inst.K
		for p_pos in 2:length(sol.vehicles[k])
			for d_pos in p_pos:length(sol.vehicles[k])
				check_ins_data = checkInsertion(sol, k, p_pos, d_pos, p_job, d_job, inst)
				if check_ins_data.feasible
					if check_ins_data.cost < best_ins_data.cost
						best_ins_data = InsertionData(
							check_ins_data.feasible,
							check_ins_data.cost,
							p_pos,
							d_pos,
							p_job,
							d_job,
							k,
							check_ins_data.possibleMachineTravels,
						)
					end
				end
			end
		end
	end
	return best_ins_data
end # function getInsertionWithLessIncreaseInCompTime()

function greedyHeuristic(inst::InstanceData, params::ParameterData)::Solution
	sol = initSolution(inst)
	nonServicedReqs = copy(tightestTimeWindows(inst))
	idxReqToServe = 1
	reqNotInserted = false
	while idxReqToServe <= length(nonServicedReqs)
		p_job = nonServicedReqs[idxReqToServe]
		d_job = p_job + inst.n

		best_ins_data = getInsertionWithLessIncreaseInCompTime(inst, sol, p_job, d_job)

		if best_ins_data.feasible
			sol = updateSolution(sol, best_ins_data, inst)
		else
			reqNotInserted = true
			idxReqToServe = length(nonServicedReqs)
		end
		idxReqToServe += 1
	end

	updateMachinesIndexes(sol)

	sol.feasible = !reqNotInserted

	# print_timeline_solution(inst, sol)
	# if validate_solution(inst, sol, params)
	# 	sol.feasible = true
	# else
	# 	sol.feasible = false
	# end
	return sol
end # function greedyHeuristic()
