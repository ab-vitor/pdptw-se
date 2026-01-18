function post_running_MSLP!(inst::InstanceData, extmd::ExternalMSLPData, all_params::AllParams)::Nothing
	calculate_stats(extmd)
	print_stats(extmd)

	solution_stats = Solutions.save_solution_stats(inst, extmd.best_sol, all_params.general)
	extmd.best_sol.stats = solution_stats

	if all_params.stop.rule != TARGET
		println("[$(Dates.Time(Dates.now()))] Writing results to CSV file: ", all_params.general.csv_file_name)
		csvrow = csvresults(inst, extmd, all_params)
		CSVUtils.write_csv_with_flock(all_params.general.csv_file_name, csvrow)

		save_summarized_solution(extmd.best_sol, inst, all_params.general)
		save_solution_timeline(extmd.best_sol, inst, all_params.general)
	end

	return nothing
end
