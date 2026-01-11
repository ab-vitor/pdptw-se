module ProcUsage

# Constants for the `who` argument
const RUSAGE_SELF    = 0
const RUSAGE_CHILDREN = -1
const RUSAGE_THREAD  = Sys.islinux() ? 1 : 0  # RUSAGE_THREAD is Linux-specific

export cpu_times

# Julia representation of C structs
struct TimeVal
    tv_sec::UInt64    # seconds (usually Int64)
    tv_usec::UInt64     # microseconds
end

struct RUsage
    ru_utime::TimeVal  # user CPU time used
    ru_stime::TimeVal  # system CPU time used
    # we ignore other fields
    _pad::NTuple{14, Clong}  # pad to match sizeof(struct rusage)
end

"""
    cpu_times(; who::Integer=RUSAGE_SELF)

Return a tuple `(user, system)` giving the CPU time spent in user and system mode
for the current process or thread.  Times are returned as `Float64` seconds.

`who` may be `RUSAGE_SELF`, `RUSAGE_CHILDREN` or `RUSAGE_THREAD` (on Linux).
"""
function cpu_times(; who::Integer=RUSAGE_SELF)
    usage = Ref{RUsage}()
    ret = ccall(:getrusage, Cint, (Cint, Ref{RUsage}), who, usage)
    if ret != 0
        throw(ErrorException("getrusage failed"))
    end
    u = usage[].ru_utime
    s = usage[].ru_stime
    user  = Float64(u.tv_sec) + Float64(u.tv_usec) / 1_000_000.0
    system = Float64(s.tv_sec) + Float64(s.tv_usec) / 1_000_000.0
    return user, system
end

end # module
