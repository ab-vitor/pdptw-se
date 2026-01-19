push!(LOAD_PATH, "modules/")
# push!(DEPOT_PATH, JULIA_DEPOT_PATH)
using Pkg
#Pkg.activate(".")
# Pkg.instantiate()
# Pkg.build()

import Data
using Parameters

oldstd = stdout
redirect_stdout(devnull)
# Read the parameters from command line
params = ParameterData()

# Read instance data
inst1 = Data.read_data(params, ARGS[1])
inst2 = Data.read_data(params, ARGS[2])

redirect_stdout(oldstd)
Data.is_tw_cap_changed(inst1, inst2)
