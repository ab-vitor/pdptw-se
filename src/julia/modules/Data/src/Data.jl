module Data

using Statistics
using Printf
using Dates
using Parameters

include("structures.jl")
include("auxiliary_functions.jl")
include("preprocessing.jl")

export InstanceData, readData, Vehicle, Job, Machine, Point, instanceDataToCsvFiles

function read_files(inst::InstanceData, params::ParameterData)::Nothing
	vehicles = string(params.instPath, "vehicles.csv")
	jobs = string(params.instPath, "jobs.csv")
	machines = string(params.instPath, "machines.csv")

	f_vehicles = open(vehicles)
	f_jobs = open(jobs)
	f_machines = open(machines)

	fText_vehicles = read(f_vehicles, String)
	fText_jobs = read(f_jobs, String)
	fText_machines = read(f_machines, String)

	list_vehicles = split(fText_vehicles, '\n')
	list_jobs = split(fText_jobs, '\n')
	list_machines = split(fText_machines, '\n')

	inst.vehicles = Vehicle[]
	for i in 1:length(list_vehicles)-1
		splited = split(list_vehicles[i], ',')
		push!(inst.vehicles, Vehicle(splited))
	end
	println("vehicles: ", inst.vehicles)
	vehicle_types = deepcopy(inst.vehicles)
	inst.vehicle_types = sort(unique(x -> x.cap, vehicle_types), by = x -> x.cap)
	println("vehicle_types: ", inst.vehicle_types)

	inst.jobs = Job[]
	for i in 1:length(list_jobs)-1
		splited = split(list_jobs[i], ',')
		push!(inst.jobs, Job(splited))
	end

	inst.machines = Machine[]
	for i in 1:length(list_machines)-1
		splited = split(list_machines[i], ',')
		pos = findfirst(m -> m.id == parse(Int64, splited[1]), inst.machines)
		if pos !== nothing
			push!(inst.machines[pos].points, Point(splited[2:4]))
		else
			push!(inst.machines, Machine(splited))
		end
	end
	if params.cutoffmachs > 0
		params.cutoffmachs = min(length(inst.machines), params.cutoffmachs)
	else
		params.cutoffmachs = length(inst.machines)
	end
	while !params.make_instance_feasible && length(inst.machines) > params.cutoffmachs
		pop!(inst.machines)
	end
	println(inst.machines)
	return nothing
end

function build_refs(inst::InstanceData, params::ParameterData)::Nothing
	cutoff = params.cutoff
	if cutoff == 0
		cutoff = div(length(inst.jobs) - 1, 2)
	end
	inst.n = cutoff
	# With these lists we can access pickup and delivery jobs in order
	# like: First Job: 	<jobs[inst.refs[1]].id, jobs[inst.refs[n+1]].id, jobs[inst.refs[1]].dem>
	#					 	<v_1, v_{n+1}, q_1>
	inst.refs = Int64[]
	push!(inst.refs, 1)
	for i in eachindex(inst.jobs)
		cust = inst.jobs[i]
		if cust.dem > 0
			push!(inst.refs, i)
		end
		if length(inst.refs) == cutoff + 1
			break
		end
	end
	for pid in inst.refs[2:inst.n+1], i in eachindex(inst.jobs)
		if inst.jobs[pid].did == inst.jobs[i].id
			push!(inst.refs, i)
		end
	end
	push!(inst.refs, 1)
	println("refs: ", inst.refs)
	# println(inst.refs)
	return nothing
end

function build_constants(inst::InstanceData)::Nothing
	inst.depot_begin = 1
	inst.depot_end = 2 * inst.n + 2
	inst.initial_station = 1
	inst.first_pickup = 2
	inst.last_pickup = inst.n + 1
	inst.first_delivery = inst.n + 2
	inst.last_delivery = 2 * inst.n + 1
	return nothing
end

