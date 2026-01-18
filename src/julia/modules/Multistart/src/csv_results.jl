function csvresults(
	inst::InstanceData,
	extmd::ExternalMSLPData,
	all_params::AllParams,
)
	gp = all_params.general
	stats = extmd.best_sol.stats

	newResultData = Dict()
	for s in (inst, extmd, gp, stats, extmd.best_sol)
		for (k, v) in structToKeyInDict(s)
			newResultData[k] = v
		end
	end


	newResultDF = DataFrame(newResultData)
	# exclude_column_from_round = :best_cost
	for col in names(newResultDF)
		if eltype(newResultDF[!, col]) <: AbstractFloat #&& col != exclude_column_from_round
			newResultDF[!, col] .= round.(newResultDF[!, col], digits = 4)
		end
	end
	# newResultDF.best_cost = round.(newResultDF.best_cost, digits = 0)

	return newResultDF

end # function csvresults