function calculate_rate_machine_travel_time(inst::InstanceData, machines, with_vehicle::Bool)
	machines_travel_times = Float64[0 for h in inst.H]
	for h in inst.H
		mach = machines[h]
		previous_f = 1
		for travel in mach
			machines_travel_times[h] += inst.O[(previous_f, inst.f[travel.orig][h], h)]
			previous_f = inst.f[travel.dest][h]
			if with_vehicle
				machines_travel_times[h] += inst.O[(inst.f[travel.orig][h], inst.f[travel.dest][h], h)]
			end
		end
		if length(mach) > 0
			machines_travel_times[h] /= inst.l[inst.depot_begin]
		end
	end
	return machines_travel_times
end # function calculate_rate_machine_travel_time()

function calculate_rate_waiting_times_of_vehicles_for_a_machine_travel(inst::InstanceData, vehicles, machines, completion_times)
	vehicles_waiting_times_for_a_machine_travel = Float64[0 for k in inst.K]
	for k in inst.K
		vehi = vehicles[k]
		for i in eachindex(vehi)[2:end]
			cur = vehi[i-1]
			nxt = vehi[i]
			if nxt.mach > 0
				v_arr = cur.serv_start_time + inst.s[cur.node] + inst.d_bar[cur.node, nxt.mach, k]
				vehicles_waiting_times_for_a_machine_travel[k] += max(0, machines[nxt.mach][nxt.mach_index].st - v_arr)
			end
		end
		if length(vehi) > 2
			vehicles_waiting_times_for_a_machine_travel[k] /= completion_times[k]
		end
	end

	return vehicles_waiting_times_for_a_machine_travel
end # function calculate_rate_waiting_times_of_vehicles_for_a_machine_travel()

function calculate_rate_waiting_time_vehicles_for_a_service(inst::InstanceData, vehicles, completion_times)
	vehicles_waiting_times_for_a_service = Float64[0 for k in inst.K]
	for k in inst.K
		vehi = vehicles[k]
		for i in eachindex(vehi)[2:end]
			cur = vehi[i-1]
			nxt = vehi[i]
			v_arr = cur.serv_start_time + inst.s[cur.node] + inst.d[cur.node, nxt.node, k]
			vehicles_waiting_times_for_a_service[k] += max(0, inst.e[nxt.node] - v_arr)
		end
		if length(vehi) > 2
			vehicles_waiting_times_for_a_service[k] /= completion_times[k]
		end
	end

	return vehicles_waiting_times_for_a_service
end # function calculate_rate_waiting_time_vehicles_for_a_service()

function save_solution_stats(
	inst::InstanceData,
	best_sol::Solution,
	params::ParameterData,
)::SolutionStats
	vehicles = best_sol.vehicles
	machines = best_sol.machines
	completion_times = best_sol.completion_times

	n_vehicles = count(rt -> (length(rt) > 2), vehicles) / length(inst.K)
	n_machines = count(rt -> (length(rt) > 0), machines) / length(inst.H)
	min_completion_time = inst.l[inst.depot_begin]
	max_completion_time = 0
	mean_completion_time = 0
	max_load_vehicle = Float64[0 for _ in inst.K]
	for k in inst.K
		if completion_times[k] > params.epsilon
			min_completion_time = min(min_completion_time, completion_times[k])
			max_completion_time = max(max_completion_time, completion_times[k])
			mean_completion_time += completion_times[k]
		end
		max_load_vehicle[k] = maximum(stop -> stop.load / inst.vehicles[k].cap, vehicles[k])
	end
	mean_completion_time /= count(rt -> (length(rt) > 2), vehicles)

	min_completion_time /= inst.l[inst.depot_begin]
	max_completion_time /= inst.l[inst.depot_begin]
	mean_completion_time /= inst.l[inst.depot_begin]

	machines_travel_times_with_vehicle = calculate_rate_machine_travel_time(inst, machines, true)
	machines_travel_times_no_vehicle = calculate_rate_machine_travel_time(inst, machines, false)

	avrg_machines_travel_time_with_vehicle = sum(machines_travel_times_with_vehicle) / (n_machines * length(inst.H))
	avrg_machines_travel_time_no_vehicle = sum(machines_travel_times_no_vehicle) / (n_machines * length(inst.H))
	avrg_machines_travel_time_only_with_vehicle = avrg_machines_travel_time_with_vehicle - avrg_machines_travel_time_no_vehicle

	vehicles_waiting_times_for_a_machine_travel =
		calculate_rate_waiting_times_of_vehicles_for_a_machine_travel(inst, vehicles, machines, completion_times)
	avrg_vehicles_waiting_time_for_a_machine_travel =
		sum(vehicles_waiting_times_for_a_machine_travel) / (n_vehicles * length(inst.K))
	vehicles_waiting_times_for_a_service = calculate_rate_waiting_time_vehicles_for_a_service(inst, vehicles, completion_times)
	avrg_vehicles_waiting_time_for_a_service = sum(vehicles_waiting_times_for_a_service) / (n_vehicles * length(inst.K))

	max_max_load_all_vehicles = maximum(max_load_vehicle)
	min_max_load_all_vehicles = minimum(filter(load -> load > params.epsilon, max_load_vehicle))
	mean_max_load_all_vehicles = sum(max_load_vehicle) / (n_vehicles * length(inst.K))

	return SolutionStats(
		n_vehicles,
		n_machines,
		max_max_load_all_vehicles,
		min_max_load_all_vehicles,
		mean_max_load_all_vehicles,
		min_completion_time,
		max_completion_time,
		mean_completion_time,
		machines_travel_times_with_vehicle,
		machines_travel_times_no_vehicle,
		max_load_vehicle,
		avrg_machines_travel_time_with_vehicle,
		avrg_machines_travel_time_only_with_vehicle,
		avrg_machines_travel_time_no_vehicle,
		avrg_vehicles_waiting_time_for_a_machine_travel,
		avrg_vehicles_waiting_time_for_a_service,
	)
end # function save_solution_stats()