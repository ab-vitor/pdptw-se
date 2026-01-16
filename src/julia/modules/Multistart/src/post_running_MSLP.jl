function post_running_MSLP!(inst::InstanceData, extmd::ExternalMSLPData, allParams::AllParams)::Nothing
	calculate_stats(extmd)
	print_stats(extmd)

	solution_stats = Solutions.save_solution_stats(inst, extmd.bestSol, allParams.general)
	extmd.bestSol.stats = solution_stats

	if allParams.stop.rule != TARGET
		println("[$(Dates.Time(Dates.now()))] Writing results to CSV file: ", allParams.general.csvfilename)
		csvrow = csvresults(inst, extmd, allParams)
		CSVUtils.write_csv_with_flock(allParams.general.csvfilename, csvrow)

		save_summarized_solution(extmd.bestSol, inst, allParams.general)
		save_solution_timeline(extmd.bestSol, inst, allParams.general)
	end

	return nothing
end