function build_vertice_sets(inst::InstanceData)::Nothing
	inst.V = Int64[]
	for i in inst.depot_begin:inst.last_delivery
		push!(inst.V, i)
	end
	println("V: ", inst.V)

	inst.V_p = Int64[i for i in inst.first_pickup:inst.last_pickup]
	println("V_p: ", inst.V_p)

	inst.V_d = Int64[i for i in inst.first_delivery:inst.last_delivery]
	println("V_d: ", inst.V_d)

	inst.V_p_d = copy(inst.V[2:end])

	inst.Vprime = copy(inst.V)
	push!(inst.Vprime, inst.depot_end)

	println("Vprime: ", inst.Vprime)
	println("V: ", inst.V)

	return nothing
end

function build_vehicle_sets(inst::InstanceData)::Nothing
	inst.K = Int64[]
	for i in 1:length(inst.vehicles)
		push!(inst.K, i)
	end
	# println("K: ", inst.K)

	inst.Q = Int64[]
	for k in inst.K
		push!(inst.Q, inst.vehicles[k].cap)
	end
	# println("Q: ", inst.Q)

	inst.max_Q = maximum(inst.Q)
	# println("max_Q: ", inst.max_Q)
	return nothing
end

function build_H(inst::InstanceData, params::ParameterData)::Nothing
	inst.H = Int64[]
	for i in 1:params.cutoffmachs
		push!(inst.H, i)
	end
	println("H: ", inst.H)
	return nothing
end

function build_d_bar(inst::InstanceData)::Nothing
	# symmetrical 
	inst.d_bar::Array{Float64, 3} = zeros(Float64, (length(inst.Vprime), length(inst.H), length(inst.K)))
	for i in inst.Vprime, h in inst.H, k in inst.K
		pos = findfirst(p -> p.z == inst.jobs[inst.refs[i]].point.z, inst.machines[h].points)
		if pos !== nothing
			inst.d_bar[i, h, k] = euclidean_dist(inst.jobs[inst.refs[i]].point, inst.machines[h].points[pos], 0)
		else
			inst.d_bar[i, h, k] = Inf64
		end
	end
	inst.d_bar_min::Array{Float64, 2} = zeros(Float64, (length(inst.Vprime), length(inst.H)))
	inst.d_bar_max::Array{Float64, 2} = zeros(Float64, (length(inst.Vprime), length(inst.H)))
	for i in inst.Vprime, h in inst.H
		inst.d_bar_min[i, h] = minimum(inst.d_bar[i, h, :])
		inst.d_bar_max[i, h] = maximum(inst.d_bar[i, h, :])
	end
	return nothing
end

function build_station_point_mapper(inst::InstanceData)::Nothing
	inst.f = Vector[]
	for i in inst.Vprime
		push!(inst.f, Int64[])
		for h in inst.H
			pos = findfirst(p -> p.z == inst.jobs[inst.refs[i]].point.z, inst.machines[h].points)
			if pos !== nothing
				push!(inst.f[i], pos)
			else
				push!(inst.f[i], -1)
			end
		end
	end
	println("f: ", inst.f)
	return nothing
end

function build_O(inst::InstanceData, params::ParameterData)::Nothing
	inst.O::Dict{Tuple{Int64, Int64, Int64}, Float64} = Dict{Tuple{Int64, Int64, Int64}, Float64}()
	for h in inst.H
		for i in 1:length(inst.machines[h].points)
			for j in 1:length(inst.machines[h].points)
				dist = euclidean_dist(inst.machines[h].points[i], inst.machines[h].points[j], params.elevator) / inst.machines[h].spd
				println(i, " ", j, " ", h, " -> ", dist)
				inst.O[(i, j, h)] = dist
			end
		end
	end
	# for h in inst.H
	# 	for i in 1:length(inst.machines[h].points)
	# 		inst.O[(i, inst.Sprime_h[h][end], h)] = 0
	# 	end
	# end
	for o in inst.O
		println("o: ", o)
	end
	println()
	# println("O: ", inst.O)
	return nothing
end

