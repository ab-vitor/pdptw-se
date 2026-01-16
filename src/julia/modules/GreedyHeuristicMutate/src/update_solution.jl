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
			machTrv = sol.machines[h][i]
			sol.vehicles[machTrv.vehicle][machTrv.vehicle_index].mach_index = i
		end
	end
    return nothing
end # function update_machines_indexes

function insert_machine_travel(
	sol::Solution,
	machineTravels::Vector{PossibleMachineTravel},
	lastMachTrv::Ref{Int64},
	lastMachTrvForH::Vector{Int64},
	vehicle_index::Int64,
	k::Int64,
)::Nothing
	machTrv = machineTravels[lastMachTrv[]]
	insert!(
		sol.machines[machTrv.h],
		machTrv.h_pos + lastMachTrvForH[machTrv.h] - 1,
		MachineTravel(k, vehicle_index, machTrv.orig, machTrv.dest, machTrv.st, true),
	)
	lastMachTrv[] += 1
	lastMachTrvForH[machTrv.h] += 1
    return nothing
end # function insert_machine_travel()

function smallest_greater_capacity(vehicle_types::Vector{Vehicle}, load::Int64)::Int64
	idx = searchsortedfirst(vehicle_types, load; lt = (x, y) -> x.cap < y)
	return vehicle_types[idx].cap
end # function smallest_greater_capacity()


