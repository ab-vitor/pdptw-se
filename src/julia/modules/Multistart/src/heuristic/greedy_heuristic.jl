"""
	function get_insertion_with_less_increase_in_comp_time(
		inst::InstanceData,
		sol::Solution,
		p_job::Int64,
		d_job::Int64,
	)::InsertionData

	Find the best feasible insertion for the pickup job `p_job` and delivery job `d_job`
	into the current solution `sol` for the given instance data `inst`,
	that results in the least increase in completion time.
"""
function get_insertion_with_less_increase_in_comp_time(
	inst::InstanceData,
	sol::Solution,
	p_job::Int64,
	d_job::Int64,
)::InsertionData
	best_ins_data = InsertionData(false, Inf64, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	for k in inst.K
		for p_pos in eachindex(sol.vehicles[k])[2:end]
			for d_pos in eachindex(sol.vehicles[k])[p_pos:end]
				check_ins_data = check_insertion(sol, k, p_pos, d_pos, p_job, d_job, inst)
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
							check_ins_data.possible_machine_travels,
						)
					end
				end
			end
		end
	end
	return best_ins_data
end # function get_insertion_with_less_increase_in_comp_time()

"""
	function greedy_heuristic(inst::InstanceData)::Solution

	Construct a solution for the given instance data `inst` using a greedy heuristic
	approach that inserts requests based on the tightest time windows first.

	Returns a `Solution` object representing the constructed solution.
"""
function greedy_heuristic(inst::InstanceData)::Solution
	sol = init_solution(inst)
	non_serviced_reqs = copy(tightest_time_windows(inst))
	idx_req_to_serve = 1
	req_not_inserted = false
	while idx_req_to_serve <= length(non_serviced_reqs) && !req_not_inserted
		p_job = non_serviced_reqs[idx_req_to_serve]
		d_job = p_job + inst.n

		best_ins_data = get_insertion_with_less_increase_in_comp_time(inst, sol, p_job, d_job)

		if best_ins_data.feasible
			sol = update_solution(sol, best_ins_data, inst)
		else
			req_not_inserted = true
		end
		idx_req_to_serve += 1
	end

	update_machines_indexes(sol)

	sol.feasible = !req_not_inserted

	return sol
end # function greedy_heuristic()
