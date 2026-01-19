module Data

using Statistics
using Printf
using Dates
using Parameters

include("structures.jl")
include("auxiliary_functions.jl")
include("statistics.jl")

export InstanceData, read_data, Vehicle, Job, Machine, Point, instance_data_to_csv_files

function read_files(inst::InstanceData, params::ParameterData)::Nothing
	vehicles = string(params.inst_path, "vehicles.csv")
	jobs = string(params.inst_path, "jobs.csv")
	machines = string(params.inst_path, "machines.csv")

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
	if params.cut_off_machs > 0
		params.cut_off_machs = min(length(inst.machines), params.cut_off_machs)
	else
		params.cut_off_machs = length(inst.machines)
	end
	while !params.make_instance_feasible && length(inst.machines) > params.cut_off_machs
		pop!(inst.machines)
	end
	println(inst.machines)
	return nothing
end

function build_refs(inst::InstanceData, params::ParameterData)::Nothing
	cut_off = params.cut_off
	if cut_off == 0
		cut_off = div(length(inst.jobs) - 1, 2)
	end
	inst.n = cut_off
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
		if length(inst.refs) == cut_off + 1
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

	return nothing
end

function build_H(inst::InstanceData, params::ParameterData)::Nothing
	inst.H = Int64[]
	for i in 1:params.cut_off_machs
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
	for o in inst.O
		println("o: ", o)
	end
	println()
	# println("O: ", inst.O)
	return nothing
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


	inst.s = Int64[]
	for i in inst.Vprime
		push!(inst.s, inst.jobs[inst.refs[i]].servt)
	end
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

function read_data(params::ParameterData, inst_path::Union{Nothing, String} = nothing)::InstanceData
	if inst_path !== nothing
		params.inst_path = inst_path
		Parameters.save_instance_full_name!(params)
	end
	println("\n[$(Dates.Time(Dates.now()))] Running Data.read_data with file $(params.inst_path)")
	inst = InstanceData()

	inst.name = params.name
	inst.group = params.group
	inst.type = params.type
	inst.full_name = params.full_name

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
	build_d(inst)

	print_jobs(inst)
	return inst
end # function read_data()

function instance_data_to_csv_files(inst::InstanceData, params::ParameterData, method_code::String)::Nothing
	original_path = pwd()
	cd(params.inst_path)
	cd("../../../")
	group = inst.group
	if endswith(inst.group, "03M")
		group = replace(inst.group, "03M" => "04M")
	elseif endswith(inst.group, "05M")
		group = replace(inst.group, "05M" => "06M")
	end

	feasible_inst_path = string("../", basename(pwd()), "_f", method_code, "/", group, "/", inst.type, "/", inst.name)
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
end # function instance_data_to_csv_files()


end # module Data
