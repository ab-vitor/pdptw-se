push!(LOAD_PATH, "modules/")

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
Data.compare_orig_instance_with_modified(inst1, inst2)