function can_be_used_to_traverse_the_arc(i::Int, j::Int, h::Int, inst::InstanceData)::Bool
	job_i_z = inst.jobs[inst.refs[i]].point.z
	job_j_z = inst.jobs[inst.refs[j]].point.z
	has_station_for_i = any(p -> p.z == job_i_z, inst.machines[h].points)
	has_station_for_j = any(p -> p.z == job_j_z, inst.machines[h].points)

	return has_station_for_i && has_station_for_j
end

function build_H_e(inst::InstanceData)::Nothing
	inst.H_e = Vector[]
	for i in inst.Vprime
		push!(inst.H_e, Vector[])
		for j in inst.Vprime
			push!(inst.H_e[i], Int64[])
			for h in inst.H
				if findfirst(p -> p.z == inst.jobs[inst.refs[i]].point.z, inst.machines[h].points) !== nothing &&
				   findfirst(p -> p.z == inst.jobs[inst.refs[j]].point.z, inst.machines[h].points) !== nothing
					push!(inst.H_e[i][j], h)
				end
			end
		end
	end
	# println("H_e ", inst.H_e)
	return nothing
end

function build_H_eprime(inst::InstanceData)::Nothing
	inst.H_eprime = []
	for i in inst.Vprime
		push!(inst.H_eprime, [])
		for j in inst.Vprime
			push!(inst.H_eprime[i], [])
			for iprime in inst.Vprime
				push!(inst.H_eprime[i][j], [])
				for jprime in inst.Vprime
					set1 = Set(inst.H_e[i][j])
					set2 = Set(inst.H_e[iprime][jprime])
					intersection = collect(intersect(set1, set2))
					push!(inst.H_eprime[i][j][iprime], intersection)
				end
			end
		end
	end
	return nothing
end

function build_d(inst::InstanceData)::Nothing
	inst.d::Array{Float64, 3} = zeros(Float64, (length(inst.Vprime), length(inst.Vprime), length(inst.K)))
	for i in inst.Vprime, j in inst.Vprime, k in inst.K
		if inst.jobs[inst.refs[i]].point.z == inst.jobs[inst.refs[j]].point.z
			inst.d[i, j, k] = euclidean_dist(inst.jobs[inst.refs[i]].point, inst.jobs[inst.refs[j]].point, 0)
		else
			inst.d[i, j, k] =
				minimum([inst.d_bar[i, h, k] + inst.d_bar[j, h, k] + inst.O[(inst.f[i][h], inst.f[j][h], h)] for h in inst.H_e[i][j]])
		end
	end

	return nothing
end

function build_requests(inst::InstanceData)::Nothing
	inst.e = Int64[inst.jobs[inst.refs[i]].earl for i in inst.Vprime]
	inst.l = Int64[inst.jobs[inst.refs[i]].lat for i in inst.Vprime]

	inst.q = Int64[]
	for i in inst.Vprime
		push!(inst.q, inst.jobs[inst.refs[i]].dem)
	end
	println("q: ", inst.q)

	inst.max_q = maximum(inst.q)

	inst.s = Int64[]
	for i in inst.Vprime
		push!(inst.s, inst.jobs[inst.refs[i]].servt)
	end
	inst.max_s = maximum(inst.s)
	return nothing
end

function build_arcs(inst::InstanceData)::Nothing
	inst.A = Tuple{Int64, Int64}[]
	inst.ppd.arcs = length(inst.Vprime) * length(inst.Vprime)
	for i in inst.Vprime, j in inst.Vprime
		if !is_arc_infeasible(i, j, inst)
			push!(inst.A, (i, j))
		end
	end
	# println("A: ", inst.A)

	inst.A_m = Tuple{Int64, Int64}[]
	inst.A_s = Tuple{Int64, Int64}[]
	for (i, j) in inst.A
		if inst.jobs[inst.refs[i]].point.z != inst.jobs[inst.refs[j]].point.z
			push!(inst.A_m, (i, j))
		else
			push!(inst.A_s, (i, j))
		end
	end
	# println("A_m: ", inst.A_m)
	# println("A_s: ", inst.A_s)
	return nothing
end

