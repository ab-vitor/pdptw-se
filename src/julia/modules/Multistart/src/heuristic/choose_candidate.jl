"""
	function choose_candidate(cand_list::Vector{InsertionData}, params::ParameterData) -> InsertionData
	
	Selects a candidate from the provided list `cand_list` using a semi-greedy approach
	based on the parameters specified in `params`. The function constructs a restricted
	candidate list (RCL) containing candidates whose costs are within a certain threshold
	of the minimum cost candidate. A candidate is then randomly selected from the RCL.
"""
function choose_candidate(cand_list::Vector{InsertionData}, params::ParameterData)
	if length(cand_list) == 0
		return InsertionData(false, Inf64, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	end
	c_min = Inf64
	c_max = 0
	for c in cand_list
		c_min = min(c_min, c.cost)
		c_max = max(c_max, c.cost)
	end
	max_cost_allowed = c_min + params.alpha * (c_max - c_min)
	rcl = InsertionData[]
	for c in cand_list
		if c.cost <= max_cost_allowed
			push!(rcl, c)
		end
	end

	k = length(rcl)
	idx_cand = (abs(rand(params.rng, Int64)) % k) + 1
	chosen = rcl[idx_cand]
	return chosen
end
