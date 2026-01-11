module LNS

using Printf

using Data
using Parameters
using Multistart
using Solutions
using Formulations
using Gurobi
using JuMP
using Random
using Enumerations
using DataFrames
using CSVUtils
using Dates
using Statistics
using Plots

include("lmns/lmns_files.jl")

function lmns(env::Union{Gurobi.Env, Nothing}, inst::InstanceData, params::ParameterData)::Solution
	stopParams = load_stop_params(params)
	shawParams = load_shaw_params(params)
	reqrParams = load_reqr_params(params)
	dgdParams = load_dgd_params(inst, params)
	acParams = load_ac_params(params)
	allParams = AllParams(params, stopParams, shawParams, reqrParams, dgdParams, acParams)

	isMainMethod = params.methodType == "heur" && params.methodCode == "lmns"
	if isMainMethod
		println("\n[$(Dates.Time(Dates.now()))] Print configuration")
		printConfiguration(inst, allParams)
	end

	extld = ExternalLMNSDataConstructor(
		mipModel = createMeloMIPModel(env, inst, allParams.general),
		env = env,
	)
	
	runLMNS!(inst, extld, allParams)

	if isMainMethod
		println("\n[$(Dates.Time(Dates.now()))] Post running LMNS")
		postRunningLMNS!(inst, extld, allParams)
	end
	return extld.bestSol
end # function lmns()

end # module LNS
