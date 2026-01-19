module GreedyHeuristicMutate

using Data
using Parameters
using Solutions
using Random

include("structures.jl")
include("init_solution.jl")
include("check_insertion.jl")
include("update_solution.jl")
include("post_processing.jl")

"""
	function flat_possible_machine_travels_chronologically(possible_machine_travels::Vector{Vector})::Vector{PossibleMachineTravel}

	Given a list of possible machine travels for each machine (possible_machine_travels),
	the function flattens the list into a single list and sorts it in chronological order
	(by start time).

	The function returns the flattened and sorted list of possible machine travels.
"""
function flat_possible_machine_travels_chronologically(possible_machine_travels::Vector{Vector})::Vector{PossibleMachineTravel}
	machine_travels = collect(Iterators.flatten(possible_machine_travels))
	sort!(machine_travels, by = i -> (i.st))

	return machine_travels
end # function flat_possible_machine_travels_chronologically()

"""
	function update_best_relax_data(
		check_ins_data::CheckInsertionData,
		best_relax_data::InsertionData,
		p_pos::Int64,
		d_pos::Int64,
		p_job::Int64,
		d_job::Int64,
		k::Int64,
		possible_machine_travels::Vector{Vector},
	)::InsertionData

	Given the results of an insertion check (check_ins_data), the current best relaxed insertion data
	(best_relax_data), the positions to insert the pickup and delivery (p_pos and d_pos), the pickup and
	delivery job indices (p_job and d_job), the vehicle index (k), and the possible machine travels already
	computed (possible_machine_travels), the function updates the best relaxed insertion data if the current
	insertion check results in a better relaxed insertion.

	The function returns the updated best relaxed insertion data.
"""
function update_best_relax_data(
	check_ins_data::CheckInsertionData,
	best_relax_data::InsertionData,
	p_pos::Int64,
	d_pos::Int64,
	p_job::Int64,
	d_job::Int64,
	k::Int64,
	possible_machine_travels::Vector{Vector}
)::InsertionData
	feasible = check_ins_data.feasible
	tw_violation = check_ins_data.tw_violation
	cap_violation = check_ins_data.cap_violation
	cost = check_ins_data.cost
	load_cost = check_ins_data.load_cost
	if tw_violation && cap_violation && cost + load_cost < best_relax_data.cost
		machine_travels = flat_possible_machine_travels_chronologically(possible_machine_travels)
		best_relax_data = InsertionData(feasible, cost + load_cost, p_pos, d_pos, p_job, d_job, k, machine_travels)
	elseif cost > 0 && cost < best_relax_data.cost
		machine_travels = flat_possible_machine_travels_chronologically(possible_machine_travels)
		best_relax_data = InsertionData(feasible, cost, p_pos, d_pos, p_job, d_job, k, machine_travels)
	elseif load_cost > 0 && load_cost < best_relax_data.cost
		machine_travels = flat_possible_machine_travels_chronologically(possible_machine_travels)
		best_relax_data = InsertionData(feasible, load_cost, p_pos, d_pos, p_job, d_job, k, machine_travels)
	end
	return best_relax_data
end # function update_best_relax_data()

"""
	function get_insertion_with_less_increase_in_comp_time(
		inst::InstanceData,
		sol::Solution,
		p_job::Int64,
		d_job::Int64,
	)::Tuple{InsertionData, InsertionData}

	Given the instance data (inst), a solution (sol), and the pickup and delivery job indices
	(p_job and d_job), the function searches for the best insertion of the pickup and delivery
	nodes in the solution, considering all vehicles and all possible positions.

	The function returns a tuple with two InsertionData structures:
	- The first structure contains the best feasible insertion found.
	- The second structure contains the best relaxed insertion found (if no feasible insertion exists).
"""
function get_insertion_with_less_increase_in_comp_time(inst::InstanceData, sol::Solution, p_job::Int64, d_job::Int64)
	best_ins_data = InsertionData(false, 0, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	best_relax_data = InsertionData(false, Inf64, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	for k in inst.K
		for p_pos in eachindex(sol.vehicles[k])[2:end]
			for d_pos in eachindex(sol.vehicles[k])[p_pos:end]
				possible_machine_travels = Vector[PossibleMachineTravel[] for _ in inst.H]
				deactivate_machine_travels(k, sol, p_pos)
				check_ins_data = check_insertion(sol, k, p_pos, d_pos, p_job, d_job, inst, possible_machine_travels)
				reactivate_machine_travels(k, sol, p_pos)
				if !check_ins_data.feasible && check_ins_data.available_vehicle
					best_relax_data = update_best_relax_data(check_ins_data, best_relax_data, p_pos, d_pos, p_job, d_job, k, possible_machine_travels)
					continue
				elseif !check_ins_data.available_vehicle
					continue
				end

				if !best_ins_data.feasible || check_ins_data.cost < best_ins_data.cost
					machine_travels = flat_possible_machine_travels_chronologically(possible_machine_travels)
					best_ins_data = InsertionData(true, check_ins_data.cost, p_pos, d_pos, p_job, d_job, k, machine_travels)
				end
			end
		end
	end
	return best_ins_data, best_relax_data
end # function get_insertion_with_less_increase_in_comp_time()

"""
	function greedy_heuristic_mutate(
		inst::InstanceData,
		params::ParameterData,
	)::Solution

	Given the instance data (inst) and the parameter data (params), the function applies
	the greedy heuristic mutation to generate a solution to the instance.

	The instance might be modified if a feasible solution is found with relaxations and
	the parameter make_instance_feasible is set to true.

	The function returns the generated solution.
"""
function greedy_heuristic_mutate(inst::InstanceData, params::ParameterData)
	sol = init_solution(inst)
	non_serviced_reqs = copy(get_service_order(inst, params))
	idx_req_to_serve = 1
	applied_relaxation = false

	while idx_req_to_serve <= length(non_serviced_reqs)
		p_job = non_serviced_reqs[idx_req_to_serve]
		d_job = p_job + inst.n

		best_ins_data, best_relax_data = get_insertion_with_less_increase_in_comp_time(inst, sol, p_job, d_job)

		if best_ins_data.feasible
			sol = update_solution(sol, best_ins_data, inst)
			idx_req_to_serve += 1
		elseif params.make_instance_feasible
			applied_relaxation = true
			sol = update_solution_with_relaxation(sol, best_relax_data, inst)
			idx_req_to_serve += 1
		else
			error("NoSolutionFound: Failed to insert the request ", p_job, " in the solution.")
		end
	end

	post_processing!(sol, inst, params, applied_relaxation)
	
	return sol

end # function greedy_heuristic_mutate()

end # module GreedyHeuristicMutate
