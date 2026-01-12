module Solutions

using Data
using Parameters
using JuMP
using Dates

export VehicleStop, MachineTravel, StatsSolution, Solution

export LPSolution

export saveSolutionToFile, saveSolutionTimeline,
	print_timeline_solution, validate_solution


include("solutionDataStructures.jl")
include("LP_solution_data_structures.jl")
include("printDetailed.jl")
include("validate_solution.jl")
include("statistics.jl")
include("convertSol.jl")
include("writeSol.jl")


end # module
