# Euclidean distance with elevation factor
function euclidean_dist(p1::Point, p2::Point, elev::Int)
    d = sqrt((p1.x - p2.x)^2 + (p1.y - p2.y)^2 + elev * (p1.z - p2.z)^2)
    return round(d, digits=2)
end

# Check if minimum arrival time is infeasible for any k
function is_min_t_arrival_infeasible(nodes::Vector{Int}, inst::InstanceData)
    for k in inst.K
        t = inst.eprime[nodes[1]]
        for idx in 2:length(nodes)
            prev = nodes[idx - 1]
            curr = nodes[idx]
            t = max(inst.eprime[curr], t + inst.s[prev] + inst.d[prev, curr, k])
        end
        if t <= inst.lprime[nodes[end]]
            return false
        end
    end
    return true
end

# Check if minimum arrival time is infeasible for a specific k
function is_min_t_arrival_infeasible_k(nodes::Vector{Int}, inst::InstanceData, k::Int)
    t = inst.eprime[nodes[1]]
    for idx in 2:length(nodes)
        prev = nodes[idx - 1]
        curr = nodes[idx]
        t = max(inst.eprime[curr], t + inst.s[prev] + inst.d[prev, curr, k])
    end
    if t <= inst.lprime[nodes[end]]
        return false
    end
    return true
end

# Check if path is valid using in_A
function valid_path(nodes::Vector{Int}, inst::InstanceData, w::Int)
    for idx in 1:w
        if !inst.in_A[(nodes[idx], nodes[idx + 1])]
            return false
        end
    end
    return true
end

# Check if path is valid using in_A_m
function valid_path_m(nodes::Vector{Int}, inst::InstanceData, w::Int)
    for idx in 1:w
        if !inst.in_A_m[(nodes[idx], nodes[idx + 1])]
            return false
        end
    end
    return true
end