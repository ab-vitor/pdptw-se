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


mutable struct InstanceData
	name::String # instance name
	group::String # group name
	type::String # type of instance
	full_name::String # full name of instance
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
	q::Vector{Int64} # demands
	K::Vector{Int64} # vehicles
	Q::Vector{Int64} # capacities
	d::Array{Float64, 3} # dist from node i to node j using vehicle k
	H::Vector{Int64} # machines
	H_e::Vector{Vector{Vector{Int64}}} # for each arc, the machines that can attend
	d_bar::Array{Float64, 3} # distance from node i to machine h using vehicle k
	f::Vector{Vector{Int64}} # z-pos for machine h considering node i (-1 if the machine is not on node's z-pos)
	O::Dict{Tuple{Int64, Int64, Int64}, Float64} # dist from z-pos of node i to z-pos of node j using machine h
	n::Int64 # number of requests
	s::Vector{Int64} # service time at node i
	depot_begin::Int64 # 1
	depot_end::Int64 # 2*n+2
	initial_station::Int64 # 1
	first_pickup::Int64 # 2
	last_pickup::Int64 # n+1
	first_delivery::Int64 # n+2
	last_delivery::Int64 # 2*n+1

	function InstanceData()
		name = ""
		group = ""
		type = ""
		full_name = ""
		vehicles = Vehicle[]
		vehicle_types = Vehicle[]
		jobs = Job[]
		machines = Machine[]
		refs = Int64[]
		V = Int64[]
		V_p = Int64[]
		V_d = Int64[]
		V_p_d = Int64[]
		Vprime = Int64[]
		e = Int64[]
		l = Int64[]
		q = Int64[]
		K = Int64[]
		Q = Int64[]
		d = Array{Float64, 3}(undef, 0, 0, 0)
		H = Int64[]
		H_e = Vector{Vector{Vector{Int64}}}()
		d_bar = Array{Float64, 3}(undef, 0, 0, 0)
		f = Vector{Vector{Int64}}()
		O = Dict{Tuple{Int64, Int64, Int64}, Float64}()
		n = 0
		s = Int64[]
		depot_begin = 0
		depot_end = 0
		initial_station = 0
		first_pickup = 0
		last_pickup = 0
		first_delivery = 0
		last_delivery = 0
		return new(
			name,
			group,
			type,
			full_name,
			vehicles,
			vehicle_types,
			jobs,
			machines,
			refs,
			V,
			V_p,
			V_d,
			V_p_d,
			Vprime,
			e,
			l,
			q,
			K,
			Q,
			d,
			H,
			H_e,
			d_bar,
			f,
			O,
			n,
			s,
			depot_begin,
			depot_end,
			initial_station,
			first_pickup,
			last_pickup,
			first_delivery,
			last_delivery,
		)
	end
end