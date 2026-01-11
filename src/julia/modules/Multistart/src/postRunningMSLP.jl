function postRunningMSLP!(inst::InstanceData, extmd::ExternalMSLPData, allParams::AllParams)::Nothing
	calculateStats(extmd)
	printStats(extmd)

	statsSolution = Solutions.save_stats_solution(inst, extmd.bestSol, allParams.general)
	extmd.bestSol.stats = statsSolution

	if allParams.stop.rule != TARGET
		println("[$(Dates.Time(Dates.now()))] Writing results to CSV file: ", allParams.general.csvfilename)
		csvrow = csvresults(inst, extmd, allParams)
		CSVUtils.write_csv_with_flock(allParams.general.csvfilename, csvrow)

		saveSolutionToFile(extmd.bestSol, inst, allParams.general)
		saveSolutionTimeline(extmd.bestSol, inst, allParams.general)
	end

	return nothing
end