function update_solution(sol::Solution, insData::InsertionData, inst::InstanceData)::Solution
	k = insData.k
	p_pos = insData.p_pos
	dPos = insData.dPos
	pJob = insData.pJob
	dJob = insData.dJob
	machineTravels = insData.machineTravels

	deactivate_machine_travels(k, sol, p_pos)

	lastMachTrv = Ref(1)
	lastMachTrvForH = Int64[1 for _ in inst.H]

	prev = p_pos - 1
	curr = p_pos
	prev_stop = sol.vehicles[k][prev]
	pickupStop = VehicleStop(pJob, inst.jobs[inst.refs[pJob]], 0, 0, 0, 0)

	time = prev_stop.servST
	time = advance_time(time, prev_stop, pickupStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load = prev_stop.load + pickupStop.job.dem

	pickupStop.servST = time
	pickupStop.load = load
	if pickupStop.mach != 0
		insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr, k)
	end

	prev_stop = pickupStop
	if p_pos != dPos
		curr_stop = sol.vehicles[k][curr]
		time = advance_time(time, prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
		load += curr_stop.job.dem

		curr_stop.servST = time
		curr_stop.load = load
		if curr_stop.mach != 0
			insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
		end

		prev += 1
		curr += 1
		while curr < dPos
			prev_stop = sol.vehicles[k][prev]
			curr_stop = sol.vehicles[k][curr]
			time = advance_time(time, prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
			load += curr_stop.job.dem

			curr_stop.servST = time
			curr_stop.load = load
			if curr_stop.mach != 0
				insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
			end

			prev += 1
			curr += 1
		end
		prev_stop = sol.vehicles[k][prev]
	end

	deliveryStop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, 0, 0, 0)
	time = advance_time(time, prev_stop, deliveryStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load += deliveryStop.job.dem

	deliveryStop.servST = time
	deliveryStop.load = load
	if deliveryStop.mach != 0
		insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
	end

	prev_stop = deliveryStop
	curr_stop = sol.vehicles[k][curr]
	time = advance_time(time, prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load += curr_stop.job.dem

	curr_stop.servST = time
	if curr_stop.mach != 0
		insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 2, k)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prev_stop = sol.vehicles[k][prev]
		curr_stop = sol.vehicles[k][curr]
		time += inst.s[prev_stop.node]
		time += get_vehicle_travel_time(prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
		time = max(time, curr_stop.job.earl)
		curr_stop.servST = time
		if curr_stop.mach != 0
			insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 2, k)
		end
		prev += 1
		curr += 1
	end

	insert!(sol.vehicles[k], dPos, deliveryStop)
	insert!(sol.vehicles[k], p_pos, pickupStop)
	remove_deactivated_travels(sol)
	update_machines_indexes(sol)

	return sol
end # function update_solution()

function update_solution_with_relaxation(sol::Solution, rlxData::InsertionData, inst::InstanceData)::Solution
	k = rlxData.k
	p_pos = rlxData.p_pos
	dPos = rlxData.dPos
	pJob = rlxData.pJob
	dJob = rlxData.dJob
	machineTravels = rlxData.machineTravels

	deactivate_machine_travels(k, sol, p_pos)

	lastMachTrv = Ref(1)
	lastMachTrvForH = Int64[1 for _ in inst.H]

	prev = p_pos - 1
	curr = p_pos
	prev_stop = sol.vehicles[k][prev]
	pickupStop = VehicleStop(pJob, inst.jobs[inst.refs[pJob]], 0, 0, 0, 0)

	time = prev_stop.servST
	time = advance_time(time, prev_stop, pickupStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load = Int64(prev_stop.load + pickupStop.job.dem)
	if time > pickupStop.job.lat
		delta = ceil(time) - inst.jobs[inst.refs[pickupStop.node]].lat
		inst.jobs[inst.refs[pickupStop.node]].lat += delta
		inst.jobs[inst.refs[pickupStop.node]].earl += delta
	end
	if load > inst.Q[k]
		new_cap = smallest_greater_capacity(inst.vehicle_types, load)
		inst.vehicles[k].cap = new_cap
		inst.Q[k] = new_cap
	end

	pickupStop.servST = time
	pickupStop.load = load
	if pickupStop.mach != 0
		insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr, k)
	end

	prev_stop = pickupStop
	if p_pos != dPos
		curr_stop = sol.vehicles[k][curr]
		time = advance_time(time, prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
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

		curr_stop.servST = time
		curr_stop.load = load
		if curr_stop.mach != 0
			insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
		end

		prev += 1
		curr += 1
		while curr < dPos
			prev_stop = sol.vehicles[k][prev]
			curr_stop = sol.vehicles[k][curr]
			time = advance_time(time, prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
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

			curr_stop.servST = time
			curr_stop.load = load
			if curr_stop.mach != 0
				insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
			end

			prev += 1
			curr += 1
		end
		prev_stop = sol.vehicles[k][prev]
	end

	deliveryStop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, 0, 0, 0)
	time = advance_time(time, prev_stop, deliveryStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load += deliveryStop.job.dem
	if time > deliveryStop.job.lat
		delta = ceil(time) - inst.jobs[inst.refs[deliveryStop.node]].lat
		inst.jobs[inst.refs[deliveryStop.node]].lat += delta
		inst.jobs[inst.refs[deliveryStop.node]].earl += delta
	end

	deliveryStop.servST = time
	deliveryStop.load = load
	if deliveryStop.mach != 0
		insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
	end

	prev_stop = deliveryStop
	curr_stop = sol.vehicles[k][curr]
	time = advance_time(time, prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load += curr_stop.job.dem
	if time > curr_stop.job.lat
		delta = ceil(time) - inst.jobs[inst.refs[curr_stop.node]].lat
		inst.jobs[inst.refs[curr_stop.node]].lat += delta
		inst.jobs[inst.refs[curr_stop.node]].earl += delta
	end

	curr_stop.servST = time
	if curr_stop.mach != 0
		insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 2, k)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prev_stop = sol.vehicles[k][prev]
		curr_stop = sol.vehicles[k][curr]
		time += inst.s[prev_stop.node]
		time += get_vehicle_travel_time(prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
		time = max(time, curr_stop.job.earl)
		if time > curr_stop.job.lat
			delta = ceil(time) - inst.jobs[inst.refs[curr_stop.node]].lat
			inst.jobs[inst.refs[curr_stop.node]].lat += delta
			inst.jobs[inst.refs[curr_stop.node]].earl += delta
		end
		curr_stop.servST = time
		if curr_stop.mach != 0
			insert_machine_travel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 2, k)
		end
		prev += 1
		curr += 1
	end

	insert!(sol.vehicles[k], dPos, deliveryStop)
	insert!(sol.vehicles[k], p_pos, pickupStop)
	remove_deactivated_travels(sol)
	update_machines_indexes(sol)
	inst.jobs[1].earl = 0

	return sol
end # function update_solution_with_relaxation()