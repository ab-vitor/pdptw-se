
"""
	function advance_time(
		time::Float64,
		prev_stop::VehicleStop,
		curr_stop::VehicleStop,
		k::Int64,
		inst::InstanceData,
		machine_travels::Vector{PossibleMachineTravel},
		last_mach_trv::Ref{Int64},
	)::Float64

	Advances the current time from `prev_stop` to `curr_stop` for vehicle `k`, using
	precomputed machine travels when necessary. It updates the time accordingly and
	ensures it respects the earliest time window of the `curr_stop`.
"""
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



"""
	function insert_machine_travels(
		sol::Solution,
		machine_travels::Vector{PossibleMachineTravel},
		k::Int64,
	)::Nothing

	Inserts the given `machine_travels` into the solution `sol` for vehicle `k`.
	Each machine travel is added to the corresponding machine's travels list
	at the specified position, marking them as active.
"""
function insert_machine_travels(
	sol::Solution,
	machine_travels::Vector{PossibleMachineTravel},
	k::Int64,
)::Nothing
	active = true
	for i in length(machine_travels):-1:1
		mach_trv = machine_travels[i]
		insert!(
			sol.machines[mach_trv.h],
			mach_trv.h_pos,
			MachineTravel(k, mach_trv.vehicle_index, mach_trv.orig, mach_trv.dest, mach_trv.st, active),
		)
	end
	return nothing
end # function insert_machine_travels()

"""
	function update_solution(
		sol::Solution,
		ins_data::InsertionData,
		inst::InstanceData,
	)::Solution

	Updates the solution `sol` by inserting pickup and delivery jobs at specified positions
	for vehicle `k`, as defined in `ins_data`. It recalculates service start times and loads
	for the affected vehicle route, updates machine travels, and adjusts the solution's
	completion times and value accordingly.
"""
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
