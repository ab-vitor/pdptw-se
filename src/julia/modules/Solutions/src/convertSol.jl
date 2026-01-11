function getMachineAttendingArc(
	i::Int64,
	j::Int64,
	inst::InstanceData,
	mipSol::MIPSolution,
	params::ParameterData,
)::Int64
	for h in inst.H
		if h in inst.H_e[i][j] && abs(mipSol.vars.phi[i, j, h] - 1) <= 0.1
			return h
		end
	end
	println("\n\n\n\n\n\n\nopa opa opa\n\n\n\n\n\n\n\n\n")
	return 0 # should never happen in a feasible solution
end

function getNextNodeRoute(
	i::Int64,
	k::Int64,
	inst::InstanceData,
	mipSol::MIPSolution,
	params::ParameterData,
)::Int64
	for j in inst.Vprime
		if (i, j) in inst.A && abs(mipSol.vars.x[i, j, k] - 1) <= 0.1
			return j
		end
	end
	println("\n\n\n\n\n\n\nopa opa opa\n\n\n\n\n\n\n\n\n")
	return 0 # should never happen in a feasible solution
end

function createVehicles(
	inst::InstanceData,
	mipSol::MIPSolution,
	params::ParameterData,
)::Tuple{Vector{Vector{VehicleStop}}, Dict{Tuple{Int64, Int64, Int64}, Tuple{Int64, Int64}}}
	vehicles = Vector{VehicleStop}[[] for _ in inst.K]
	arcsh_kp = Dict{Tuple{Int64, Int64, Int64}, Tuple{Int64, Int64}}()
	for k in inst.K
		i = inst.depot_begin
		push!(vehicles[k], VehicleStop(i, inst.jobs[inst.refs[i]], mipSol.vars.tstart[k], 0, 0, mipSol.vars.z[i, k]))
		j = getNextNodeRoute(i, k, inst, mipSol, params)
		h = 0
		if (i, j) in inst.A_m
			h = getMachineAttendingArc(i, j, inst, mipSol, params)
			arcsh_kp[(i, j, h)] = (k, length(vehicles[k]) + 1)
		end
		while j != inst.depot_end
			push!(vehicles[k], VehicleStop(j, inst.jobs[inst.refs[j]], mipSol.vars.t[j], h, 0, mipSol.vars.z[j, k]))
			i = j
			j = getNextNodeRoute(i, k, inst, mipSol, params)
			h = 0
			if (i, j) in inst.A_m
				h = getMachineAttendingArc(i, j, inst, mipSol, params)
				arcsh_kp[(i, j, h)] = (k, length(vehicles[k]) + 1)
			end
		end
		push!(vehicles[k], VehicleStop(j, inst.jobs[inst.refs[j]], mipSol.vars.tfinal[k], h, 0, mipSol.vars.z[j, k]))
	end
	return vehicles, arcsh_kp
end

function createSolutionMelo(
	inst::InstanceData,
	mipSol::MIPSolution,
	params::ParameterData,
)::Solution
	vehicles, arcsh_kp = createVehicles(inst, mipSol, params)

	machines = Vector{MachineTravel}[[] for _ in inst.H]
	completionTimes = Float64[]

	ordered_alpha = Any[]
	for h in inst.H
		push!(ordered_alpha, Any[])
		for (i, j) in inst.A_m
			if h in inst.H_e[i][j] && abs(mipSol.vars.phi[i, j, h] - 1) <= 0.1
				push!(ordered_alpha[h], (mipSol.vars.alpha[i, j, h], i, j))
			end
		end
	end
	for h in inst.H
		ordered_alpha[h] = sort(ordered_alpha[h], by = first)
	end

	for h in inst.H
		for (st, i, j) in ordered_alpha[h]
			if abs(mipSol.vars.phi[i, j, h] - 1) <= 0.1
				k, p = arcsh_kp[(i, j, h)]
				push!(machines[h], MachineTravel(k, p, i, j, st, true))
				vehicles[k][p].machInd = length(machines[h])
			end
		end
	end

	for k in inst.K
		push!(completionTimes, round(mipSol.vars.C[k], digits = 5))
	end

	feasible = true
	sol = Solution(vehicles, machines, completionTimes, feasible, mipSol.stats.objValue, StatsSolution())
	sol.stats = save_stats_solution(inst, sol, params)
	return sol

end # function createSolutionMelo()

function updateSolFromLPSol!(
	sol::Solution,
	lpSol::LPSolution,
	inst::InstanceData,
	params::ParameterData,
)::Nothing
	for k in inst.K
		rt = sol.vehicles[k]
		if length(rt) > 2
			rt[1].servST = lpSol.tstart[k]
			for stop in rt[2:end-1]
				stop.servST = lpSol.t[stop.node]
			end
			rt[end].servST = lpSol.tfinal[k]
		end
		sol.completionTimes[k] = lpSol.C[k]
	end

	for h in inst.H
		mach = sol.machines[h]
		for mtrv in mach
			mtrv.st = lpSol.alpha[mtrv.orig, mtrv.dest, h]
		end
	end

	sol.feasible = true
	sol.value = lpSol.objValue
	return nothing
end # function updateSolFromLPSol!()
