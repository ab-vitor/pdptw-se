mutable struct Vehicle
	id::Int64
	cap::Int64
	Vehicle(l) = new(parse(Int64, l[1]), parse(Int64, l[2]))
end

mutable struct Point
	x::Int64
	y::Int64
	z::Int64
	Point(l) = new(parse(Int64, l[1]), parse(Int64, l[2]), parse(Int64, l[3]))
end

mutable struct Job
	id::Int64
	point::Point
	dem::Int64
	earl::Int64
	lat::Int64
	servt::Int64
	pid::Int64
	did::Int64
	Job(l) = new(
		parse(Int64, l[1]),
		Point(l[2:4]),
		parse(Int64, l[5]),
		parse(Int64, l[6]),
		parse(Int64, l[7]),
		parse(Int64, l[8]),
		parse(Int64, l[9]),
		parse(Int64, l[10]),
	)
end

mutable struct Machine
	id::Int64
	points::Vector{Point}
	spd::Float64
	Machine(l) = new(parse(Int64, l[1]), [Point(l[2:4])], parse(Float64, l[5]))
end

mutable struct PreprocessingData
	arcs::Int64
	arc_removals::Int64
	arc_removals_is_loop::Int64
	arc_removals_is_delivery_to_pickup::Int64
	arc_removals_is_depot_begin_to_delivery::Int64
	arc_removals_is_pickup_to_depot_end::Int64
	arc_removals_is_dest_depot_begin::Int64
	arc_removals_is_orig_depot_end::Int64
    arc_removals_is_capacity_violated:: Int64
	arc_removals_is_time_window_limited::Int64
    arc_removals_is_time_window_pairing_limited::Int64
	arc_removals_is_indirect_request_service_impossible::Int64
    gamma_vars::Int64
    feas_gamma_vars::Int64
    infeas_gamma_vars_is_next_mtrv_unreachable::Int64
    infeas_gamma_vars_is_iprime_jprime_eq_i_j::Int64
    machine_removal_for_an_arc::Int64
	PreprocessingData() = new(
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	)
end

mutable struct InstanceData
	name::String # instance name
	group::String # group name
	type::String # type of instance
	fullname::String # full name of instance
	vehicles::Vector{Vehicle} # list of vehicles
	vehicle_types::Vector{Vehicle} # list of vehicle types
	jobs::Vector{Job} # list of requests
	machines::Vector{Machine} # list of machines
	refs::Vector{Int64} # the corresponded position of a node in jobs
	V::Vector{Int64} # the nodes as in the article
	V_p::Vector{Int64} # the nodes of pickup
	V_d::Vector{Int64} # the nodes of delivery
	V_p_d::Vector{Int64} # V_p \cup V_d
	Vprime::Vector{Int64} # all the nodes, including a returning depot
	e::Vector{Int64} # early time for i in Vprime
	l::Vector{Int64} # late time for i in Vprime
	eprime::Vector{Float64} # early possible time for i in Vprime given any vehicle
	lprime::Vector{Float64} # late possible time for i in Vprime given any vehicle
	q::Vector{Int64} # demands
	max_q::Int64 # maximum demand
	K::Vector{Int64} # vehicles
	Q::Vector{Int64} # capacities
	max_Q::Int64 # maximum capacity
	d::Array{Float64, 3} # dist from node i to node j using vehicle k
	dmax_vehicle::Array{Float64, 2} # dist max from node i to node j from all vehicles
	dmin_vehicle::Array{Float64, 2} # dist min from node i to node j from all vehicles
	max_d::Float64 # dist max in `d`
	A::Vector{Tuple{Int64, Int64}} # all POSSIBLE arcs (i,j), where i is the start node and j is the end node
	A_m::Vector{Tuple{Int64, Int64}} # subset of A for arcs that need to use the machine
	A_s::Vector{Tuple{Int64, Int64}} # subset of A, where A_s = A \ A_m
    feas_gamma::Array{Float64, 5}
	H::Vector{Int64} # machines
	H_e::Vector{Vector{Vector{Int64}}} # for each arc, the machines that can attend
	H_eprime::Vector{Vector{Vector{Vector{Vector{Int64}}}}} # for each arc, the machines that can attend
	d_bar::Array{Float64, 3} # distance from node i to machine h using vehicle k
	d_bar_min::Array{Float64, 2} # minimum distance from node i to machine h from all vehicles k
	d_bar_max::Array{Float64, 2} # maximum distance from node i to machine h from all vehicles k
	f::Vector{Vector{Int64}} # z-pos for machine h considering node i (-1 if the machine is not on node's z-pos)
	O::Dict{Tuple{Int64, Int64, Int64}, Float64} # dist from z-pos of node i to z-pos of node j using machine h
	n::Int64 # number of requests
	s::Vector{Int64} # service time at node i
	max_s::Int64 # maximum service time
	M::Vector{Int64} # big m constants
	L_K::Vector{Int64} # order positions for a truck k 
	L_H::Vector{Int64} # order positions for a machine h
	F_h::Vector{Vector{Int64}} # regions attended by machine h
	S_h::Vector{Vector{Int64}} # machine h stations points indexes
	Sprime_h::Vector{Vector{Int64}} # machine h stations points indexes + dummy end station
	depot_begin::Int64 # 1
	depot_end::Int64 # 2*n+2
	initial_station::Int64 # 1
	first_pickup::Int64 # 2
	last_pickup::Int64 # n+1
	first_delivery::Int64 # n+2
	last_delivery::Int64 # 2*n+1
	ppd::PreprocessingData
	InstanceData() = new(
		"", "", "", "",
		Vehicle[], Vehicle[], Job[], Machine[], Int64[], Int64[], Int64[], Int64[], Int64[], Int64[],
		Int64[], Int64[], Int64[], Int64[], Int64[], 0, Int64[], Int64[], 0,
		zeros(Float64, 0, 0, 0), zeros(Float64, 0, 0), zeros(Float64, 0, 0), 0.0,
		Tuple{Int64, Int64}[], Tuple{Int64, Int64}[], Tuple{Int64, Int64}[], zeros(Float64, 0, 0, 0, 0, 0),
		Int64[], Vector{Vector{Vector{Int64}}}(), Vector{Vector{Vector{Vector{Vector{Int64}}}}}(), 
        zeros(Float64, 0, 0, 0), zeros(Float64, 0, 0), zeros(Float64, 0, 0),
		Vector{Vector{Int64}}(), Dict{Tuple{Int64, Int64, Int64}, Float64}(),
		0, Int64[], 0, Int64[], Int64[], Int64[], Vector{Vector{Int64}}(), Vector{Vector{Int64}}(), Vector{Vector{Int64}}(),
		0, 0, 0, 0, 0, 0, 0, PreprocessingData()
	)
end