function getInitialSolution(env::Union{Gurobi.Env, Nothing}, inst::InstanceData, params::ParameterData)
	sol = Multistart.multistartlp(env, inst, params)
	return sol
end # function getInitialSolution()