function print_stats(extmd::ExternalMSLPData)::Nothing
	@printf("Best solution value: %.2f\n", extmd.best_sol.value)
	@printf("Total time elapsed: %.6f\n", extmd.total_time_elapsed)
	@printf("Time to best: %.6f\n", extmd.time_to_best)
	@printf("Iterations: %d\n", extmd.iteration)
	@printf("Iterations to best: %d\n", extmd.iteration_to_best)
	@printf("Improvements: %d\n", extmd.count_improvements)
	@printf("Infeasible solutions percentage: (%d / %d) = %.4f %%\n", extmd.infeasible_sol, extmd.iteration, extmd.percentage_infeasible_sol)
	@printf("(LP improvements)/(LP runs) = %d/%d = %.4f %%\n", extmd.LP_impr, extmd.LP_runs, extmd.percentage_LP_impr)
	@printf("Mean LP improvement percentage: %.4f %%\n", extmd.mean_LP_impr_percentage)

	return nothing
end

function calculate_stats(extmd::ExternalMSLPData)::Nothing
	extmd.percentage_infeasible_sol = round(extmd.infeasible_sol / (extmd.iteration) * 100, digits = 4)
	extmd.percentage_LP_impr = round(extmd.LP_impr / max(1, extmd.LP_runs) * 100, digits = 4)
	extmd.mean_LP_impr_percentage = round(extmd.sum_LP_impr_percentage / max(1, extmd.LP_runs) * 100, digits = 4)
	return nothing
end
