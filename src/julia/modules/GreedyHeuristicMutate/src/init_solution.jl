function tightest_time_windows(inst::InstanceData)
	reqs = copy(inst.V_p)
	sort!(reqs, by = i -> (inst.jobs[inst.refs[i]].lat - inst.jobs[inst.refs[i]].earl))

	return reqs
end # function tightest_time_windows()

function earliest_time_windows(inst::InstanceData)
	reqs = copy(inst.V_p)
	sort!(reqs, by = i -> inst.jobs[inst.refs[i]].lat)

end # function earliest_time_windows()

function init_vehicle_routes(inst::InstanceData)
	# Start depot -> 1 in inst.Vprime, which is equivalent to 0 in paper
	firstVehicleStop = VehicleStop(1, inst.jobs[inst.refs[1]], 0, 0, 0, 0)
	# End depot -> 2*inst.n+2 in inst.Vprime, which is equivalent to 2*n+1 in paper
	lastVehicleStop = VehicleStop(2 * inst.n + 2, inst.jobs[inst.refs[2*inst.n+2]], 0, 0, 0, 0)

	vehicleRoutes = Vector[VehicleStop[copy(firstVehicleStop), copy(lastVehicleStop)] for _ in inst.K]

	return vehicleRoutes
end # function init_vehicle_routes()

function init_machine_travels(inst::InstanceData)
	# Insert a dummy MachineTravel in each machine travels list with start time at 0 (code simplification)
	dummyMachineTravel = MachineTravel(0, 0, 0, 0, 0.0, true)
	machineRoutes = Vector[MachineTravel[copy(dummyMachineTravel), copy(dummyMachineTravel)] for _ in inst.H]

	return machineRoutes
end # function init_machine_travels()

function get_service_order(inst::InstanceData, params::ParameterData)
	if params.greedy_service_order == "tightest_tw"
		return tightest_time_windows(inst)
	elseif params.greedy_service_order == "earliest_tw"
		return earliest_time_windows(inst)
	end

	return inst.V_p # just in case
end # function get_service_order()

function init_solution(inst::InstanceData)
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
		initial_stats,
	)
end # function init_solution()