using Random

function chooseCandidate(candList::Vector{InsertionData}, params::ParameterData)
	if length(candList) == 0
		return InsertionData(false, Inf64, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	end
	cMin = Inf64
	cMax = 0
	for c in candList
		cMin = min(cMin, c.cost)
		cMax = max(cMax, c.cost)
	end
	maxCostAllowed = cMin + params.alpha * (cMax - cMin)
	rcl = InsertionData[]
	for c in candList
		if c.cost <= maxCostAllowed
			push!(rcl, c)
		end
	end

	k = length(rcl)
	idxCand = (abs(rand(params.rng, Int64)) % k) + 1
	chosen = rcl[idxCand]
	return chosen
end
