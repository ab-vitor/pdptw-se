function update_current_results!(extmd::ExternalMSLPData)::Nothing
	extmd.time_to_best = cpu_times()[1] - extmd.start_time
	extmd.iteration_to_best = extmd.iteration
	extmd.best_sol = extmd.curr_sol
	update_offset = extmd.iteration - extmd.iteration_to_best
	extmd.largest_update_offset = max(extmd.largest_update_offset, update_offset)
	extmd.count_improvements += 1

	@printf(
		"%.2f;%.2f;%d;%.6f\n",
		extmd.best_sol.value,
		extmd.last_greedy_sol_value,
		extmd.iteration,
		extmd.time_to_best
	)
    return nothing
end
