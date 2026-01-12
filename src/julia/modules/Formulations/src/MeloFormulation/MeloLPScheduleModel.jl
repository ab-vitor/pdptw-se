function runLPFormToReScheduleSol(env::Union{Gurobi.Env, Nothing}, sol::Solution, inst::InstanceData, params::ParameterData)::Solution
	if params.solver == "Gurobi"
		model = Model(() -> Gurobi.Optimizer(env))
		if params.outputFlagGrbMSLP == 0
			set_attribute(model, "OutputFlag", 0)
			set_silent(model)
		end
		if params.threads > 0
			max_num_threads = length(Sys.cpu_info())
			num_threads = max_num_threads
			if params.threads > 0 && params.threads <= max_num_threads
				num_threads = params.threads
			else
				error("Number of threads must be between 1 and $(max_num_threads)")
			end
			set_attribute(model, "Threads", num_threads)
		else
			error("Number of threads must be greater than zero")
		end
		set_attribute(model, "Threads", params.threads)
		set_attribute(model, "Method", Int(params.solverMethod))
	else
		error("No solver selected")
	end


	trvs = Vector[Tuple{Int64, Int64}[(trv.orig, trv.dest) for trv in sol.machines[h]] for h in inst.H]

	sigma = Vector[Int64[stop.node for stop in sol.vehicles[k][2:end-1]] for k in inst.K]
	psi = Vector[Tuple{Int64, Int64, Int64}[(trv.orig, trv.dest, trv.vehicle) for trv in sol.machines[h]] for h in inst.H]
	L_k = Vector[Int64[i for i in eachindex(sol.vehicles[k][1:end-2])] for k in inst.K]
	L_h = Vector[Int64[i for i in eachindex(sol.machines[h])] for h in inst.H]

	@variable(model, inst.jobs[inst.refs[inst.depot_begin]].lat >= t[i = inst.V_p_d] >= 0)
	@variable(model, inst.jobs[inst.refs[inst.depot_begin]].lat >= tstart[k = inst.K] >= 0)
	@variable(model, inst.jobs[inst.refs[inst.depot_begin]].lat >= tfinal[k = inst.K] >= 0)
	@variable(model, inst.jobs[inst.refs[inst.depot_begin]].lat >= C[k = inst.K] >= 0)
	@variable(
		model,
		inst.jobs[inst.refs[inst.depot_begin]].lat >= alpha[i = inst.Vprime, j = inst.Vprime, h = inst.H; (i, j) in trvs[h]] >= 0
	)

	# c37
	for k in inst.K, i in L_k[k][2:end]
		if inst.jobs[inst.refs[sigma[k][i-1]]].point.z == inst.jobs[inst.refs[sigma[k][i]]].point.z
			@constraint(
				model,
				t[sigma[k][i]] >=
				t[sigma[k][i-1]] +
				inst.s[sigma[k][i-1]] +
				inst.d[sigma[k][i-1], sigma[k][i], k],
				base_name = "c37"
			)
		end
	end

	# c38
	for k in inst.K
		if length(L_k[k]) > 0 && inst.jobs[inst.refs[1]].point.z == inst.jobs[inst.refs[sigma[k][1]]].point.z
			@constraint(
				model,
				t[sigma[k][1]] >=
				tstart[k] +
				inst.d[1, sigma[k][1], k],
				base_name = "c38"
			)
		end
	end

	# c39 and c40
	for h in inst.H, l in L_h[h]
		if psi[h][l][1] != 1
			@constraint(
				model,
				alpha[psi[h][l][1], psi[h][l][2], h] >=
				t[psi[h][l][1]] +
				inst.s[psi[h][l][1]] +
				inst.d_bar[psi[h][l][1], h, psi[h][l][3]],
				base_name = "c39"
			)
		else
			@constraint(model, alpha[1, psi[h][l][2], h] >= tstart[psi[h][l][3]] + inst.d_bar[1, h, psi[h][l][3]], base_name = "c40")
		end
	end

	# c41
	for h in inst.H, l in L_h[h]
		if psi[h][l][2] != inst.depot_end
			@constraint(
				model,
				t[psi[h][l][2]] >=
				alpha[psi[h][l][1], psi[h][l][2], h] +
				inst.O[(
					inst.f[psi[h][l][1]][h],
					inst.f[psi[h][l][2]][h],
					h,
				)] +
				inst.d_bar[psi[h][l][2], h, psi[h][l][3]],
				base_name = "c41"
			)
		end
	end

	# c42
	for h in inst.H, l in L_h[h][2:end]
		@constraint(
			model,
			alpha[psi[h][l][1], psi[h][l][2], h] >=
			alpha[psi[h][l-1][1], psi[h][l-1][2], h] +
			inst.O[(
				inst.f[psi[h][l-1][1]][h],
				inst.f[psi[h][l-1][2]][h],
				h,
			)] +
			inst.O[(
				inst.f[psi[h][l-1][2]][h],
				inst.f[psi[h][l][1]][h],
				h,
			)],
			base_name = "c42"
		)
	end

	# c43
	for h in inst.H
		if length(L_h[h]) > 0
			@constraint(
				model,
				alpha[psi[h][1][1], psi[h][1][2], h] >=
				inst.O[(1, inst.f[psi[h][1][1]][h], h)],
				base_name = "c43"
			)
		end
	end

	# c44
	for k in inst.K
		if length(L_k[k]) > 0 && inst.jobs[inst.refs[sigma[k][end]]].point.z == inst.jobs[inst.refs[inst.depot_end]].point.z
			@constraint(
				model,
				tfinal[k] >=
				t[sigma[k][end]] +
				inst.s[sigma[k][end]] +
				inst.d[sigma[k][end], inst.depot_end, k],
				base_name = "c44"
			)
		end
	end

	# c45
	for h in inst.H, l in L_h[h]
		if psi[h][l][2] == 2 * inst.n + 2
			@constraint(
				model,
				tfinal[psi[h][l][3]] >=
				alpha[psi[h][l][1], inst.depot_end, h] +
				inst.O[(
					inst.f[psi[h][l][1]][h],
					inst.f[inst.depot_end][h],
					h,
				)] +
				inst.d_bar[inst.depot_end, h, psi[h][l][3]],
				base_name = "c45"
			)
		end
	end

	# c46
	for k in inst.K
		@constraint(model, C[k] >= tfinal[k] - tstart[k], base_name = "c46")
	end

	# c47
	for i in inst.V_p_d
		@constraint(model, inst.eprime[i] <= t[i], base_name = "c47_p1")
		@constraint(model, t[i] <= inst.lprime[i], base_name = "c47_p2")
	end

	# c48
	for k in inst.K
		@constraint(model, inst.jobs[inst.refs[inst.depot_begin]].earl <= tstart[k], base_name = "c48_p1")
		@constraint(model, tstart[k] <= tfinal[k], base_name = "c48_p2")
		@constraint(model, tfinal[k] <= inst.jobs[inst.refs[inst.depot_begin]].lat, base_name = "c48_p3")
	end

	# c36
	@objective(model, Min, sum(C))

	# Starting optimization

	optimize!(model)


	# Retrieving results

	status = termination_status(model)

	opt = 0
	tle = 0
	if status == OPTIMAL
		# Solution is optimal
		opt = 1
	elseif status == TIME_LIMIT && has_values(model)
		# Solution is suboptimal due to a time limit, but a primal solution is available
		tle = 1
	else
		# The model was not solved correctly
		sol.feasible = false
		return sol
	end
	# println("  objective value = ", objective_value(model))

	# println(status)

	objValue = objective_value(model)
	if abs(sol.value - objValue) < params.epsilon
		return sol
	end
	bestbound = objective_bound(model)
	numnodes = node_count(model)
	time = solve_time(model)
	gap = 100 * (objValue - bestbound) / objValue

	t = value.(t)
	tstart = value.(tstart)
	tfinal = value.(tfinal)
	C = value.(C)
	alpha = value.(alpha)

	lpSol = LPSolution(t, tstart, tfinal, C, alpha, status, opt, tle, objValue, bestbound, numnodes, time, gap)
	Solutions.updateSolFromLPSol!(sol, lpSol, inst, params)

	return sol
end # function runLPFormToReScheduleSol()
