"""
	function tightest_time_windows(inst::InstanceData)::Vector{Int64}

	Returns a vector of request indices sorted by the tightness of their time windows,
	where tightness is defined as the difference between the latest and earliest service times.
"""
function tightest_time_windows(inst::InstanceData)::Vector{Int64}
	reqs = copy(inst.V_p)
	sort!(reqs, by = i -> (inst.l[i] - inst.e[i]))

	return reqs
end # function tightest_time_windows()

"""
	function random_order_nodes(inst::InstanceData, params::ParameterData)::Vector{Int64}

	Generates a random order of request indices using the random number generator
	specified in `params`. The function returns a vector of request indices in
	random order.
"""
function random_order_nodes(inst::InstanceData, params::ParameterData)::Vector{Int64}
	rkvector = rand(params.rng, Float64, inst.n)
	order_nodes = sortperm(rkvector) .+ 1

	return order_nodes
end # function random_order_nodes

"""
	function init_vehicle_routes(inst::InstanceData)::Vector{Vector{VehicleStop}}

	Initializes the vehicle routes for each vehicle in the instance `inst` by
	creating a route that starts and ends at the depot. Each vehicle route
	contains two stops: the start depot and the end depot (depot's copy).
"""
function init_vehicle_routes(inst::InstanceData)::Vector{Vector{VehicleStop}}
	# Start depot -> 1 in inst.Vprime, which is equivalent to 0 in paper
	first_vehicle_stop = VehicleStop(1, inst.jobs[inst.refs[1]], 0, 0, 0, 0)
	# End depot -> 2*inst.n+2 in inst.Vprime, which is equivalent to 2*n+1 in paper
	last_vehicle_stop = VehicleStop(2 * inst.n + 2, inst.jobs[inst.refs[2*inst.n+2]], 0, 0, 0, 0)

	vehicle_routes = Vector{VehicleStop}[[copy(first_vehicle_stop), copy(last_vehicle_stop)] for _ in inst.K]

	return vehicle_routes
end # function init_vehicle_routes()

"""
	function init_machine_travels(inst::InstanceData)::Vector{Vector{MachineTravel}}

	Initializes the machine travels for each machine in the instance `inst` by
	creating an empty list of machine travels for each machine.
"""
function init_machine_travels(inst::InstanceData)::Vector{Vector{MachineTravel}}
	# Insert a dummy MachineTravel in each machine travels list with start time at 0 (code simplification)
	machine_routes = Vector{MachineTravel}[[] for _ in inst.H]

	return machine_routes
end # function init_machine_travels()

"""
	function get_service_order(inst::InstanceData, params::ParameterData)::Vector{Int64}

	Determines the service order of requests based on the specified strategy
	in `params`. It supports "tightest_tw" for tightest time windows and
	"random" for a random order of requests.
"""
function get_service_order(inst::InstanceData, params::ParameterData)::Vector{Int64}
	if params.greedy_service_order == "tightest_tw"
		return tightest_time_windows(inst)
	elseif params.greedy_service_order == "random"
		return random_order_nodes(inst, params)
	end

	error("Unknown greedy service order: $(params.greedy_service_order)")
end # function get_service_order()

"""
	function init_solution(inst::InstanceData)::Solution

	Initializes a solution for the instance `inst` by creating initial vehicle routes,
	machine travels, and completion times. The solution is set as infeasible with
	a value of 0.0 and default statistics.
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