"""
	function update_machines_indexes(sol::Solution)::Nothing

	Updates the machine indexes in the solution `sol` to ensure that each vehicle's
	machine index corresponds to its position in the machine travels list. This is
	done by iterating through each machine's travels and updating the `mach_index`
	attribute of the corresponding vehicle stops.
"""
function update_machines_indexes(sol::Solution)::Nothing
	for h in eachindex(sol.machines)
		for i in eachindex(sol.machines[h])[1:end]
			mach_trv = sol.machines[h][i]
			sol.vehicles[mach_trv.vehicle][mach_trv.vehicle_index].mach_index = i
		end
	end
	return nothing
end # function update_machines_indexes

"""
	function deactivate_machine_travels(
		k::Int64,
		sol::Solution,
		p_pos::Int64,
	)::Nothing

	Deactivates all machine travels in the solution `sol` for vehicle `k` that have
	a vehicle index greater than or equal to `p_pos`. This is done by setting the
	`active` attribute of the relevant machine travels to `false`.
"""
function deactivate_machine_travels(k::Int64, sol::Solution, p_pos::Int64)::Nothing
	for h in eachindex(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if sol.machines[h][i].vehicle == k && sol.machines[h][i].vehicle_index >= p_pos
				sol.machines[h][i].active = false
			end
		end
	end
	return nothing
end # function deactivate_machine_travels()

"""
	flat_machine_travels_chronollogically(
		possible_machine_travels::Vector{Vector{PossibleMachineTravel}},
	)::Vector{PossibleMachineTravel}

	Flattens a vector of vectors of `PossibleMachineTravel` objects into a single
	vector and sorts them in chronological order based on their start times.
"""
function flat_machine_travels_chronollogically(
	possible_machine_travels::Vector{Vector{PossibleMachineTravel}},
)::Vector{PossibleMachineTravel}
	machine_travels = collect(Iterators.flatten(possible_machine_travels))
	sort!(machine_travels, by = i -> (i.st))

	return machine_travels
end # function flat_machine_travels_chronollogically()

"""
	function remove_deactivated_travels(sol::Solution)::Nothing

	Removes all deactivated machine travels from the solution `sol`. A machine travel is considered
	deactivated if its `active` attribute is set to `false`. The function iterates through each
	machine's travels and removes any deactivated ones.
"""
function remove_deactivated_travels(sol::Solution)::Nothing
	for h in eachindex(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if !sol.machines[h][i].active
				splice!(sol.machines[h], i)
			end
		end
	end
	return nothing
end # function remove_deactivated_travels()