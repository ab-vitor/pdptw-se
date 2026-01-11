function parseField(field::Any)::Any
    if typeof(field) == Enum
        return string(field)
    end
    return field
end

function structToKeyInDict(s; exclude_fields = Set())
	return Dict(
		field => (
			parseField(getfield(s, field))
		)
		for field in fieldnames(typeof(s)) if !(field in exclude_fields)
	)
end

function csvresults(
	inst::InstanceData,
	extld::ExternalLMNSData,
    allParams::AllParams,
)
	gp = allParams.general

	exclude_fields_gp = Set([
		:maxtime,
		:printsol,
		:maxnodes,
		:output,
	])

	exclude_fields_extld = Set([
		:startTime,
        :env,
        :bestSol,
		:mipModel,
		:mipSol,
		:mipSolT,
		:mipSolB,
		:psi,
		:delta,
		:destroyOptions,
		:destroyOperator,
		:destroyOperatorFunction!,
		:countImprovementsPerOperator,
		:countExecutionsPerOperator,
		:countExecutionsPerOperatorAndPsi,
		:historyLMNSData,
		:tabuList,
	])

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
		:dmax_vehicle,
		:dmin_vehicle,
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
		:ppd,
	])

    stats = extld.bestSol.stats

	exclude_fields_stats = Set([
		:machines_travel_times_with_vehicle,
		:machines_travel_times_no_vehicle,
		:max_load_vehicle,
	])

	exclude_fields_sol = Set([
		:vehicles,
		:machines,
		:completionTimes,
		:stats
	])

	newResultData = merge(
		structToKeyInDict(inst; exclude_fields=exclude_fields_i),
		structToKeyInDict(extld; exclude_fields=exclude_fields_extld),
		structToKeyInDict(gp; exclude_fields=exclude_fields_gp),
		structToKeyInDict(stats; exclude_fields=exclude_fields_stats),
		structToKeyInDict(extld.bestSol; exclude_fields=exclude_fields_sol),
	)


	newResultDF = DataFrame(newResultData)
	# exclude_column_from_round = :best_cost
	for col in names(newResultDF)
		if eltype(newResultDF[!, col]) <: AbstractFloat #&& col != exclude_column_from_round
			newResultDF[!, col] .= round.(newResultDF[!, col], digits=2)
		end
	end
	# newResultDF.best_cost = round.(newResultDF.best_cost, digits = 0)

	return newResultDF

end # function csvresults