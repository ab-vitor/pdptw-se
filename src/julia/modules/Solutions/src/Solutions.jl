module Solutions

using Data
using Parameters
using JuMP
using Dates

export VehicleStop, MachineTravel, StatsSolution, Solution

export LPSolution

export createSolutionMelo, saveSolutionToFile, saveSolutionTimeline,
	printDetailMeloFormulationSolution, validate_solution


include("solutionDataStructures.jl")
include("LPSolutionDataStructures.jl")
include("printDetailed.jl")
include("validate_solution.jl")
include("statistics.jl")
include("convertSol.jl")
include("writeSol.jl")


end # module
