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

	# Sequence of pickup and delivery nodes visited for each vehicle
	sigma = Vector[Int64[stop.node for stop in sol.vehicles[k][2:end-1]] for k in inst.K]

	# Sequence of machine travels performed by each machine
	psi = Vector[Tuple{Int64, Int64, Int64}[(trv.orig, trv.dest, trv.vehicle) for trv in sol.machines[h]] for h in inst.H]
	
	# Route positions for the sigma list (vehicles)
	L_k = Vector[Int64[i for i in eachindex(sol.vehicles[k][1:end-2])] for k in inst.K]

	# Route positions for the sigma list (machines)
	L_h = Vector[Int64[i for i in eachindex(sol.machines[h])] for h in inst.H]

	# Create variables and fix their respective domains.
	@variable(model, inst.l[inst.depot_begin] >= t[i = inst.V_p_d] >= inst.e[inst.depot_begin])
	@variable(model, inst.l[inst.depot_begin] >= tstart[k = inst.K] >= inst.e[inst.depot_begin])
	@variable(model, inst.l[inst.depot_begin] >= tfinal[k = inst.K] >= inst.e[inst.depot_begin])
	@variable(model, inst.l[inst.depot_begin] >= C[k = inst.K] >= 0)

	# Simplify machine travels
	trvs = Vector[Tuple{Int64, Int64}[(trv.orig, trv.dest) for trv in sol.machines[h]] for h in inst.H]
	@variable(
		model,
		inst.l[inst.depot_begin] >= alpha[i = inst.Vprime, j = inst.Vprime, h = inst.H;
			(i, j) in trvs[h]] >= inst.e[inst.depot_begin]
	)

	"""
	Constraints (48):
	- (General case) Whenever an intra-region arc is traversed by a vehicle, the time to serve the 
	destination node is determined by the times of its origin.
	"""
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

	"""
	Constraints (49):
	- (Depot case) Whenever an intra-region arc is traversed by a vehicle, the time to serve the 
	destination node is determined by the times of its origin.
	"""
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

	"""
	Constraints (50):
	- (General case) Whenever a machine is used to traverse an arc, the starting time on
	the machine is determined by the times of its origin node.
	"""
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
		end
	end

	"""
	Constraints (51):
	- (Depot case) Whenever a machine is used to traverse an arc, the starting time on
	the machine is determined by the times of its origin node.
	"""
	for h in inst.H, l in L_h[h]
		if psi[h][l][1] == inst.depot_begin
			@constraint(model, alpha[inst.depot_begin, psi[h][l][2], h] >= tstart[psi[h][l][3]] + inst.d_bar[inst.depot_begin, h, psi[h][l][3]], base_name = "c51")
		end
	end

	"""
	Constraints (52):
	- Whenever an inter-region arc is traversed by the vehicle, the time to serve the 
	destination node is determined by the times of its machine travel origin station.
	"""
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

	"""
	Constraints (53):
	- The machine can only start a machine travel after finishing the previous
	travel and traveling to the next machine travel origin station.
	"""
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

	"""
	Constraints (54):
	- The machine can only start the first machine travel after traveling 
	from its initial station to the first machine travel origin station.
	"""
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

	"""
	Constraints (55):
	- (General case) Arrival times of the vehicles at the depot based on their origin nodes.
	"""
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

	"""
	Constraints (56):
	- (Depot case) Arrival times of the vehicles at the depot based on their origin nodes.
	"""
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

	"""
	Constraints (57):
	- Lower bounds on the completion times of the vehicles.
	"""
	for k in inst.K
		@constraint(model, C[k] >= tfinal[k] - tstart[k], base_name = "c57")
	end

	"""
	Constraints (58):
	- Lower and upper bounds on the service start times to respect time windows.
	"""
	for i in inst.V_p_d
		@constraint(model, inst.e[i] <= t[i], base_name = "c58_p1")
		@constraint(model, t[i] <= inst.l[i], base_name = "c58_p2")
	end

	"""
	Constraints (59):
	- Vehicle start time earlier than its end time.
	"""
	for k in inst.K
		@constraint(model, tstart[k] <= tfinal[k], base_name = "c59")
	end

	"""
	Objective function (47):
	- The same for the MIP formulation, i.e., minimizing the total completion
	time of the vehicles.
	"""
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
