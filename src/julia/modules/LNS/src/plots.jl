function plotHistoryImprv(plotPath::String, extld::ExternalLMNSData)::Nothing
	hist = extld.stats.historyBestCosts
	x = []
	y = []
	for i in 1:length(hist)-1
		push!(x, hist[i][2])
		push!(y, hist[i][1])
		if hist[i][2] != hist[i+1][2] - 1
			push!(x, hist[i+1][2] - 1)
			push!(y, hist[i][1])
		end
	end
	push!(x, hist[end][2])
	push!(y, hist[end][1])
	push!(x, extld.totalNumIterations)
	push!(y, hist[end][1])

	p = Plots.plot(
		x, y, xlabel = "Iteration", ylabel = "Solution value",
		lw = 2, xticks = :auto, legend = false,
	)
	savefig(p, plotPath)
	return nothing
end