function deactivate_machine_travels(k::Int64, sol::Solution, p_pos::Int64)::Nothing
	for h in 1:length(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if sol.machines[h][i].vehicle == k && sol.machines[h][i].vehicle_index >= p_pos
				sol.machines[h][i].active = false
			end
		end
	end
    return nothing
end # function deactivate_machine_travels()

function reactivate_machine_travels(k::Int64, sol::Solution, p_pos::Int64)::Nothing
	for h in 1:length(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if sol.machines[h][i].vehicle == k && sol.machines[h][i].vehicle_index >= p_pos
				sol.machines[h][i].active = true
			end
		end
	end
    return nothing
end # function reactivate_machine_travels()

function reactivate_next_travels(k::Int64, sol::Solution, curr::Int64)::Nothing
	for h in 1:length(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if sol.machines[h][i].vehicle == k && sol.machines[h][i].vehicle_index >= curr
				sol.machines[h][i].active = true
			end
		end
	end
    return nothing
end # function reactivate_next_travels()

function remove_deactivated_travels(sol::Solution)::Nothing
	for h in 1:length(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if !sol.machines[h][i].active
				splice!(sol.machines[h], i)
			end
		end
	end
    return nothing
end # function remove_deactivated_travels()

function update_machines_indexes(sol::Solution)::Nothing
	for h in 1:length(sol.machines)
		for i in eachindex(sol.machines[h])[2:end-1]
			mach_trv = sol.machines[h][i]
			sol.vehicles[mach_trv.vehicle][mach_trv.vehicle_index].mach_index = i
		end
	end
    return nothing
end # function update_machines_indexes

function insert_machine_travel(
	sol::Solution,
	machine_travels::Vector{PossibleMachineTravel},
	lastMachTrv::Ref{Int64},
	lastMachTrvForH::Vector{Int64},
	vehicle_index::Int64,
	k::Int64,
)::Nothing
	mach_trv = machine_travels[lastMachTrv[]]
	insert!(
		sol.machines[mach_trv.h],
		mach_trv.h_pos + lastMachTrvForH[mach_trv.h] - 1,
		MachineTravel(k, vehicle_index, mach_trv.orig, mach_trv.dest, mach_trv.st, true),
	)
	lastMachTrv[] += 1
	lastMachTrvForH[mach_trv.h] += 1
    return nothing
end # function insert_machine_travel()


"""
	function get_vehicle_travel_time(
		prev_stop::VehicleStop,
		curr_stop::VehicleStop,
		k::Int64,
		inst::InstanceData,
		machine_travels::Vector{PossibleMachineTravel},
		last_mach_trv::Ref{Int64},
		last_mach_trv_for_h::Vector{Int64},
	)::Float64

	Given two vehicle stops (prev_stop and curr_stop), the vehicle index (k), the instance data (inst),
	the machine travels already computed (machine_travels), the last machine travel index used (last_mach_trv),
	and the last machine travel index used for each machine (last_mach_trv_for_h), the function returns
	the vehicle travel time between the two stops, considering both a same-region travel and different-region 
	travels.
	If it is a different-region travel, the function also updates the prev_stop and curr_stop with the
	machine used and its index in the machine travels list.
"""
function get_vehicle_travel_time(
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machine_travels::Vector{PossibleMachineTravel},
	last_mach_trv::Ref{Int64},
	last_mach_trv_for_h::Vector{Int64},
)
	if prev_stop.job.point.z == curr_stop.job.point.z
		curr_stop.mach = 0
		return inst.d[prev_stop.node, curr_stop.node, k]
	end

	mach_trv = machine_travels[last_mach_trv[]]
	curr_stop.mach = mach_trv.h
	curr_stop.mach_index = mach_trv.h_pos + last_mach_trv_for_h[mach_trv.h] - 1
	return mach_trv.delta_t

end # function get_vehicle_travel_time()

function advance_time(
	time::Float64,
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machine_travels::Vector{PossibleMachineTravel},
	last_mach_trv::Ref{Int64},
	last_mach_trv_for_h::Vector{Int64},
)::Float64
	time += inst.s[prev_stop.node]
	time += get_vehicle_travel_time(prev_stop, curr_stop, k, inst, machine_travels, last_mach_trv, last_mach_trv_for_h)
	time = max(time, curr_stop.job.earl)
	return time
end # function advance_time()

function smallest_greater_capacity(vehicle_types::Vector{Vehicle}, load::Int64)::Int64
	idx = searchsortedfirst(vehicle_types, load; lt = (x, y) -> x.cap < y)
	return vehicle_types[idx].cap
end # function smallest_greater_capacity()


function update_solution(sol::Solution, insData::InsertionData, inst::InstanceData)::Solution
	k = insData.k
	p_pos = insData.p_pos
	d_pos = insData.d_pos
	p_job = insData.p_job
	d_job = insData.d_job
	machine_travels = insData.machine_travels

	deactivate_machine_travels(k, sol, p_pos)

	lastMachTrv = Ref(1)
	lastMachTrvForH = Int64[1 for _ in inst.H]

	prev = p_pos - 1
	curr = p_pos
	prev_stop = sol.vehicles[k][prev]
	pickup_stop = VehicleStop(p_job, inst.jobs[inst.refs[p_job]], 0, 0, 0, 0)

	time = prev_stop.serv_start_time
	time = advance_time(time, prev_stop, pickup_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
	load = prev_stop.load + pickup_stop.job.dem

	pickup_stop.serv_start_time = time
	pickup_stop.load = load
	if pickup_stop.mach != 0
		insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr, k)
	end

	prev_stop = pickup_stop
	if p_pos != d_pos
		curr_stop = sol.vehicles[k][curr]
		time = advance_time(time, prev_stop, curr_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
		load += curr_stop.job.dem

		curr_stop.serv_start_time = time
		curr_stop.load = load
		if curr_stop.mach != 0
			insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr + 1, k)
		end

		prev += 1
		curr += 1
		while curr < d_pos
			prev_stop = sol.vehicles[k][prev]
			curr_stop = sol.vehicles[k][curr]
			time = advance_time(time, prev_stop, curr_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
			load += curr_stop.job.dem

			curr_stop.serv_start_time = time
			curr_stop.load = load
			if curr_stop.mach != 0
				insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr + 1, k)
			end

			prev += 1
			curr += 1
		end
		prev_stop = sol.vehicles[k][prev]
	end

	delivery_stop = VehicleStop(d_job, inst.jobs[inst.refs[d_job]], 0, 0, 0, 0)
	time = advance_time(time, prev_stop, delivery_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
	load += delivery_stop.job.dem

	delivery_stop.serv_start_time = time
	delivery_stop.load = load
	if delivery_stop.mach != 0
		insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr + 1, k)
	end

	prev_stop = delivery_stop
	curr_stop = sol.vehicles[k][curr]
	time = advance_time(time, prev_stop, curr_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
	load += curr_stop.job.dem

	curr_stop.serv_start_time = time
	if curr_stop.mach != 0
		insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr + 2, k)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prev_stop = sol.vehicles[k][prev]
		curr_stop = sol.vehicles[k][curr]
		time += inst.s[prev_stop.node]
		time += get_vehicle_travel_time(prev_stop, curr_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
		time = max(time, curr_stop.job.earl)
		curr_stop.serv_start_time = time
		if curr_stop.mach != 0
			insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr + 2, k)
		end
		prev += 1
		curr += 1
	end

	insert!(sol.vehicles[k], d_pos, delivery_stop)
	insert!(sol.vehicles[k], p_pos, pickup_stop)
	remove_deactivated_travels(sol)
	update_machines_indexes(sol)

	return sol
end # function update_solution()

function update_solution_with_relaxation(sol::Solution, rlxData::InsertionData, inst::InstanceData)::Solution
	k = rlxData.k
	p_pos = rlxData.p_pos
	d_pos = rlxData.d_pos
	p_job = rlxData.p_job
	d_job = rlxData.d_job
	machine_travels = rlxData.machine_travels

	deactivate_machine_travels(k, sol, p_pos)

	lastMachTrv = Ref(1)
	lastMachTrvForH = Int64[1 for _ in inst.H]

	prev = p_pos - 1
	curr = p_pos
	prev_stop = sol.vehicles[k][prev]
	pickup_stop = VehicleStop(p_job, inst.jobs[inst.refs[p_job]], 0, 0, 0, 0)

	time = prev_stop.serv_start_time
	time = advance_time(time, prev_stop, pickup_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
	load = Int64(prev_stop.load + pickup_stop.job.dem)
	if time > pickup_stop.job.lat
		delta = ceil(time) - inst.jobs[inst.refs[pickup_stop.node]].lat
		inst.jobs[inst.refs[pickup_stop.node]].lat += delta
		inst.jobs[inst.refs[pickup_stop.node]].earl += delta
	end
	if load > inst.Q[k]
		new_cap = smallest_greater_capacity(inst.vehicle_types, load)
		inst.vehicles[k].cap = new_cap
		inst.Q[k] = new_cap
	end

	pickup_stop.serv_start_time = time
	pickup_stop.load = load
	if pickup_stop.mach != 0
		insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr, k)
	end

	prev_stop = pickup_stop
	if p_pos != d_pos
		curr_stop = sol.vehicles[k][curr]
		time = advance_time(time, prev_stop, curr_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
		load += curr_stop.job.dem
		if time > curr_stop.job.lat
			delta = ceil(time) - inst.jobs[inst.refs[curr_stop.node]].lat
			inst.jobs[inst.refs[curr_stop.node]].lat += delta
			inst.jobs[inst.refs[curr_stop.node]].earl += delta
		end
		if load > inst.Q[k]
			new_cap = smallest_greater_capacity(inst.vehicle_types, load)
			inst.vehicles[k].cap = new_cap
			inst.Q[k] = new_cap
		end

		curr_stop.serv_start_time = time
		curr_stop.load = load
		if curr_stop.mach != 0
			insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr + 1, k)
		end

		prev += 1
		curr += 1
		while curr < d_pos
			prev_stop = sol.vehicles[k][prev]
			curr_stop = sol.vehicles[k][curr]
			time = advance_time(time, prev_stop, curr_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
			load += curr_stop.job.dem
			if time > curr_stop.job.lat
				delta = ceil(time) - inst.jobs[inst.refs[curr_stop.node]].lat
				inst.jobs[inst.refs[curr_stop.node]].lat += delta
				inst.jobs[inst.refs[curr_stop.node]].earl += delta
			end
			if load > inst.Q[k]
				new_cap = smallest_greater_capacity(inst.vehicle_types, load)
				inst.vehicles[k].cap = new_cap
				inst.Q[k] = new_cap
			end

			curr_stop.serv_start_time = time
			curr_stop.load = load
			if curr_stop.mach != 0
				insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr + 1, k)
			end

			prev += 1
			curr += 1
		end
		prev_stop = sol.vehicles[k][prev]
	end

	delivery_stop = VehicleStop(d_job, inst.jobs[inst.refs[d_job]], 0, 0, 0, 0)
	time = advance_time(time, prev_stop, delivery_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
	load += delivery_stop.job.dem
	if time > delivery_stop.job.lat
		delta = ceil(time) - inst.jobs[inst.refs[delivery_stop.node]].lat
		inst.jobs[inst.refs[delivery_stop.node]].lat += delta
		inst.jobs[inst.refs[delivery_stop.node]].earl += delta
	end

	delivery_stop.serv_start_time = time
	delivery_stop.load = load
	if delivery_stop.mach != 0
		insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr + 1, k)
	end

	prev_stop = delivery_stop
	curr_stop = sol.vehicles[k][curr]
	time = advance_time(time, prev_stop, curr_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
	load += curr_stop.job.dem
	if time > curr_stop.job.lat
		delta = ceil(time) - inst.jobs[inst.refs[curr_stop.node]].lat
		inst.jobs[inst.refs[curr_stop.node]].lat += delta
		inst.jobs[inst.refs[curr_stop.node]].earl += delta
	end

	curr_stop.serv_start_time = time
	if curr_stop.mach != 0
		insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr + 2, k)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prev_stop = sol.vehicles[k][prev]
		curr_stop = sol.vehicles[k][curr]
		time += inst.s[prev_stop.node]
		time += get_vehicle_travel_time(prev_stop, curr_stop, k, inst, machine_travels, lastMachTrv, lastMachTrvForH)
		time = max(time, curr_stop.job.earl)
		if time > curr_stop.job.lat
			delta = ceil(time) - inst.jobs[inst.refs[curr_stop.node]].lat
			inst.jobs[inst.refs[curr_stop.node]].lat += delta
			inst.jobs[inst.refs[curr_stop.node]].earl += delta
		end
		curr_stop.serv_start_time = time
		if curr_stop.mach != 0
			insert_machine_travel(sol, machine_travels, lastMachTrv, lastMachTrvForH, curr + 2, k)
		end
		prev += 1
		curr += 1
	end

	insert!(sol.vehicles[k], d_pos, delivery_stop)
	insert!(sol.vehicles[k], p_pos, pickup_stop)
	remove_deactivated_travels(sol)
	update_machines_indexes(sol)
	inst.jobs[1].earl = 0

	return sol
end # function update_solution_with_relaxation()