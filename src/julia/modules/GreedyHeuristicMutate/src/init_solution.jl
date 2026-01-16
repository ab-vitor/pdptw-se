"""
	function tightest_time_windows(inst::InstanceData)::Vector{Int64}

	Returns a vector of request indices sorted by the tightness of their pickup time windows,
	where tightness is defined as the difference between the latest and earliest service times.
"""
function tightest_time_windows(inst::InstanceData)::Vector{Int64}
	reqs = copy(inst.V_p)
	sort!(reqs, by = i -> (inst.jobs[inst.refs[i]].lat - inst.jobs[inst.refs[i]].earl))

	return reqs
end # function tightest_time_windows()

"""
	function init_vehicle_routes(inst::InstanceData)::Vector{Vector{VehicleStop}}

	Initializes the vehicle routes for the given instance data by creating a list of vehicle routes,
	each starting and ending at the depot.

	The function returns a vector of vehicle routes, where each route is represented as a vector of VehicleStop objects.
"""
function init_vehicle_routes(inst::InstanceData)::Vector{Vector{VehicleStop}}
	# Start depot -> 1 in inst.Vprime, which is equivalent to 0 in paper
	first_vehicle_stop = VehicleStop(1, inst.jobs[inst.refs[1]], 0, 0, 0, 0)
	# End depot -> 2*inst.n+2 in inst.Vprime, which is equivalent to 2*n+1 in paper
	last_vehicle_stop = VehicleStop(2 * inst.n + 2, inst.jobs[inst.refs[2*inst.n+2]], 0, 0, 0, 0)

	vehicle_routes = Vector[VehicleStop[copy(first_vehicle_stop), copy(last_vehicle_stop)] for _ in inst.K]
	return vehicle_routes
end # function init_vehicle_routes()

"""
	function init_machine_travels(inst::InstanceData)::Vector{Vector{MachineTravel}}

	Initializes the machine travels for the given instance data by creating a list of machine travels,
	each starting with a dummy MachineTravel object.

	The function returns a vector of machine travels, where each travel is represented as a vector of MachineTravel objects.
"""
function init_machine_travels(inst::InstanceData)::Vector{Vector{MachineTravel}}
	# Insert a dummy MachineTravel in each machine travels list with start time at 0 (code simplification)
	dummy_machine_travel = MachineTravel(0, 0, 0, 0, 0.0, true)
	machine_routes = Vector[MachineTravel[copy(dummy_machine_travel), copy(dummy_machine_travel)] for _ in inst.H]

	return machine_routes
end # function init_machine_travels()

"""
	function get_service_order(inst::InstanceData, params::ParameterData)::Vector{Int64}

	Determines the order in which service requests should be handled based on the specified greedy service order strategy.

	The function returns a vector of request indices representing the service order.
"""
function get_service_order(inst::InstanceData, params::ParameterData)::Vector{Int64}
	if params.greedy_service_order == "tightest_tw"
		return tightest_time_windows(inst)
	end
	error("Service order $(params.greedy_service_order) not implemented.")
end # function get_service_order()

"""
	function init_solution(inst::InstanceData)::Solution

	Initializes a solution for the given instance data by setting up initial vehicle routes,
	machine travels, completion times, and solution statistics.

	The function returns an initialized Solution object.
"""
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
		initial_stats,
	)
end # function init_solution()