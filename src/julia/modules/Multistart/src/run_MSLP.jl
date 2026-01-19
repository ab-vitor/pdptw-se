"""
	function continue_running_MSLP(extmd::ExternalMSLPData, all_params::AllParams)::Bool

	Determine whether the Multi-Start Local Search Procedure (MSLP) should continue running
	based on the stopping criteria defined in `all_params`.

	# Arguments
	- `extmd::ExternalMSLPData`: The external MSLP data containing the current state of the algorithm.
	- `all_params::AllParams`: The parameters defining the stopping criteria.

	# Returns
	- `Bool`: `true` if MSLP should continue running, `false` otherwise.
"""
function continue_running_MSLP(extmd::ExternalMSLPData, all_params::AllParams)::Bool
	current_time_elapsed = cpu_times()[1] - extmd.start_time
	return !(
		current_time_elapsed >= all_params.stop.maximum_time ||
		(all_params.stop.rule == ITERATIONS && extmd.iteration >= all_params.stop.argument) ||
		(all_params.stop.rule == FEASIBILITY && extmd.best_sol.feasible) ||
		(all_params.stop.rule == MAXTIME && current_time_elapsed >= all_params.stop.argument) ||
		(all_params.stop.rule == TARGET && extmd.best_sol.value <= all_params.stop.argument + all_params.general.epsilon)
	)
end

"""
	function run_MSLP!(inst::InstanceData, extmd::ExternalMSLPData, all_params::AllParams)

	Run the Multi-Start Local Search Procedure (MSLP) on the given instance data `inst`,
	using the external MSLP data `extmd` and the parameters specified in `all_params`.
	Updates the `extmd` with the best solution found and various statistics during the run.
"""
function run_MSLP!(inst::InstanceData, extmd::ExternalMSLPData, all_params::AllParams)::Nothing
	println("obj_value;greedysol;iteration;time")
	extmd.curr_sol = greedy_heuristic(inst)

	if extmd.curr_sol.feasible
		extmd.last_greedy_sol_value = extmd.curr_sol.value
		extmd.curr_sol = Formulations.run_LP_to_reschedule_solution(extmd.env, extmd.curr_sol, inst, all_params.general)
		extmd.LP_runs += 1

		if extmd.curr_sol.feasible && extmd.curr_sol.value < extmd.last_greedy_sol_value
			extmd.LP_impr += 1
			extmd.sum_LP_impr_percentage += round(
				(extmd.last_greedy_sol_value - extmd.curr_sol.value) / extmd.last_greedy_sol_value,
				digits = 4,
			)
		end
		if extmd.curr_sol.feasible
			update_current_results!(extmd)
		else
			extmd.best_sol = extmd.curr_sol
			extmd.best_sol.value = Inf64
		end
	else
		extmd.infeasible_sol += 1
		extmd.best_sol = extmd.curr_sol
		extmd.best_sol.value = Inf64
	end

	run = continue_running_MSLP(extmd, all_params)
	while run
		extmd.iteration += 1
		extmd.curr_sol = semi_greedy_heuristic(inst, all_params.general)
		if extmd.curr_sol.feasible
			extmd.last_greedy_sol_value = extmd.curr_sol.value
			extmd.curr_sol = Formulations.run_LP_to_reschedule_solution(extmd.env, extmd.curr_sol, inst, all_params.general)
			extmd.LP_runs += 1

			if extmd.curr_sol.value < extmd.last_greedy_sol_value
				extmd.LP_impr += 1
				extmd.sum_LP_impr_percentage += round(
					(extmd.last_greedy_sol_value - extmd.curr_sol.value) / extmd.last_greedy_sol_value,
					digits = 4,
				)
			end
		else
			extmd.infeasible_sol += 1
		end

		if extmd.curr_sol.feasible && extmd.curr_sol.value + all_params.general.epsilon < extmd.best_sol.value
			update_current_results!(extmd)
		end

		run = continue_running_MSLP(extmd, all_params)
	end
	extmd.total_time_elapsed = cpu_times()[1] - extmd.start_time
	println("\n[$(Dates.Time(Dates.now()))] Finished running MSLP")
end