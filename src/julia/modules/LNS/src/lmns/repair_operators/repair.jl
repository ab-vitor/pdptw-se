function getRemainingTime(extld::ExternalLMNSData, allParams::AllParams)::Float64
	if allParams.stop.rule == MAXTIME
		return allParams.stop.argument - (time() - extld.startTime)
	end
	return allParams.stop.maximum_time - (time() - extld.startTime)
end # function getRemainingTime()

function repair!(extld::ExternalLMNSData, allParams::AllParams)::Union{MIPSolution, Nothing}
	println("Repairing the solution")
	mipModel = extld.mipModel

	set_attribute(mipModel.model, "TimeLimit", Inf64)
	remainingTime = max(0, floor(getRemainingTime(extld, allParams)))
	timeLimitModel = min(allParams.general.lmnsRepairTime, remainingTime)
	println("Time limit of the model: $(timeLimitModel)")
	# set_attribute(mipModel.model, "ImproveStartTime", 4*timeLimitModel/5)
	foundSol = false
	function stop_criterion(cb_data, cb_where::Cint)
		if cb_where == GRB_CB_MIPSOL && !foundSol
			foundSol = true
			println("Found solution. Setting time limit to: ", timeLimitModel)
			GRBcbsetdblparam(cb_data, GRB_DBL_PAR_TIMELIMIT, timeLimitModel)
		end
	end
	MOI.set(mipModel.model, Gurobi.CallbackFunction(), stop_criterion)

	optimize!(mipModel.model)

	status = termination_status(mipModel.model)
	push!(extld.historyLMNSData.mipStatus, status)
	opt = 0
	tle = 0
	if status == OPTIMAL
		println("Solution is optimal")
		opt = 1
	elseif status == TIME_LIMIT && has_values(mipModel.model)
		println("Solution is suboptimal due to a time limit, but a primal solution is available")
		tle = 1
	else
		println("The model was not solved correctly. Status: ", status)
		return nothing
	end
	println("  objective value = ", objective_value(mipModel.model))

	println(status)
	objValue = sum(value.(mipModel.C))
	bestbound = objective_bound(mipModel.model)
	numnodes = node_count(mipModel.model)
	time = solve_time(mipModel.model)
	gap = 100 * (objValue - bestbound) / objValue

	x = value.(mipModel.x)
	z = value.(mipModel.z)
	t = value.(mipModel.t)
	tstart = value.(mipModel.tstart)
	tfinal = value.(mipModel.tfinal)
	C = value.(mipModel.C)
	phi = value.(mipModel.phi)
	gamma = value.(mipModel.gamma)
	alpha = value.(mipModel.alpha)

	mipVarsSol = MIPVarsSolution(x, z, t, tstart, tfinal, C, phi, gamma, alpha)
	mipStats = MIPStats(status, opt, tle, objValue, bestbound, numnodes, time, gap)

	return MIPSolution(mipVarsSol, mipStats)
end # function repair()