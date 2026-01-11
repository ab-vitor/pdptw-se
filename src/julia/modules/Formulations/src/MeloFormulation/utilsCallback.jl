using Dates

function build_node_labels(
	inst::InstanceData,
	params::ParameterData,
	x_val::JuMP.Containers.SparseAxisArray,
	t_val::JuMP.Containers.DenseAxisArray,
	tstart_val::JuMP.Containers.DenseAxisArray,
	tfinal_val::JuMP.Containers.DenseAxisArray,
	C_val::JuMP.Containers.DenseAxisArray,
)::Vector{String}

	node_labels = Vector{String}(undef, 2 * inst.n + 2)
	for i in inst.V_p_d
		node_labels[i] = "k:"
		for k in inst.K
			found_k = false
			for (j, p) in inst.A
				if p == i
					if x_val[j, i, k] > params.epsilon
						node_labels[i] *= string(" ", k)
						found_k = true
					end
				end
				if found_k
					break
				end
			end
		end
		node_labels[i] *= string("\nt", " = ", round(t_val[i], digits = 2))
		node_labels[i] *= string("\nTW: [", inst.e[i], ", ", inst.l[i], "]\n")
	end

	first_k = inst.K[1]
	node_labels[1] = string("t^", first_k, "_st = ", round(tstart_val[first_k], digits = 2), "\n")
	node_labels[2*inst.n+2] = string(
		# "t^",
		# first_k,
		# "_f = ",
		# round(tfinal_val[first_k], digits = 2),
		" C_",
		first_k,
		" = ",
		round(C_val[first_k], digits = 2),
		"\n",
	)
	for k in inst.K[2:end]
		node_labels[1]          *= string("t^", k, "_st = ", round(tstart_val[k], digits = 2), "\n")
		node_labels[2*inst.n+2] *= string(        # "t^", k, "_f = ", round(tfinal_val[k], digits = 2),
		" C_", k, " = ", round(C_val[first_k], digits = 2), "\n"
)
	end

	return node_labels
end

function get_graph_dot_filename(calls::Int64)::String
	return string("graphdotfiles/graph_", calls%10, ".dot")
end
"""
	save_graph_to_dot(g::DiGraph, filename::String, edge_labels::Matrix{String}, node_labels::Vector{String})

Saves a directed graph `g` to a DOT file using the provided `edge_labels` matrix.
"""
function save_graph_to_dot(g::DiGraph, filename::String, edge_labels::Matrix{String}, node_labels::Vector{String})::Nothing
	n = nv(g)  # Number of vertices

	# Create a DOT graph
	dot_graph = digraph("G")

	# Add nodes
	for v in 1:n
		dot_graph |> node("v$v"; label = string("v", v, "\n", node_labels[v]))
	end

	# Add edges with labels
	for i in 1:n, j in 1:n
		if has_edge(g, i, j) && !isempty(edge_labels[i, j])
			dot_graph |> edge("v$i", "v$j"; label = edge_labels[i, j])
		end
	end


	# Save the graph to a temporary file
	temp_filename = "temp.dot"
	save(dot_graph, temp_filename; format = "dot")

	# Read the saved file and clean it up
	dot_content = read(temp_filename, String)

	# Remove node [label="\N"];
	dot_content = replace(dot_content, r"label=\"\\N\";?" => "shape=box")

	# Remove unwanted attributes like height, lp, and pos
	dot_content = replace(dot_content, r"\b(width|height)=[^,\]]+,?" => "")
	dot_content = replace(dot_content, r"\b(pos|lp)=\"[^\"]*\"\s*,?" => "")

	# # Remove unnecessary commas left after attribute removal
	dot_content = replace(dot_content, r",\s*([\]])" => s"\1")

	# Ensure labels are correctly quoted
	dot_content = replace(dot_content, r"label=([^\"][^{}\s\];]*)" => s"label=\"\1\"")

	# Remove unnecessary line breaks after "["
	dot_content = replace(dot_content, r"\[\s*\n\s*" => "[")

	dot_content = string(now(), "\n", dot_content)

	# Write the cleaned content to the final DOT file
	write(filename, dot_content)
	# println("Graph saved as $filename (cleaned)")

	rm(temp_filename, force = true)
	# println("Temporary file $temp_filename deleted.")
	return nothing
end