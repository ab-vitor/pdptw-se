function createMeloMIPModel(env::Union{Gurobi.Env, Nothing}, inst::InstanceData, params::ParameterData)::Union{MIPModel, Nothing}
	println("\n[$(Dates.Time(Dates.now()))] Creating Melo MIP model...")
	if params.solver == "Gurobi"
		model = Model(() -> Gurobi.Optimizer(env))

		if params.outputFlagGrbMIP == 0
			set_silent(model)
		end
		set_attribute(model, "OutputFlag", params.outputFlagGrbMIP)

		max_num_threads = length(Sys.cpu_info())
		num_threads = max_num_threads
		if params.threads > 0 && params.threads <= max_num_threads
			num_threads = params.threads
		end
		set_attribute(model, "Threads", num_threads)

		set_attribute(model, "Seed", params.seed)

		set_attribute(model, "TimeLimit", params.mipmaxtime)
		dir = dirname(params.grbFilename)
		if !isdir(dir)
			mkpath(dir)
		end
		set_attribute(model, "LogFile", params.grbFilename)
		set_attribute(model, "Presolve", params.mipPresolve)
		set_attribute(model, "Cuts", params.gurobiCuts)
		if params.maxnodes >= 0
			set_attribute(model, "NodeLimit", params.maxnodes)
		end
	else
		println("No solver selected")
		return nothing
	end

	### Defining variables ###

	# Routing variables
	x, z = meloRoutingVariables(inst, model)

	# Scheduling variables
	t, tstart, tfinal, C, phi, gamma, alpha = meloSchedulingVariables(inst, model)

	### Routing Constraints ###
	println("\n[$(Dates.Time(Dates.now()))] Adding routing constraints")
	meloRoutingConstraints(inst, params, model, x, z)

	### Scheduling constraints ###
	println("[$(Dates.Time(Dates.now()))] Adding scheduling constraints")
	meloSchedulingConstraints(inst, model, x, t, tstart, tfinal, C, phi, gamma, alpha)

	### Objective function ###
	println("[$(Dates.Time(Dates.now()))] Adding objective function")
	meloObjectiveFunction(model, C)

	return MIPModel(model, x, z, t, tstart, tfinal, C, phi, gamma, alpha)
end # function createMeloMIPModel()