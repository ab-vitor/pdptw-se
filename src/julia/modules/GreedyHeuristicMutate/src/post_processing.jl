"""
	function remove_dummy_objects!(sol::Solution, inst::InstanceData)::Nothing

	Given a solution (sol) and the instance data (inst), the function removes the dummy
	objects added during the initialization of the solution.
"""
function remove_dummy_objects!(sol::Solution, inst::InstanceData)
	for h in inst.H
		popfirst!(sol.machines[h])
		pop!(sol.machines[h])
	end

	for k in inst.K
		for i in 1:length(sol.vehicles[k])
			if sol.vehicles[k][i].mach != 0
				sol.vehicles[k][i].mach_index -= 1
			end
		end
	end
end # function remove_dummy_objects!()

"""
    function post_processing!(sol::Solution, inst::InstanceData, params::ParameterData, applied_relaxation::Bool)::Nothing

    Performs post-processing on the solution after the greedy heuristic has been applied.
    Removes dummy objects, calculates completion times, evaluates solution feasibility,
    prints the timeline and solution value, and updates the instance data if necessary.

    # Arguments
    - `sol::Solution`: The solution object to be processed.
    - `inst::InstanceData`: The instance data associated with the solution.
    - `params::ParameterData`: The parameters used in the heuristic.
    - `applied_relaxation::Bool`: Indicates if relaxation was applied during the heuristic.

    # Returns
    - `Nothing`: The function modifies the solution in place.
"""
function post_processing!(sol::Solution, inst::InstanceData, params::ParameterData, applied_relaxation::Bool)::Nothing
    remove_dummy_objects!(sol, inst)

	sol.completion_times = Float64[rt[length(rt)].serv_start_time for rt in sol.vehicles]
	sol.value = sum(sol.completion_times)
	print_timeline_solution(inst, sol)
	println(inst.name, ": ", sol.value)
	if validate_solution(inst, sol, params)
		sol.feasible = true
		println("Feasible solution! :D")
		if params.make_instance_feasible && params.method_code == "greedy"
			if applied_relaxation
				println("Updating instance...")
			end
			instance_data_to_csv_files(inst, params, "g")
		end
	else
		sol.feasible = false
		println("Infeasible solution! :(")
	end
    return nothing
end