function build_barbosa_formulation_data(inst::InstanceData)::Nothing
	inst.L_K = copy(inst.Vprime)
	length_L_H = 0
	for i in inst.V_p
		nodes = Int64[1, i, i+inst.n, 1]
		for j in eachindex(nodes)[2:end]
			if inst.jobs[inst.refs[nodes[j]]].point.z != inst.jobs[inst.refs[nodes[j-1]]].point.z
				length_L_H += 1
			end
		end
	end
	inst.L_H = Int64[i for i in 1:length_L_H]
	println("L_K: ", inst.L_K)
	println("L_H: ", inst.L_H)

	inst.F_h = Vector[]
	for h in inst.H
		push!(inst.F_h, Int64[])
		for mpt in inst.machines[h].points
			push!(inst.F_h[h], mpt.z)
		end
	end
	println("F_h: ", inst.F_h)

	inst.S_h = Vector[]
	for h in inst.H
		push!(inst.S_h, Int64[])
		for i in 1:length(inst.F_h[h])
			push!(inst.S_h[h], i)
		end
	end
	println("S_h: ", inst.S_h)

	inst.Sprime_h = deepcopy(inst.S_h)
	for h in inst.H
		push!(inst.Sprime_h[h], length(inst.F_h[h]) + 1)
	end
	println("Sprime_h: ", inst.Sprime_h)
	return nothing
end

function build_minimums_and_maximums(inst::InstanceData)::Nothing
	inst.dmax_vehicle::Array{Float64, 2} = zeros(Float64, (length(inst.Vprime), length(inst.Vprime)))
	for i in inst.Vprime, j in inst.Vprime
		inst.dmax_vehicle[i, j] = maximum(inst.d[i, j, :])
	end
	inst.dmin_vehicle::Array{Float64, 2} = zeros(Float64, (length(inst.Vprime), length(inst.Vprime)))
	for i in inst.Vprime, j in inst.Vprime
		inst.dmin_vehicle[i, j] = minimum(inst.d[i, j, :])
	end
end

function build_feas_gamma(inst::InstanceData)::Nothing
	inst.feas_gamma = zeros(Float64, length(inst.Vprime), length(inst.Vprime), length(inst.Vprime), length(inst.Vprime), length(inst.H))
	for (i, j) in inst.A_m
		for (ip, jp) in inst.A_m
			for h in intersect(inst.H_e[i][j], inst.H_e[ip][jp])
				inst.ppd.gamma_vars += 1
				if is_precede_possible(i, j, ip, jp, h, inst)
					inst.feas_gamma[i, j, ip, jp, h] = 1.0
					inst.ppd.feas_gamma_vars += 1
				end
			end
		end
	end
	return nothing
end

function build_big_M(inst::InstanceData)::Nothing
	inst.max_d::Float64 = maximum(inst.d)

	inst.M = Int64[]

	M1 = inst.max_Q + inst.max_q + 1
	M1 = ceil(M1)
	push!(inst.M, M1)

	M2 = inst.jobs[1].lat + inst.max_s + inst.max_d + 1
	M2 = ceil(M2)
	push!(inst.M, M2)

	M3 = inst.jobs[1].lat + inst.max_d + 1
	M3 = ceil(M3)
	push!(inst.M, M3)

	max_d_bar = maximum([inst.d_bar[i, h, k] for i in inst.Vprime for h in inst.H for k in inst.K if inst.f[i][h] != -1])
	M4 = inst.jobs[1].lat + inst.max_s + max_d_bar + 1
	M4 = ceil(M4)
	push!(inst.M, M4)

	M5 = inst.jobs[1].lat + max_d_bar + 1
	M5 = ceil(M5)
	push!(inst.M, M5)

	max_O =
		maximum([inst.O[(i, j, h)] for h in inst.H for i in 1:length(inst.machines[h].points) for j in 1:length(inst.machines[h].points)])
	M6 = inst.jobs[1].lat + max_O + max_d_bar + 1
	M6 = ceil(M6)
	push!(inst.M, M6)

	M7 = inst.jobs[1].lat + 2 * max_O + 1
	M7 = ceil(M7)
	push!(inst.M, M7)

	M8 = max_O + 1
	M8 = ceil(M8)
	push!(inst.M, M8)
	println(inst.M)
	return nothing
