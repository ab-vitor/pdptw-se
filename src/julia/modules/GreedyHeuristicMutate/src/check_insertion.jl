"""
	function find_next_active_machine_travel(machine::Vector{MachineTravel}, pos::Ref{Int64})::MachineTravel

	Given a machine travel list (machine), and a position in that list (pos), the function returns
	the next active machine travel found in the list, starting from the given position.
"""
function find_next_active_machine_travel(machine::Vector{MachineTravel}, pos::Ref{Int64})::MachineTravel
	trv = machine[pos[]]
	while !trv.active
		pos[] += 1
		trv = machine[pos[]]
	end
	return trv
end # function find_next_active_machine_travel()

"""
	function analyze_possible_machine_travel_from_last_computed_possible_machine_travel!(
		prev_stop::VehicleStop,
		curr_stop::VehicleStop,
		k::Int64,
		curr_time::Float64,
		inst::InstanceData,
		machines::Vector{Vector{MachineTravel}},
		possible_machine_travels::Vector{Vector},
		h::Int64,
		best_possible_machine_travel::Ref{PossibleMachineTravel},
		start_h_pos::Ref{Int64},
	)::Nothing

	Given the last computed possible machine travel for a given machine (h), the function analyses
	if it is possible to schedule a new machine travel after that one, and if so, updates the best
	possible machine travel found so far.
"""
function analyze_possible_machine_travel_from_last_computed_possible_machine_travel!(
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	curr_time::Float64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possible_machine_travels::Vector{Vector},
	h::Int64,
	best_possible_machine_travel::Ref{PossibleMachineTravel},
	start_h_pos::Ref{Int64},
)::Nothing
	last_possible_machine_travel = possible_machine_travels[h][end]
	start_h_pos[] = last_possible_machine_travel.h_pos
	trv_1 = last_possible_machine_travel
	trv_2 = find_next_active_machine_travel(machines[h], start_h_pos)

	trv_1_end = trv_1.st + inst.O[(inst.f[trv_1.orig][h], inst.f[trv_1.dest][h], h)]
	h_arr = trv_1_end + inst.O[(inst.f[trv_1.dest][h], inst.f[prev_stop.node][h], h)]
	k_arr = curr_time + inst.d_bar[prev_stop.node, h, k]
	new_trv_end = max(h_arr, k_arr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
	if start_h_pos[] == length(machines[h]) || new_trv_end + inst.O[(inst.f[curr_stop.node][h], inst.f[trv_2.orig][h], h)] <= trv_2.st
		delta_t = new_trv_end - curr_time
		delta_t += inst.d_bar[curr_stop.node, h, k]
		if !best_possible_machine_travel[].found || delta_t < best_possible_machine_travel[].delta_t
			best_possible_machine_travel[] = PossibleMachineTravel(true, delta_t, h, start_h_pos[], max(h_arr, k_arr), prev_stop.node, curr_stop.node)
		end
	end
	return nothing
end # function analyze_possible_machine_travel_from_last_computed_possible_machine_travel!()

"""
	function get_best_vehicle_travel_time(
		prev_stop::VehicleStop,
		curr_stop::VehicleStop,
		k::Int64,
		curr_time::Float64,
		inst::InstanceData,
		machines::Vector{Vector{MachineTravel}},
		possible_machine_travels::Vector{Vector},
	)::Float64

	Given two vehicle stops (prev_stop and curr_stop), the vehicle index (k), the current time
	(curr_time), the instance data (inst), the machine travels (machines), and the possible
	machine travels already computed (possible_machine_travels), the function returns the best
	vehicle travel time between the two stops, considering both a same-region travel and different-region 
	travels.
	If it is a different-region travel, the function also updates the possible_machine_travels by 
	selecting the best possible machine travel found.

	Note: it is assumed that at least one possible machine travel can be scheduled between the two stops
	Time windows are checked later in the insertion checking function.
"""
function get_best_vehicle_travel_time(
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	curr_time::Float64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possible_machine_travels::Vector{Vector},
)::Float64
	if prev_stop.job.point.z == curr_stop.job.point.z
		return inst.d[prev_stop.node, curr_stop.node, k]
	end

	best_possible_machine_travel = Ref(PossibleMachineTravel(false, 0, 0, 0, 0, 0, 0))
	for h in inst.H_e[prev_stop.node][curr_stop.node]
		start_h_pos = Ref(1)
		if length(possible_machine_travels[h]) > 0
			analyze_possible_machine_travel_from_last_computed_possible_machine_travel!(
				prev_stop,
				curr_stop,
				k,
				curr_time,
				inst,
				machines,
				possible_machine_travels,
				h,
				best_possible_machine_travel,
				start_h_pos,
			)
		end
		curr_h_pos = Ref(start_h_pos[])
		next_h_pos = Ref(curr_h_pos[] + 1)
		while next_h_pos[] <= length(machines[h])
			trv_1 = find_next_active_machine_travel(machines[h], curr_h_pos)
			next_h_pos[] = curr_h_pos[] + 1

			trv_2 = find_next_active_machine_travel(machines[h], next_h_pos)

			if curr_h_pos[] == 1
				trv_1_end = trv_1.st
				h_arr = trv_1_end + inst.O[(inst.initial_station, inst.f[prev_stop.node][h], h)]
			else
				trv_1_end = trv_1.st + inst.O[(inst.f[trv_1.orig][h], inst.f[trv_1.dest][h], h)]
				h_arr = trv_1_end + inst.O[(inst.f[trv_1.dest][h], inst.f[prev_stop.node][h], h)]
			end
			k_arr = curr_time + inst.d_bar[prev_stop.node, h, k]
			new_trv_end = max(h_arr, k_arr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
			if next_h_pos[] == length(machines[h]) || new_trv_end + inst.O[(inst.f[curr_stop.node][h], inst.f[trv_2.orig][h], h)] <= trv_2.st
				delta_t = new_trv_end - curr_time
				delta_t += inst.d_bar[curr_stop.node, h, k]
				if !best_possible_machine_travel[].found || delta_t < best_possible_machine_travel[].delta_t
					best_possible_machine_travel[] =
						PossibleMachineTravel(true, delta_t, h, next_h_pos[], max(h_arr, k_arr), prev_stop.node, curr_stop.node)
				end
			end
			curr_h_pos[] += 1
			next_h_pos[] += 1
		end
	end
	if !best_possible_machine_travel[].found
		# Shouldn't be executed
		error("Error in get_best_vehicle_travel_time(): it should be always possible to schedule a new machine travel (time windows are checked later)")
	end
	push!(possible_machine_travels[best_possible_machine_travel[].h], best_possible_machine_travel[])

	return best_possible_machine_travel[].delta_t
end # function get_best_vehicle_travel_time()

"""
	function advance_best_time(
		time::Float64,
		prev_stop::VehicleStop,
		curr_stop::VehicleStop,
		k::Int64,
		inst::InstanceData,
		machines::Vector{Vector{MachineTravel}},
		possible_machine_travels::Vector{Vector},
	)::Float64

	Given the current time (time), two vehicle stops (prev_stop and curr_stop), the vehicle index (k),
	the instance data (inst), the machine travels (machines), and the possible machine travels already
	computed (possible_machine_travels), the function advances the time to the best possible service start
	time at curr_stop, considering both a same-region travel and different-region travels.
"""
function advance_best_time(
	time::Float64,
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possible_machine_travels::Vector{Vector},
)
	time += inst.s[prev_stop.node]
	time += get_best_vehicle_travel_time(prev_stop, curr_stop, k, time, inst, machines, possible_machine_travels)
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
		possible_machine_travels::Vector{Vector},
	)::CheckInsertionData

	Given a solution (sol), a vehicle index (k), positions to insert the pickup and delivery
	(p_pos and d_pos), the pickup and delivery job indices (p_job and d_job), the instance data
	(inst), and the possible machine travels already computed (possible_machine_travels), the function
	checks if the insertion is feasible, and if not, computes the cost of the insertion in terms of
	time window and capacity violations.

	The function returns a CheckInsertionData structure with the results of the insertion check 
	to assist the update process.
"""
function check_insertion(
	sol::Solution,
	k::Int64,
	p_pos::Int64,
	d_pos::Int64,
	p_job::Int64,
	d_job::Int64,
	inst::InstanceData,
	possible_machine_travels::Vector{Vector},
)::CheckInsertionData
	feasible = true
	available_vehicle = true
	cost = 0
	load_cost = 0

	prev = p_pos - 1
	curr = p_pos
	prev_stop = sol.vehicles[k][prev]
	curr_stop = VehicleStop(p_job, inst.jobs[inst.refs[p_job]], 0, 0, 0, 0)

	time = prev_stop.serv_start_time
	time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels)
	load = prev_stop.load + curr_stop.job.dem

	if time > curr_stop.job.lat || load > inst.Q[k]
		feasible = false
		cost += max(0, time - curr_stop.job.lat)
		available_vehicle = available_vehicle && !(load > maximum(inst.Q))
		load_cost = max(load_cost, (load - inst.Q[k]) * inst.Q[k])
	end

	prev_stop = curr_stop
	if p_pos != d_pos
		curr_stop = sol.vehicles[k][curr]
		time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels)
		load += curr_stop.job.dem
		if time > curr_stop.job.lat || load > inst.Q[k]
			feasible = false
			cost += max(0, time - curr_stop.job.lat)
			available_vehicle = available_vehicle && !(load > maximum(inst.Q))
			load_cost = max(load_cost, (load - inst.Q[k]) * inst.Q[k])
		end

		prev += 1
		curr += 1
		while curr < d_pos
			prev_stop = sol.vehicles[k][prev]
			curr_stop = sol.vehicles[k][curr]
			time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels)
			load += curr_stop.job.dem
			if time > curr_stop.job.lat || load > inst.Q[k]
				feasible = false
				cost += max(0, time - curr_stop.job.lat)
				available_vehicle = available_vehicle && !(load > maximum(inst.Q))
				load_cost = max(load_cost, (load - inst.Q[k]) * inst.Q[k])
			end	
			prev += 1
			curr += 1
		end
		prev_stop = sol.vehicles[k][prev]
	end

	curr_stop = VehicleStop(d_job, inst.jobs[inst.refs[d_job]], 0, 0, 0, 0)
	time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels)
	load += curr_stop.job.dem
	if time > curr_stop.job.lat
		feasible = false
		cost += max(0, time - curr_stop.job.lat)
	end

	prev_stop = curr_stop
	curr_stop = sol.vehicles[k][curr]
	time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels)
	load += curr_stop.job.dem
	if time > curr_stop.job.lat
		feasible = false
		cost += max(0, time - curr_stop.job.lat)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prev_stop = sol.vehicles[k][prev]
		curr_stop = sol.vehicles[k][curr]
	time += inst.s[prev_stop.node]
	time += get_best_vehicle_travel_time(prev_stop, curr_stop, k, time, inst, sol.machines, possible_machine_travels)
		time = max(time, curr_stop.job.earl)
		if time > curr_stop.job.lat
			feasible = false
			cost += max(0, time - curr_stop.job.lat)
		end
		prev += 1
		curr += 1
	end
	if feasible
		return CheckInsertionData(feasible, cost > 0, load_cost > 0, time - sol.vehicles[k][end].serv_start_time, 0, available_vehicle)
	end

	return CheckInsertionData(feasible, cost > 0, load_cost > 0, cost, load_cost, available_vehicle)
end # function check_insertion()