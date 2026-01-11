function proximityBasedRemoval!(extld::ExternalLMNSData, inst::InstanceData, allParams::AllParams)::Nothing
	idop = Int(extld.destroyOperator)
	psi = extld.psi[idop]
	mipModel = extld.mipModel
	ddp = allParams.dgd
	
	println("-----------## Performing proximity-based removal | psi = $(psi) ##------------")

	tabuListPsi = get(extld.tabuList[idop], psi, [])
	options = setdiff(inst.V_p_d, tabuListPsi)
	if length(options) == 0
		updateDegreeOfDestruction!(extld, allParams)
		return nothing
	end
	idx = rand(ddp.rng, 1:length(options))
	i = options[idx]

	if !haskey(extld.tabuList[idop], psi)
		extld.tabuList[idop][psi] = Vector{Int64}[]
	end
	push!(extld.tabuList[idop][psi], i)
	println(extld.tabuList[idop])

	if !haskey(extld.countExecutionsPerOperatorAndPsi[idop], psi)
		extld.countExecutionsPerOperatorAndPsi[idop][psi] = 0
	end
	extld.countExecutionsPerOperatorAndPsi[idop][psi] += 1
	
	jobsToRemove = Int64[i]
	jobsToAnalyze = copy(inst.V_p_d)
	splice!(jobsToAnalyze, idx)

	for _ in 1:psi-1
		i = jobsToRemove[end]
		jobsProxValue = Tuple{Float64, Int64, Int64}[]
		for jidx in eachindex(jobsToAnalyze)
			j = jobsToAnalyze[jidx]
			dist = inst.dmax_vehicle[i, j]
			proxValue = dist
			push!(jobsProxValue, (proxValue, j, jidx))
		end
		proxValue, j, jidx = jobsProxValue[argmin(jobsProxValue)]
		splice!(jobsToAnalyze, jidx)
		push!(jobsToRemove, j)
	end

	numDestroyedVars = Ref{Int64}(0)
	println("\t-> Removing vars related to inst.depot_begin -> inst.depot_end")
	removeVarsVehicleDepotToDepot!(extld, inst, numDestroyedVars)
	println("\t-> Removing vars related to jobs: $(jobsToRemove) length = $(length(jobsToRemove))")
	removeVarsRelatedToJobs!(jobsToRemove, extld, inst, numDestroyedVars)

	push!(extld.historyLMNSData.numDestroyedVars, numDestroyedVars[])

	printStatusVars(mipModel, numDestroyedVars)
	return nothing
end