end

function print_jobs(inst::InstanceData)::Nothing
	println("JOBS in the order of refs (Vprime)")
	for i in inst.Vprime
		ref = inst.refs[i]
		println("Node ", i, ": ", inst.jobs[ref])
	end
	return nothing
end

function print_preprocessingdata(ppd::PreprocessingData)::Nothing
	println()
	println("### Preprocessing Data ###")
	for field in fieldnames(typeof(ppd))
		fname = String(field)
		value = getfield(ppd, field)
		if occursin("arc", fname)
			perc = ppd.arcs != 0 ? round(100 * value / ppd.arcs; digits = 2) : 0
			println("\t-> $(fname): $(value) ($(perc)%)")
		elseif occursin("gamma", fname)
			perc = ppd.gamma_vars != 0 ? round(100 * value / ppd.gamma_vars; digits = 2) : 0
			println("\t-> $(fname): $(value) ($(perc)%)")
		elseif occursin("machine", fname)
			println("\t-> $(fname): $(value)")
		end
	end
	println("##########################")
	return nothing
end

function readData(params::ParameterData, instPath::Union{Nothing, String} = nothing)::InstanceData
	if instPath !== nothing
		params.instPath = instPath
		Parameters.saveInstanceFullName!(params)
	end
	println("\n[$(Dates.Time(Dates.now()))] Running Data.readData with file $(params.instPath)")
	inst = InstanceData()

	inst.name = params.name
	inst.group = params.group
	inst.type = params.type
	inst.fullname = params.fullname

	# * The building order matters
	read_files(inst, params)
	build_refs(inst, params)
	build_constants(inst)
	build_vertice_sets(inst)
	build_vehicle_sets(inst)
	build_requests(inst)
	build_H(inst, params)
	build_d_bar(inst)
	build_station_point_mapper(inst)
	build_O(inst, params)
	build_H_e(inst)
	# build_H_eprime(inst)
	build_d(inst)
	build_minimums_and_maximums(inst)
	build_eprime_lprime!(inst)
	build_arcs(inst)
	build_big_M(inst)
	# preprocess_H_e!(inst)
	# build_H_eprime(inst)
	# build_feas_gamma(inst)

	print_jobs(inst)
	print_preprocessingdata(inst.ppd)
	return inst
end # function readData()

function instanceDataToCsvFiles(inst::InstanceData, params::ParameterData, methodCode::String)::Nothing
	original_path = pwd()
	cd(params.instPath)
	cd("../../../")
	group = inst.group
	if endswith(inst.group, "03M")
		group = replace(inst.group, "03M" => "04M")
	elseif endswith(inst.group, "05M")
		group = replace(inst.group, "05M" => "06M")
	end

	feasible_inst_path = string("../", basename(pwd()), "_f", methodCode, "/", group, "/", inst.type, "/", inst.name)
	if !ispath(feasible_inst_path)
		mkpath(feasible_inst_path)
	end
	cd(feasible_inst_path)

	vehicles = "vehicles.csv"
	jobs = "jobs.csv"
	machines = "machines.csv"

	open(vehicles, "w") do file
		for vehicle in inst.vehicles
			write(file, "$(vehicle.id),$(vehicle.cap)\n")
		end
	end

	open(jobs, "w") do file
		for job in inst.jobs
			write(
				file,
				"$(job.id),$(job.point.x),$(job.point.y),$(job.point.z),$(job.dem),$(job.earl),$(job.lat),$(job.servt),$(job.pid),$(job.did)\n",
			)
		end
	end

	open(machines, "w") do file
		for machine in inst.machines
			for point in machine.points
				write(file, "$(machine.id),$(point.x),$(point.y),$(point.z),$(machine.spd)\n")
			end
		end
	end

	cd(original_path)
	return nothing
end # function instanceDataToCsvFiles()

include("Statistics.jl")

end # module Data
