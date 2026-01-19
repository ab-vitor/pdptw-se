function run_LP_to_reschedule_solution(env::Union{Gurobi.Env, Nothing}, sol::Solution, inst::InstanceData, params::ParameterData)::Solution
	if params.solver == "Gurobi"
		model = Model(() -> Gurobi.Optimizer(env))
		if params.output_flag_grb_MSLP == 0
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
		set_attribute(model, "Method", Int(params.solver_method))
	else
		error("No solver selected")
	end


	trvs = Vector[Tuple{Int64, Int64}[(trv.orig, trv.dest) for trv in sol.machines[h]] for h in inst.H]

	sigma = Vector[Int64[stop.node for stop in sol.vehicles[k][2:end-1]] for k in inst.K]
	psi = Vector[Tuple{Int64, Int64, Int64}[(trv.orig, trv.dest, trv.vehicle) for trv in sol.machines[h]] for h in inst.H]
	L_k = Vector[Int64[i for i in eachindex(sol.vehicles[k][1:end-2])] for k in inst.K]
	L_h = Vector[Int64[i for i in eachindex(sol.machines[h])] for h in inst.H]

	@variable(model, inst.l[inst.depot_begin] >= t[i = inst.V_p_d] >= inst.e[inst.depot_begin])
	@variable(model, inst.l[inst.depot_begin] >= tstart[k = inst.K] >= inst.e[inst.depot_begin])
	@variable(model, inst.l[inst.depot_begin] >= tfinal[k = inst.K] >= inst.e[inst.depot_begin])
	@variable(model, inst.l[inst.depot_begin] >= C[k = inst.K] >= 0)
	@variable(
		model,
		inst.l[inst.depot_begin] >= alpha[i = inst.Vprime, j = inst.Vprime, h = inst.H;
			(i, j) in trvs[h]] >= inst.e[inst.depot_begin]
	)

	# c48
	for k in inst.K, i in L_k[k][2:end]
		if inst.jobs[inst.refs[sigma[k][i-1]]].point.z == inst.jobs[inst.refs[sigma[k][i]]].point.z
			@constraint(
				model,
				t[sigma[k][i]] >=
				t[sigma[k][i-1]] +
				inst.s[sigma[k][i-1]] +
				inst.d[sigma[k][i-1], sigma[k][i], k],
				base_name = "c48"
			)
		end
	end

	# c49
	for k in inst.K
		if length(L_k[k]) > 0 && inst.jobs[inst.refs[inst.depot_begin]].point.z == inst.jobs[inst.refs[sigma[k][1]]].point.z
			@constraint(
				model,
				t[sigma[k][1]] >=
				tstart[k] +
				inst.d[inst.depot_begin, sigma[k][1], k],
				base_name = "c49"
			)
		end
	end

	# c50 and c51
	for h in inst.H, l in L_h[h]
		if psi[h][l][1] != inst.depot_begin
			@constraint(
				model,
				alpha[psi[h][l][1], psi[h][l][2], h] >=
				t[psi[h][l][1]] +
				inst.s[psi[h][l][1]] +
				inst.d_bar[psi[h][l][1], h, psi[h][l][3]],
				base_name = "c50"
			)
		else
			@constraint(model, alpha[inst.depot_begin, psi[h][l][2], h] >= tstart[psi[h][l][3]] + inst.d_bar[inst.depot_begin, h, psi[h][l][3]], base_name = "c51")
		end
	end

	# c52
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
				base_name = "c52"
			)
		end
	end

	# c53
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
			base_name = "c53"
		)
	end

	# c54
	for h in inst.H
		if length(L_h[h]) > 0
			@constraint(
				model,
				alpha[psi[h][1][1], psi[h][1][2], h] >=
				inst.O[(inst.initial_station, inst.f[psi[h][1][1]][h], h)],
				base_name = "c54"
			)
		end
	end

	# c55
	for k in inst.K
		if length(L_k[k]) > 0 && inst.jobs[inst.refs[sigma[k][end]]].point.z == inst.jobs[inst.refs[inst.depot_end]].point.z
			@constraint(
				model,
				tfinal[k] >=
				t[sigma[k][end]] +
				inst.s[sigma[k][end]] +
				inst.d[sigma[k][end], inst.depot_end, k],
				base_name = "c55"
			)
		end
	end

	# c56
	for h in inst.H, l in L_h[h]
		if psi[h][l][2] == inst.depot_end
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
				base_name = "c56"
			)
		end
	end

	# c57
	for k in inst.K
		@constraint(model, C[k] >= tfinal[k] - tstart[k], base_name = "c57")
	end

	# c58
	for i in inst.V_p_d
		@constraint(model, inst.e[i] <= t[i], base_name = "c58_p1")
		@constraint(model, t[i] <= inst.l[i], base_name = "c58_p2")
	end

	# c59
	for k in inst.K
		@constraint(model, inst.e[inst.depot_begin] <= tstart[k], base_name = "c59_p1")
		@constraint(model, tstart[k] <= tfinal[k], base_name = "c59_p2")
		@constraint(model, tfinal[k] <= inst.l[inst.depot_begin], base_name = "c59_p3")
	end

	# c47
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

	obj_value = objective_value(model)
	if abs(sol.value - obj_value) < params.epsilon
		return sol
	end
	best_bound = objective_bound(model)
	num_nodes = node_count(model)
	time = solve_time(model)
	gap = 100 * (obj_value - best_bound) / obj_value

	t = value.(t)
	tstart = value.(tstart)
	tfinal = value.(tfinal)
	C = value.(C)
	alpha = value.(alpha)

	LP_sol = LPSolution(t, tstart, tfinal, C, alpha, status, opt, tle, obj_value, best_bound, num_nodes, time, gap)
	Solutions.update_sol_from_LP_sol!(sol, LP_sol, inst)

	return sol
end # function run_LP_to_reschedule_solution()
