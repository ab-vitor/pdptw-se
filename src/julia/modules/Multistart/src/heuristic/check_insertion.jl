"""
	function find_active_machine_travel(
		machine::Vector{MachineTravel},
		pos::Ref{Int64},
		k::Int64,
		p_pos::Int64,
		i::Int64 = 1,
	)::MachineTravel

	Given a list of machine travels `machine`, a position reference `pos`, a vehicle `k`, and a position `p_pos`,
	this function iterates through the machine travels starting from `pos` until it finds
	the next active machine travel for vehicle `k` that has a vehicle index greater than or equal
	to `p_pos`. The position reference `pos` is updated to point to the next position after the 
	found machine travel.
"""
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

"""
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

	Searches for a feasible machine travel to insert into the machine travels list `machine` for a given
	vehicle `k` and position `p_pos`. The search starts from index `start` and considers the time window constraints
	of the `prev_stop` and `curr_stop`. If a feasible insertion is found, it returns a `PossibleMachineTravel` object
	indicating the details of the insertion; otherwise, it returns a dummy `PossibleMachineTravel` indicating no feasible insertion.
"""
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
					return PossibleMachineTravel(
						true,
						delta_t,
						h,
						pos_to_insert,
						max(h_arr, k_arr),
						prev_stop.node,
						curr_stop.node,
						vehicle_index,
					)
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

"""
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

	Analyzes the last computed possible machine travel for a given machine `h` to determine if it can be used
	to satisfy the time window constraints of the `curr_stop`. If feasible, it updates the `best_possible_machine_travel`
	reference with the new possible machine travel details. The function returns `true` if a feasible machine travel
	is found or if the last computed travel cannot satisfy the time window; otherwise, it returns `false`.
"""
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

"""
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

	Finds the best machine travel time for a vehicle `k` traveling from `prev_stop` to `curr_stop`.
	It iterates through all available machines and checks for feasible machine travels that satisfy
	the time window constraints. The function returns the minimum travel time found; if no feasible
	travel is found, it returns `Inf` to indicate infeasibility.
"""
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

"""
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

	Advances the current time from `prev_stop` to `curr_stop` for vehicle `k`, considering
	either same-region travel or machine travel between regions. It updates the time
	accordingly and ensures it respects the earliest time window of the `curr_stop`.
"""
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

"""
	function check_insertion(
		sol::Solution,
		k::Int64,
		p_pos::Int64,
		d_pos::Int64,
		p_job::Int64,
		d_job::Int64,
		inst::InstanceData,
	)::CheckInsertionData

	Checks the feasibility of inserting pickup and delivery jobs into the vehicle route
	of vehicle `k` at positions `p_pos` and `d_pos`, respectively. It verifies time window
	and capacity constraints, returning a `CheckInsertionData` object indicating whether
	the insertion is feasible, the associated cost, and any possible machine travels.
"""
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