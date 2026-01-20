function csvresults(
	inst::InstanceData,
	extmd::ExternalMSLPData,
	all_params::AllParams,
)
	gp = all_params.general
	stats = extmd.best_sol.stats

	new_result_data = Dict()
	for s in (inst, extmd, gp, stats, extmd.best_sol)
		for (k, v) in struct_to_key_in_dict(s)
			new_result_data[k] = v
		end
	end


	new_result_DF = DataFrame(new_result_data)
	# exclude_column_from_round = :best_cost
	for col in names(new_result_DF)
		if eltype(new_result_DF[!, col]) <: AbstractFloat #&& col != exclude_column_from_round
			new_result_DF[!, col] .= round.(new_result_DF[!, col], digits = 4)
		end
	end
	# new_result_DF.best_cost = round.(new_result_DF.best_cost, digits = 0)

	return new_result_DF

end # function csvresults