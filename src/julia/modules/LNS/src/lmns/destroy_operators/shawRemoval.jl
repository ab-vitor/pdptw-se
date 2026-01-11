function shawRemoval!(extld::ExternalLMNSData, inst::InstanceData, allParams::AllParams)::Nothing
	idop = Int(extld.destroyOperator)
	psi = extld.psi[idop]
	mipModel = extld.mipModel
	sp = allParams.shaw
	ddp = allParams.dgd

	println("-----------## Performing shaw removals | psi = $(psi) ##------------")
	
	l = Int16[]
	isSameRouteApplied = sp.weightSameRoute > ddp.epsilon
	if isSameRouteApplied
		l = ones(Int16, (length(inst.Vprime), length(inst.Vprime)))
		vehicles = createVehicles(inst, mipModel)
		for k in inst.K, i in eachindex(vehicles[k])[1:end-1], j in eachindex(vehicles[k])[i+1:end]
			nodei = vehicles[k][i]
			nodej = vehicles[k][j]
			l[nodei, nodej] = -1
		end
	end

	# Normalize shaw's component values
	# endPlanning = 1
	# maxDem = 1
	# maxDist = 1
	endPlanning = inst.l[inst.depot_begin]
	maxDem = inst.max_q
	maxDist = inst.max_d

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
	filter!(x -> x != i, jobsToAnalyze)

	for _ in 1:psi-1
		i = jobsToRemove[end]
		jobShawValues = Tuple{Float64, Int64, Int64}[]
		for jidx in eachindex(jobsToAnalyze)
			j = jobsToAnalyze[jidx]
			dist = maximum(inst.d[i, j, :]) / maxDist
			earl = abs(inst.e[i] - inst.e[j]) / endPlanning
			sameRoute = isSameRouteApplied ? l[i, j] : 0
			dem = abs(inst.q[i] - inst.q[j]) / maxDem

			shawValue = sp.weightDistProx * dist
			shawValue += sp.weightEarlProx * earl
			shawValue += sp.weightSameRoute * sameRoute
			shawValue += sp.weightDemandSim * dem
			push!(jobShawValues, (shawValue, j, jidx))
		end
		idxArgMin = argmin(jobShawValues)
		shawValue, j, jidx = jobShawValues[idxArgMin]
		splice!(jobsToAnalyze, jidx)
		push!(jobsToRemove, j)
	end

	numDestroyedVars = Ref{Int64}(0)
	println("\t-> Removing vars related to depot_begin -> depot_end")
	removeVarsVehicleDepotToDepot!(extld, inst, numDestroyedVars)
	println("\t-> Removing vars related to jobs: $(jobsToRemove) length = $(length(jobsToRemove))")
	removeVarsRelatedToJobs!(jobsToRemove, extld, inst, numDestroyedVars)

	push!(extld.historyLMNSData.numDestroyedVars, numDestroyedVars[])

	printStatusVars(mipModel, numDestroyedVars)

	return nothing
end
