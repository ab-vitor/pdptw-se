module CSVUtils

using CSV
using DataFrames

export write_csv_with_flock, structToKeyInDict

# Function to apply file locks
function flock(fd::Integer, operation::Integer)
    ccall(:flock, Cint, (Cint, Cint), fd, operation)
end

# Function to get file descriptor
function fd_from_io(io::IO)
    return ccall(:fileno, Cint, (Ptr{Cvoid},), io)
end

# Function to write data to CSV with file locking
function write_csv_with_flock(filename::String, data::DataFrame)
    # Ensure all directories in the path exist
    dir = dirname(filename)
    if !isdir(dir)
        mkpath(dir)
    end

    if !isfile(filename)
        open(filename, "a") do io
            fd = fd_from_io(io)  # Get file descriptor
            flock(fd, 2)  # LOCK_EX (blocking lock)
    
            CSV.write(filename, data, delim = ";")
            
            flock(fd, 8)  # LOCK_UN (unlock)
        end
    else
        open(filename, "a") do io
            fd = fd_from_io(io)  # Get file descriptor
            flock(fd, 2)  # LOCK_EX (blocking lock)
    
            CSV.write(filename, data, append = true, writeheader = false, delim = ";")
    
            flock(fd, 8)  # LOCK_UN (unlock)
        end
    end
end

function parseField(field::Any)::Any
    if typeof(field) == Enum
        return string(field)
    end
    return field
end

function structToKeyInDict(s)
    return Dict(
        field => (typeof(val) <: Enum ? string(val) : val)
        for field in fieldnames(typeof(s))
        for val = (getfield(s, field),)
        if isa(val, Number) || isa(val, Bool) || isa(val, String) || isa(val, Symbol) || typeof(val) <: Enum
    )
end




end # module CSVUtils 