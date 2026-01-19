"""
	function get_candidate_list_by_increase_in_comp_time(
		inst::InstanceData,
		sol::Solution,
		p_job::Int64,
		d_job::Int64,
	)::Vector{InsertionData}

	Generate a list of all feasible insertion candidates for the pickup job `p_job` and delivery job `d_job`
	into the current solution `sol` for the given instance data `inst`. Each candidate is represented 
	by an `InsertionData` object.
"""
function get_candidate_list_by_increase_in_comp_time(
	inst::InstanceData,
	sol::Solution,
	p_job::Int64,
	d_job::Int64,
)::Vector{InsertionData}
	cand_list = InsertionData[]
	for k in inst.K
		for p_pos in eachindex(sol.vehicles[k])[2:end]
			for d_pos in eachindex(sol.vehicles[k])[p_pos:end]
				check_ins_data = check_insertion(sol, k, p_pos, d_pos, p_job, d_job, inst)
				if !check_ins_data.feasible
					continue
				end

				push!(cand_list, InsertionData(true, check_ins_data.cost, p_pos, d_pos, p_job, d_job, k, check_ins_data.possible_machine_travels))
			end
		end
	end
	return cand_list
end # function get_candidate_list_by_increase_in_comp_time()

"""
	function semi_greedy_heuristic(inst::InstanceData, params::ParameterData)

	Construct a solution for the given instance data `inst` using a semi-greedy heuristic
	approach based on the parameters specified in `params`.

	Returns a `Solution` object representing the constructed solution.
"""
function semi_greedy_heuristic(inst::InstanceData, params::ParameterData)::Solution
	sol = init_solution(inst)
	non_serviced_reqs = copy(get_service_order(inst, params))
	idx_req_to_serve = 1
	req_not_inserted = false
	while idx_req_to_serve <= length(non_serviced_reqs) && !req_not_inserted
		p_job = non_serviced_reqs[idx_req_to_serve]
		d_job = p_job + inst.n

		cand_list = get_candidate_list_by_increase_in_comp_time(inst, sol, p_job, d_job)
		chosen = choose_candidate(cand_list, params)

		if chosen.feasible
			sol = update_solution(sol, chosen, inst)
		else
			req_not_inserted = true
		end
		idx_req_to_serve += 1
	end

	update_machines_indexes(sol)

	sol.feasible = !req_not_inserted

	return sol
end # function semi_greedy_heuristic()