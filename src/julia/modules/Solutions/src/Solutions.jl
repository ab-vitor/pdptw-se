module Solutions

using Data
using Parameters
using JuMP
using Dates

export VehicleStop, MachineTravel, SolutionStats, Solution

export LPSolution

export save_summarized_solution, save_solution_timeline,
	print_timeline_solution, validate_solution


include("solution_data_structures.jl")
include("LP_solution_data_structures.jl")
include("print_timeline_solution.jl")
include("validate_solution.jl")
include("statistics.jl")
include("convert_solution.jl")
include("save_solution.jl")


end # module
