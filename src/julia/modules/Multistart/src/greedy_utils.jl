function find_active_machine_travel(machine::Vector{MachineTravel}, pos::Ref{Int64}, k::Int64, p_pos::Int64, i::Int64 = 1)::MachineTravel
	if pos[] > length(machine)
		return MachineTravel(k, p_pos)
	end
	trv = machine[pos[]]
	while trv.vehicle == k &&
			  trv.vehicle_index >= p_pos &&
			  pos[] < length(machine)
		pos[] += i
		trv = machine[pos[]]
	end
	return trv
end # function find_active_machine_travel()

function find_feas_mtrv_to_insert_in_machine(
	machine::Vector{MachineTravel},
	h::Int64,
	start::Int64,
	k::Int64,
	p_pos::Int64,
	dep_time::Float64,
	LB_new_trv_end::Float64,
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	vehicle_index::Int64,
	inst::InstanceData,
)::PossibleMachineTravel
	dummy_mtrv = PossibleMachineTravel(false, 0, 0, 0, 0, 0, 0, 0)
	prev_active_mtrv_pos = start - 1
	for pos_to_insert in eachindex(machine)[start:end]
		trv = machine[pos_to_insert]
		if trv.vehicle != k || trv.vehicle_index < p_pos
			if LB_new_trv_end + inst.O[(inst.f[curr_stop.node][h], inst.f[trv.orig][h], h)] <= trv.st
				if prev_active_mtrv_pos == 0
					init_station_dep_time = inst.e[inst.depot_begin]
					h_arr = init_station_dep_time + inst.O[(inst.initial_station, inst.f[prev_stop.node][h], h)]
				else
					prev_act_trv = machine[prev_active_mtrv_pos]
					prev_act_trv_end = prev_act_trv.st + inst.O[(inst.f[prev_act_trv.orig][h], inst.f[prev_act_trv.dest][h], h)]
					h_arr = prev_act_trv_end + inst.O[(inst.f[prev_act_trv.dest][h], inst.f[prev_stop.node][h], h)]
				end
				k_arr = dep_time + inst.d_bar[prev_stop.node, h, k]
				new_trv_end = max(h_arr, k_arr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
				k_arr_at_curr_node = new_trv_end + inst.d_bar[curr_stop.node, h, k]
				if k_arr_at_curr_node > curr_stop.job.lat
					return dummy_mtrv
				elseif new_trv_end + inst.O[(inst.f[curr_stop.node][h], inst.f[trv.orig][h], h)] <= trv.st
					delta_t = k_arr_at_curr_node - dep_time
					return PossibleMachineTravel(true, delta_t, h, pos_to_insert, max(h_arr, k_arr), prev_stop.node, curr_stop.node, vehicle_index)
				end
			end
			prev_active_mtrv_pos = pos_to_insert
		end
	end

	if prev_active_mtrv_pos == 0
		pos_to_insert = 1
		init_station_dep_time = inst.e[inst.depot_begin]
		h_arr = init_station_dep_time + inst.O[(inst.initial_station, inst.f[prev_stop.node][h], h)]
		k_arr = dep_time + inst.d_bar[prev_stop.node, h, k]
		new_trv_end = max(h_arr, k_arr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
		k_arr_at_curr_node = new_trv_end + inst.d_bar[curr_stop.node, h, k]
		if k_arr_at_curr_node > curr_stop.job.lat
			return dummy_mtrv
		else
			delta_t = k_arr_at_curr_node - dep_time
			return PossibleMachineTravel(true, delta_t, h, pos_to_insert, max(h_arr, k_arr), prev_stop.node, curr_stop.node, vehicle_index)
		end
	end

	pos_to_insert = length(machine) + 1
	prev_act_trv = machine[prev_active_mtrv_pos]
	prev_act_trv_end = prev_act_trv.st + inst.O[(inst.f[prev_act_trv.orig][h], inst.f[prev_act_trv.dest][h], h)]
	h_arr = prev_act_trv_end + inst.O[(inst.f[prev_act_trv.dest][h], inst.f[prev_stop.node][h], h)]
	k_arr = dep_time + inst.d_bar[prev_stop.node, h, k]
	new_trv_end = max(h_arr, k_arr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
	k_arr_at_curr_node = new_trv_end + inst.d_bar[curr_stop.node, h, k]
	if k_arr_at_curr_node > curr_stop.job.lat
		return dummy_mtrv
	end

	delta_t = k_arr_at_curr_node - dep_time
	return PossibleMachineTravel(true, delta_t, h, pos_to_insert, max(h_arr, k_arr), prev_stop.node, curr_stop.node, vehicle_index)
end # function find_feas_mtrv_to_insert_in_machine()

function analyze_possible_machine_travel_from_last_computed_possible_machine_travel(
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	curr_time::Float64,
	inst::InstanceData,
	machine::Vector{MachineTravel},
	possible_machine_travels::Vector{Vector},
	h::Int64,
	best_possible_machine_travel::Ref{PossibleMachineTravel},
	start_h_pos::Ref{Int64},
	vehicle_index::Int64,
	p_pos::Int64,
)::Bool
	last_possible_mtrv = possible_machine_travels[h][end]
	start_h_pos[] = last_possible_mtrv.h_pos
	last_possible_mtrv_end = last_possible_mtrv.st + inst.O[(inst.f[last_possible_mtrv.orig][h], inst.f[last_possible_mtrv.dest][h], h)]
	h_arr = last_possible_mtrv_end + inst.O[(inst.f[last_possible_mtrv.dest][h], inst.f[prev_stop.node][h], h)]
	k_arr = curr_time + inst.d_bar[prev_stop.node, h, k]
	new_trv_end = max(h_arr, k_arr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
	k_arr_at_curr_node = new_trv_end + inst.d_bar[curr_stop.node, h, k]
	if k_arr_at_curr_node > curr_stop.job.lat
		return true
	end
	next_trv = find_active_machine_travel(machine, start_h_pos, k, p_pos)
	if !(next_trv.vehicle == k && next_trv.vehicle_index >= p_pos)
		if new_trv_end + inst.O[(inst.f[curr_stop.node][h], inst.f[next_trv.orig][h], h)] <= next_trv.st
			delta_t = k_arr_at_curr_node - curr_time
			if delta_t < best_possible_machine_travel[].delta_t
				best_possible_machine_travel[] =
					PossibleMachineTravel(true, delta_t, h, start_h_pos[], max(h_arr, k_arr), prev_stop.node, curr_stop.node, vehicle_index)
			end
			return true
		end
		return false
	end

	delta_t = k_arr_at_curr_node - curr_time
	if delta_t < best_possible_machine_travel[].delta_t
		best_possible_machine_travel[] =
			PossibleMachineTravel(true, delta_t, h, start_h_pos[], max(h_arr, k_arr), prev_stop.node, curr_stop.node, vehicle_index)
	end
	return true
end # function analyze_possible_machine_travel_from_last_computed_possible_machine_travel()

function get_best_machine_travel_time(
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	dep_time::Float64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possible_machine_travels::Vector{Vector},
	vehicle_index::Int64,
	p_pos::Int64,
)::Float64
	best_possible_machine_travel = Ref(PossibleMachineTravel(false, Inf64, 0, 0, 0, 0, 0, 0))
	for h in inst.H_e[prev_stop.node][curr_stop.node]
		LB_new_trv_end = dep_time + inst.d_bar[prev_stop.node, h, k] + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
		if LB_new_trv_end + inst.d_bar[curr_stop.node, h, k] > curr_stop.job.lat
			continue
		end

		start_h_pos = Ref(1)
		if length(possible_machine_travels[h]) > 0 &&
		   analyze_possible_machine_travel_from_last_computed_possible_machine_travel(
			prev_stop,
			curr_stop,
			k,
			dep_time,
			inst,
			machines[h],
			possible_machine_travels,
			h,
			best_possible_machine_travel,
			start_h_pos,
			vehicle_index,
			p_pos,
		)
			continue
		end

		mtrv = find_feas_mtrv_to_insert_in_machine(
			machines[h], h, start_h_pos[],
			k, p_pos, dep_time, LB_new_trv_end,
			prev_stop, curr_stop, vehicle_index, inst,
		)
		if mtrv.found && mtrv.delta_t < best_possible_machine_travel[].delta_t
			best_possible_machine_travel[] = mtrv
		end
	end
	if !best_possible_machine_travel[].found
		# If it wasn't found, it means that time window at curr_stop cannot be satisfied
		# thus we return Inf to indicate infeasibility
		return Inf64
	end
	push!(possible_machine_travels[best_possible_machine_travel[].h], best_possible_machine_travel[])

	return best_possible_machine_travel[].delta_t
end # function get_best_machine_travel_time()


function advance_best_time(
	time::Float64,
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possible_machine_travels::Vector{Vector},
	vehicle_index::Int64,
	p_pos::Int64,
)::Float64
	time += inst.s[prev_stop.node]
	if prev_stop.job.point.z == curr_stop.job.point.z
		time += inst.d[prev_stop.node, curr_stop.node, k]
	else
		time += get_best_machine_travel_time(prev_stop, curr_stop, k, time, inst, machines, possible_machine_travels, vehicle_index, p_pos)
	end
	time = max(time, curr_stop.job.earl)
	return time
end # function advance_best_time()

function advance_time(
	time::Float64,
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machine_travels::Vector{PossibleMachineTravel},
	last_mach_trv::Ref{Int64},
)::Float64
	time += inst.s[prev_stop.node]
	if prev_stop.job.point.z == curr_stop.job.point.z
		curr_stop.mach = 0
		time += inst.d[prev_stop.node, curr_stop.node, k]
	else
		mach_trv = machine_travels[last_mach_trv[]]
		curr_stop.mach = mach_trv.h
		last_mach_trv[] += 1
		time += mach_trv.delta_t
	end
	time = max(time, curr_stop.job.earl)
	return time
end # function advance_time()

function deactivate_machine_travels(k::Int64, sol::Solution, p_pos::Int64)::Nothing
	for h in eachindex(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if sol.machines[h][i].vehicle == k && sol.machines[h][i].vehicle_index >= p_pos
				sol.machines[h][i].active = false
			end
		end
	end
	return nothing
end # function deactivate_machine_travels()

function check_insertion(
	sol::Solution,
	k::Int64,
	p_pos::Int64,
	d_pos::Int64,
	p_job::Int64,
	d_job::Int64,
	inst::InstanceData,
)::CheckInsertionData

	possible_machine_travels = Vector[PossibleMachineTravel[] for _ in inst.H]

	prev = p_pos - 1
	curr = p_pos
	prev_stop = sol.vehicles[k][prev]
	curr_stop = VehicleStop(p_job, inst.jobs[inst.refs[p_job]], 0, 0, 0, 0)

	time = prev_stop.serv_start_time
	time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels, curr, p_pos)
	load = prev_stop.load + curr_stop.job.dem

	if time > curr_stop.job.lat || load > inst.Q[k]
		return CheckInsertionData(false, 0, possible_machine_travels)
	end

	prev_stop = curr_stop
	if p_pos != d_pos
		curr_stop = sol.vehicles[k][curr]
		time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels, curr + 1, p_pos)
		load += curr_stop.job.dem
		if time > curr_stop.job.lat || load > inst.Q[k]
			return CheckInsertionData(false, 0, possible_machine_travels)
		end

		prev += 1
		curr += 1
		while curr < d_pos
			prev_stop = sol.vehicles[k][prev]
			curr_stop = sol.vehicles[k][curr]
			time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels, curr + 1, p_pos)
			load += curr_stop.job.dem
			if time > curr_stop.job.lat || load > inst.Q[k]
				return CheckInsertionData(false, 0, possible_machine_travels)
			end
			prev += 1
			curr += 1
		end
		prev_stop = sol.vehicles[k][prev]
	end

	curr_stop = VehicleStop(d_job, inst.jobs[inst.refs[d_job]], 0, 0, 0, 0)
	time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels, curr + 1, p_pos)
	load += curr_stop.job.dem
	if time > curr_stop.job.lat
		return CheckInsertionData(false, 0, possible_machine_travels)
	end

	prev_stop = curr_stop
	curr_stop = sol.vehicles[k][curr]
	time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels, curr + 2, p_pos)
	load += curr_stop.job.dem
	if time > curr_stop.job.lat
		return CheckInsertionData(false, 0, possible_machine_travels)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prev_stop = sol.vehicles[k][prev]
		curr_stop = sol.vehicles[k][curr]
		time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels, curr + 2, p_pos)
		if time > curr_stop.job.lat
			return CheckInsertionData(false, 0, possible_machine_travels)
		end
		prev += 1
		curr += 1
	end

	cost = time - sol.vehicles[k][end].serv_start_time
	return CheckInsertionData(true, cost, possible_machine_travels)
