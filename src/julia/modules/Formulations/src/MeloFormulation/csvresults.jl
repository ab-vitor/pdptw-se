function csvresults(
	sol::Solution,
	mipSol::MIPSolution,
	inst::InstanceData,
	params::ParameterData,
)::DataFrame

	exclude_fields_i = Set([
		:vehicles,
		:vehicle_types,
		:jobs,
		:machines,
		:refs,
		:V,
		:V_p,
		:V_d,
		:V_p_d,
		:Vprime,
		:e,
		:l,
		:eprime,
		:lprime,
		:q,
		:K,
		:Q,
		:d,
		:dmax_vehicle,
		:dmin_vehicle,
		:A,
		:A_m,
		:A_s,
		:H,
		:H_e,
		:d_bar,
		:d_bar_min,
		:d_bar_max,
		:f,
		:O,
		:s,
		:M,
		:L_K,
		:L_H,
		:F_h,
		:S_h,
		:Sprime_h,
		:ppd,
	])

	exclude_fields_params = Set([])

	exclude_fields_sol = Set([
		:vehicles,
		:machines,
		:completionTimes,
		:stats,
		:value,
	])

	exclude_fields_sol_stats = Set([
		:machines_travel_times_with_vehicle,
		:machines_travel_times_no_vehicle,
		:max_load_vehicle,
	])

	newResultData = merge(
		structToKeyInDict(inst;),
		structToKeyInDict(params),
		structToKeyInDict(sol),
		structToKeyInDict(sol.stats),
		structToKeyInDict(mipSol.stats),
	)	

	newResultDF = DataFrame(newResultData)
	# exclude_column_from_round = :best_cost
	for col in names(newResultDF)
		if eltype(newResultDF[!, col]) <: AbstractFloat #&& col != exclude_column_from_round
			newResultDF[!, col] .= round.(newResultDF[!, col], digits = 2)
		end
	end
	# newResultDF.best_cost = round.(newResultDF.best_cost, digits = 0)

	return newResultDF
end # function csvresults()


function csvresults(
	inst::InstanceData,
	params::ParameterData,
)::DataFrame
	exclude_fields_i = Set([
		:vehicles,
		:vehicle_types,
		:jobs,
		:machines,
		:refs,
		:V,
		:V_p,
		:V_d,
		:V_p_d,
		:Vprime,
		:q,
		:K,
		:Q,
		:d,
		:A,
		:A_m,
		:A_s,
		:H,
		:H_e,
		:d_bar,
		:f,
		:O,
		:s,
		:M,
		:L_K,
		:L_H,
		:F_h,
		:S_h,
		:Sprime_h,
	])

	exclude_fields_params = Set([])

	exclude_fields_sol = Set([
		:vehicles,
		:machines,
		:completionTimes,
		:stats,
		:value,
	])

	exclude_fields_sol_stats = Set([
		:machines_travel_times_with_vehicle,
		:machines_travel_times_no_vehicle,
		:max_load_vehicle,
	])

	newResultData = merge(
		structToKeyInDict(inst; exclude_fields = exclude_fields_i),
		structToKeyInDict(params; exclude_fields = exclude_fields_params),
		structToKeyInDict(sol; exclude_fields = exclude_fields_sol),
		structToKeyInDict(sol.stats; exclude_fields = exclude_fields_sol_stats),
		structToKeyInDict(mipSol.stats),
	)

	newResultDF = DataFrame(newResultData)
	# exclude_column_from_round = :best_cost
	for col in names(newResultDF)
		if eltype(newResultDF[!, col]) <: AbstractFloat #&& col != exclude_column_from_round
			newResultDF[!, col] .= round.(newResultDF[!, col], digits = 2)
		end
	end
	# newResultDF.best_cost = round.(newResultDF.best_cost, digits = 0)

	return newResultDF
end # function write_reduced_output
