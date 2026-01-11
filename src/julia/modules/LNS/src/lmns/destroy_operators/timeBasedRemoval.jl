function timeBasedRemoval!(extld::ExternalLMNSData, inst::InstanceData, allParams::AllParams)::Nothing
	idop = Int(extld.destroyOperator)
	psi = extld.psi[idop]
	mipModel = extld.mipModel
	ddp = allParams.dgd

	println("-----------## Performing time-based removals | psi = $(psi) ##------------")
	
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
		timeValues = Tuple{Float64, Int64, Int64}[]
		for jidx in eachindex(jobsToAnalyze)
			j = jobsToAnalyze[jidx]
			# timeDiff = abs(inst.e[i] - inst.e[j])
			timeDiff = abs(value(extld.mipSol.vars.t[i]) - value(extld.mipSol.vars.t[j]))
			push!(timeValues, (timeDiff, j, jidx))
		end
		idxArgMin = argmin(timeValues)
		timeValue, j, jidx = timeValues[idxArgMin]
		splice!(jobsToAnalyze, jidx)
		push!(jobsToRemove, j)
	end

	numDestroyedVars = Ref{Int64}(0)
	println("\t-> Removing vars related to inst.depot_begin -> inst.depot_end")
	removeVarsVehicleDepotToDepot!(extld, inst, numDestroyedVars)
	println("\t-> Removing vars related to jobs: $(jobsToRemove) length = $(length(jobsToRemove))")
	removeVarsRelatedToJobs!(jobsToRemove, extld, inst, numDestroyedVars)
	# removeMachineVars!(extld, inst, numDestroyedVars)
	# removeVehicleVarsRelatedToJobs!(jobsToRemove, extld, inst, numDestroyedVars)
	
	push!(extld.historyLMNSData.numDestroyedVars, numDestroyedVars[])
	
	printStatusVars(mipModel, numDestroyedVars)

	return nothing
end
