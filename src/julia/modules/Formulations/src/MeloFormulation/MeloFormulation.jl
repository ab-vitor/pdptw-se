using Graphs, Plots
import MathOptInterface as MOI

include("MeloFormulationStructures.jl")
include("DebugMeloMIPModel.jl")
include("VariablesMeloMIPModel.jl")
include("ConstraintsMeloMIPModel.jl")
include("ObjectiveFunctionMeloMIPModel.jl")
include("WarmStartMeloMIPModel.jl")
include("CreateMeloMIPModel.jl")
include("utilsCallback.jl")
include("UserCallbacks.jl")
include("MeloLPScheduleModel.jl")
include("csvresults.jl")


function meloFormulation(env::Union{Gurobi.Env, Nothing}, inst::InstanceData, params::ParameterData)::Union{Nothing, Solution}
	println("\n[$(Dates.Time(Dates.now()))] Running Formulations.meloFormulation")

	mipModel = createMeloMIPModel(env, inst, params)

	### Write model in a file
	# write_to_file(model,"modelo.lp")
	# println("Model file created")

	### Warm-start
	if params.warmStart
		meloWarmStartGreedyHeuristic(env, inst, params, mipModel)
	end

	# set_attribute(mipModel.model, "PreSolve", 0)
	# undo = relax_integrality(mipModel.model)
	# println("Number of integer constraints (relax): ", num_constraints(mipModel.model, VariableRef, MOI.Integer))
	# undo()
	# println("Number of integer constraints (normal): ", num_constraints(mipModel.model, VariableRef, MOI.Integer))


	if params.typeUserCut >= 1
		calls = -1
		cbclosure = CallbackClosure(inst, params, mipModel, calls)
		user_cut_function = get_user_cut_function(cbclosure)
		set_attribute(mipModel.model, MOI.UserCutCallback(), user_cut_function)
	end

	t1 = time_ns()
	println("starting")
	optimize!(mipModel.model)
	println("final")
	t2 = time_ns()
	elapsedtime = (t2 - t1) / 1.0e9

	status = termination_status(mipModel.model)

	opt = 0
	tle = 0
	if status == OPTIMAL
		println("Solution is optimal")
		opt = 1
	elseif status == TIME_LIMIT && has_values(mipModel.model)
		tle = 1
		println("Solution is suboptimal due to a time limit, but a primal solution is available")
	else
		tle = 1
		println("The model was not solved correctly. Status: ", status)
		println("[$(Dates.Time(Dates.now()))] Writing results to CSV file: ", params.csvfilename)
		csvrow = csvresults(inst, params)
		CSVUtils.write_csv_with_flock(params.csvfilename, csvrow)

		return nothing
	end
	println("  objective value = ", objective_value(mipModel.model))

	println(status)
	objValue = sum(value.(mipModel.C))
	bestbound = objective_bound(mipModel.model)
	numnodes = node_count(mipModel.model)
	time = solve_time(mipModel.model)
	gap = 100 * (objValue - bestbound) / objValue

	x = value.(mipModel.x)
	z = value.(mipModel.z)
	t = value.(mipModel.t)
	tstart = value.(mipModel.tstart)
	tfinal = value.(mipModel.tfinal)
	C = value.(mipModel.C)
	phi = value.(mipModel.phi)
	gamma = value.(mipModel.gamma)
	alpha = value.(mipModel.alpha)
	# detailed_analysis(inst, params, x, z, t, tstart, tfinal, C, phi, gamma, alpha)

	mipVarsSol = MIPVarsSolution(x, z, t, tstart, tfinal, C, phi, gamma, alpha)
	mipStats = MIPStats(status, opt, tle, objValue, bestbound, numnodes, time, gap)
	mipSol = Solutions.MIPSolution(mipVarsSol, mipStats)

	sol = Solutions.createSolutionMelo(inst, mipSol, params)

	println("\n[$(Dates.Time(Dates.now()))] Writing results to CSV file: ", params.csvfilename)
	csvrow = csvresults(sol, mipSol, inst, params)
	CSVUtils.write_csv_with_flock(params.csvfilename, csvrow)
	saveSolutionToFile(sol, inst, params)
	saveSolutionTimeline(sol, inst, params)

	return sol

end # function meloFormulation()