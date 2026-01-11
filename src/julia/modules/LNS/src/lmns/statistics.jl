using StatsBase

function calculateStats(extld::ExternalLMNSData)::Nothing
	oldTotalTimeElapsed = extld.totalTimeElapsed
	prefixes = [:total, :mean, :std, :max, :min]
	fieldsIgnore = [:objValues, :mipStatus, :psi]

	for field in fieldnames(HistoryLMNSData)
		if field in fieldsIgnore
			continue
		end
		data = getfield(extld.historyLMNSData, field)

		if !isempty(data)
			stats = [sum(data), mean(data), std(data), maximum(data), minimum(data)]
		else
			stats = [0.0, 0.0, 0.0, 0.0, Inf64]
		end

		for (prefix, value) in zip(prefixes, stats)
			stat_field = Symbol(string(prefix, uppercasefirst(string(field))))
			if stat_field == :totalNumDestroyedVars
				continue
			end
			field_type = fieldtype(typeof(extld), stat_field)
			parsed_value = convert(field_type, value)
			setfield!(extld, stat_field, parsed_value)
		end
	end

	extld.totalTimeElapsed = oldTotalTimeElapsed # I don't want to change this value
	return nothing
end

function printStats(extld::ExternalLMNSData)::Nothing

	println("\n[$(Dates.Time(Dates.now()))] Statistics:")

	@printf("\t-> Total number of iterations: %d\n", extld.totalNumIterations)
	@printf("\t-> Best solution value: %.2f\n", extld.bestSol.value)
	@printf("\t-> Time to best: %.6f\n", extld.timeToBest)
	@printf("\t-> Largest update offset: %d\n", extld.largestUpdateOffset)
	@printf("\t-> Iterations to best: %d\n", extld.iterationToBest)

	println()

	@printf("\t-> Total time elapsed: %.6f\n", extld.totalTimeElapsed)
	@printf("\t-> Mean time elapsed: %.6f\n", extld.meanTimeElapsed)
	@printf("\t-> Std time elapsed: %.6f\n", extld.stdTimeElapsed)
	@printf("\t-> Max time elapsed: %.6f\n", extld.maxTimeElapsed)
	@printf("\t-> Min time elapsed: %.6f\n", extld.minTimeElapsed)

	println()

	@printf("\t-> Total time destroy: %.6f\n", extld.totalTimeDestroy)
	@printf("\t-> Mean time destroy: %.6f\n", extld.meanTimeDestroy)
	@printf("\t-> Std time destroy: %.6f\n", extld.stdTimeDestroy)
	@printf("\t-> Max time destroy: %.6f\n", extld.maxTimeDestroy)
	@printf("\t-> Min time destroy: %.6f\n", extld.minTimeDestroy)

	println()

	@printf("\t-> Total time repair: %.6f\n", extld.totalTimeRepair)
	@printf("\t-> Mean time repair: %.6f\n", extld.meanTimeRepair)
	@printf("\t-> Std time repair: %.6f\n", extld.stdTimeRepair)
	@printf("\t-> Max time repair: %.6f\n", extld.maxTimeRepair)
	@printf("\t-> Min time repair: %.6f\n", extld.minTimeRepair)

	println()

	@printf("\t-> Mean number of destroyed variables: %.6f\n", extld.meanNumDestroyedVars)
	@printf("\t-> Std number of destroyed variables: %.6f\n", extld.stdNumDestroyedVars)
	@printf("\t-> Max number of destroyed variables: %d\n", extld.maxNumDestroyedVars)
	@printf("\t-> Min number of destroyed variables: %d\n", extld.minNumDestroyedVars)

	println()

	@printf("\t-> Total time fixing MIP solution: %.6f\n", extld.totalTimeFixingMIPSolution)
	@printf("\t-> Mean time fixing MIP solution: %.6f\n", extld.meanTimeFixingMIPSolution)
	@printf("\t-> Std time fixing MIP solution: %.6f\n", extld.stdTimeFixingMIPSolution)
	@printf("\t-> Max time fixing MIP solution: %.6f\n", extld.maxTimeFixingMIPSolution)
	@printf("\t-> Min time fixing MIP solution: %.6f\n", extld.minTimeFixingMIPSolution)

	println()

	@printf("\t-> Total time fixing solution: %.6f\n", extld.totalTimeFixingSolution)

	println()

	println("\t-> Count improvements: ", extld.countImprovements)
	println("\t-> Count improvements per operator:")
	for destroyOperator in instances(DestroyOperator)
		idop = Int(destroyOperator)
		improvs = extld.countImprovementsPerOperator[idop]
		println("\t\t-> $(string(destroyOperator)): $(improvs)")
	end
	println("\t-> Count executions per operator:")
	for destroyOperator in instances(DestroyOperator)
		idop = Int(destroyOperator)
		execs = extld.countExecutionsPerOperator[idop]
		println("\t\t-> $(string(destroyOperator)): $(execs)")
	end
	println()

	println("\t-> Count executions per operator and psi:")
	for destroyOperator in instances(DestroyOperator)
		idop = Int(destroyOperator)
		println("\t\t-> $(string(destroyOperator)):")
		for psi in keys(extld.countExecutionsPerOperatorAndPsi[idop])
			execs = get(extld.countExecutionsPerOperatorAndPsi[idop], psi, 0)
			println("\t\t\t-> psi = $(psi): $(execs)")
		end
	end
	println()

	println("\t-> Tabu list per operator and psi:")
	for destroyOperator in instances(DestroyOperator)
		idop = Int(destroyOperator)
		println("\t\t-> $(string(destroyOperator)):")
		for psi in keys(extld.tabuList[idop])
			execs = length(get(extld.tabuList[idop], psi, Int64[]))
			println("\t\t\t-> psi = $(psi): $(execs)")
		end
	end
	println()

	println("\t-> Count Map MIP status:")
	counts = countmap(extld.historyLMNSData.mipStatus)
	for (k, v) in counts
		println("\t\t-> $k => $v")
	end


	println()

	println("\t-> Proved optimality: ", extld.provedOptimality)

	println()
	return nothing
end