end # function check_insertion()

function remove_deactivated_travels(sol::Solution)::Nothing
	for h in eachindex(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if !sol.machines[h][i].active
				splice!(sol.machines[h], i)
			end
		end
	end
	return nothing
end # function remove_deactivated_travels()

function update_machines_indexes(sol::Solution)::Nothing
	for h in eachindex(sol.machines)
		for i in eachindex(sol.machines[h])[1:end]
			mach_trv = sol.machines[h][i]
			sol.vehicles[mach_trv.vehicle][mach_trv.vehicle_index].mach_index = i
		end
	end
	return nothing
end # function update_machines_indexes

function insert_machine_travels(
	sol::Solution,
	machine_travels::Vector{PossibleMachineTravel},
	k::Int64,
)
	active = true
	for i in length(machine_travels):-1:1
		mach_trv = machine_travels[i]
		insert!(
			sol.machines[mach_trv.h],
			mach_trv.h_pos,
			MachineTravel(k, mach_trv.vehicle_index, mach_trv.orig, mach_trv.dest, mach_trv.st, active),
		)
	end
end # function insert_machine_travels()

function update_solution(sol::Solution, ins_data::InsertionData, inst::InstanceData)::Solution
	k = ins_data.k
	p_pos = ins_data.p_pos
	d_pos = ins_data.d_pos
	p_job = ins_data.p_job
	d_job = ins_data.d_job
	machine_travels = flat_machine_travels_chronollogically(ins_data.machine_travels)

	deactivate_machine_travels(k, sol, p_pos)

	last_mach_trv = Ref(1)

	prev = p_pos - 1
	curr = p_pos
	prev_stop = sol.vehicles[k][prev]
	pickup_stop = VehicleStop(p_job, inst.jobs[inst.refs[p_job]], 0, 0, 0, 0)

	time = prev_stop.serv_start_time
	time = advance_time(time, prev_stop, pickup_stop, k, inst, machine_travels, last_mach_trv)
	load = prev_stop.load + pickup_stop.job.dem

	pickup_stop.serv_start_time = time
	pickup_stop.load = load

	prev_stop = pickup_stop
	if p_pos != d_pos
		curr_stop = sol.vehicles[k][curr]
		time = advance_time(time, prev_stop, curr_stop, k, inst, machine_travels, last_mach_trv)
		load += curr_stop.job.dem

		curr_stop.serv_start_time = time
		curr_stop.load = load

		prev += 1
		curr += 1
		while curr < d_pos
			prev_stop = sol.vehicles[k][prev]
			curr_stop = sol.vehicles[k][curr]
			time = advance_time(time, prev_stop, curr_stop, k, inst, machine_travels, last_mach_trv)
			load += curr_stop.job.dem

			curr_stop.serv_start_time = time
			curr_stop.load = load

			prev += 1
			curr += 1
		end
		prev_stop = sol.vehicles[k][prev]
	end

	delivery_stop = VehicleStop(d_job, inst.jobs[inst.refs[d_job]], 0, 0, 0, 0)
	time = advance_time(time, prev_stop, delivery_stop, k, inst, machine_travels, last_mach_trv)
	load += delivery_stop.job.dem

	delivery_stop.serv_start_time = time
	delivery_stop.load = load

	prev_stop = delivery_stop
	curr_stop = sol.vehicles[k][curr]
	time = advance_time(time, prev_stop, curr_stop, k, inst, machine_travels, last_mach_trv)
	load += curr_stop.job.dem

	curr_stop.serv_start_time = time

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prev_stop = sol.vehicles[k][prev]
		curr_stop = sol.vehicles[k][curr]
		time = advance_time(time, prev_stop, curr_stop, k, inst, machine_travels, last_mach_trv)
		curr_stop.serv_start_time = time
		prev += 1
		curr += 1
	end

	insert!(sol.vehicles[k], d_pos, delivery_stop)
	insert!(sol.vehicles[k], p_pos, pickup_stop)
	insert_machine_travels(sol, machine_travels, k)
	remove_deactivated_travels(sol)
	sol.completion_times[k] = sol.vehicles[k][end].serv_start_time
	sol.value += ins_data.cost

	return sol
end # function update_solution()

function tightest_time_windows(inst::InstanceData)::Vector{Int64}
	reqs = copy(inst.V_p)
	sort!(reqs, by = i -> (inst.l[i] - inst.e[i]))

	return reqs
end # function tightest_time_windows()

function random_order_nodes(inst::InstanceData, params::ParameterData)::Vector{Int64}
	rkvector = rand(params.rng, Float64, inst.n)
	order_nodes = sortperm(rkvector) .+ 1

	return order_nodes
end # function random_order_nodes

function init_vehicle_routes(inst::InstanceData)::Vector{Vector{VehicleStop}}
	# Start depot -> 1 in inst.Vprime, which is equivalent to 0 in paper
	first_vehicle_stop = VehicleStop(1, inst.jobs[inst.refs[1]], 0, 0, 0, 0)
	# End depot -> 2*inst.n+2 in inst.Vprime, which is equivalent to 2*n+1 in paper
	last_vehicle_stop = VehicleStop(2 * inst.n + 2, inst.jobs[inst.refs[2*inst.n+2]], 0, 0, 0, 0)

	vehicle_routes = Vector{VehicleStop}[[copy(first_vehicle_stop), copy(last_vehicle_stop)] for _ in inst.K]

	return vehicle_routes
end # function init_vehicle_routes()

function init_machine_travels(inst::InstanceData)::Vector{Vector{MachineTravel}}
	# Insert a dummy MachineTravel in each machine travels list with start time at 0 (code simplification)
	machine_routes = Vector{MachineTravel}[[] for _ in inst.H]

	return machine_routes
end # function init_machine_travels()

function get_service_order(inst::InstanceData, params::ParameterData)::Vector{Int64}
	if params.greedy_service_order == "tightest_tw"
		return tightest_time_windows(inst)
	elseif params.greedy_service_order == "random"
		return random_order_nodes(inst, params)
	end

	error("Unknown greedy service order: $(params.greedy_service_order)")
end # function get_service_order()

function init_solution(inst::InstanceData)::Solution
	initial_vehicle_routes = init_vehicle_routes(inst)
	initial_machine_travels = init_machine_travels(inst)
	initial_completion_times = Float64[0 for _ in inst.K]
	initial_stats = SolutionStats()

	return Solution(
		initial_vehicle_routes,
		initial_machine_travels,
		initial_completion_times,
		false,
		0.0,
		initial_stats)
end # function init_solution()

function flat_machine_travels_chronollogically(
	possible_machine_travels::Vector{Vector{PossibleMachineTravel}},
)::Vector{PossibleMachineTravel}
	machine_travels = collect(Iterators.flatten(possible_machine_travels))
	sort!(machine_travels, by = i -> (i.st))

	return machine_travels
end # function flat_machine_travels_chronollogically()
