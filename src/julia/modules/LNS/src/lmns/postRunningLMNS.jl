function postRunningLMNS!(inst::InstanceData, extld::ExternalLMNSData, allParams::AllParams)::Nothing
	calculateStats(extld)
	printStats(extld)

	statsSolution = Solutions.save_stats_solution(inst, extld.bestSol, allParams.general)
	extld.bestSol.stats = statsSolution

	if allParams.stop.rule != TARGET
		println("[$(Dates.Time(Dates.now()))] Writing results to CSV file: ", allParams.general.csvfilename)
		csvrow = csvresults(inst, extld, allParams)
		CSVUtils.write_csv_with_flock(allParams.general.csvfilename, csvrow)

		saveSolutionToFile(extld.bestSol, inst, allParams.general)
		saveSolutionTimeline(extld.bestSol, inst, allParams.general)
	end

	return nothing
end # function postRunningLMNS()
