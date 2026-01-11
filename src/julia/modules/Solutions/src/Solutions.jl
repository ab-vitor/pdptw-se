module Solutions

using Data
using Parameters
using JuMP
using Dates

export VehicleStop, MachineTravel, StatsSolution, Solution

export MIPVarsSolution, MIPStats, MIPSolution, LPSolution

export createSolutionMelo, saveSolutionToFile, saveSolutionTimeline,
	printDetailMeloFormulationSolution, validateSolution


include("solutionDataStructures.jl")
include("MIPSolutionDataStructures.jl")
include("printDetailed.jl")
include("validateSolution.jl")
include("statistics.jl")
include("convertSol.jl")
include("writeSol.jl")


end # module
