function is_arc_infeasible_priority(i::Int, j::Int, inst::InstanceData)
	is_depot_begin_to_delivery = (i == inst.depot_begin && inst.first_delivery <= j <= inst.last_delivery)
	if is_depot_begin_to_delivery
		inst.ppd.arc_removals += 1
		inst.ppd.arc_removals_is_depot_begin_to_delivery += 1
		return true
	end

	is_delivery_to_pickup = i == j + inst.n
	if is_delivery_to_pickup
		inst.ppd.arc_removals += 1
		inst.ppd.arc_removals_is_delivery_to_pickup += 1
		return true
	end

	is_dest_depot_begin = j == inst.depot_begin
	if is_dest_depot_begin
		inst.ppd.arc_removals += 1
		inst.ppd.arc_removals_is_dest_depot_begin += 1
		return true
	end

	is_orig_depot_end = i == inst.depot_end
	if is_orig_depot_end
		inst.ppd.arc_removals += 1
		inst.ppd.arc_removals_is_orig_depot_end += 1
		return true
	end

	return false
end

function is_arc_infeasible_pairing(i::Int, j::Int, inst::InstanceData)
	is_pickup_to_depot_end = (inst.first_pickup <= i <= inst.last_pickup && j == inst.depot_end)
	if is_pickup_to_depot_end
		inst.ppd.arc_removals += 1
		inst.ppd.arc_removals_is_pickup_to_depot_end += 1
		return true
	end
	return false
end

function is_arc_infeasible_vehicle_capacity(i::Int, j::Int, inst::InstanceData)
	is_capacity_violated = abs(inst.q[i]) + abs(inst.q[j]) > inst.max_Q
	if is_capacity_violated
		inst.ppd.arc_removals += 1
		inst.ppd.arc_removals_is_capacity_violated += 1
		return true
	end
	return false
end


function is_arc_infeasible_time_windows(i::Int, j::Int, inst::InstanceData)
    is_time_window_limited = (i in inst.V_p_d &&
                             j in inst.V_p_d &&
                             inst.eprime[i] + inst.s[i] + inst.dmin_vehicle[i, j] > inst.lprime[j])
    if is_time_window_limited
        inst.ppd.arc_removals += 1
        inst.ppd.arc_removals_is_time_window_limited += 1
        return true
    end
    return false
end

function is_arc_infeasible_time_windows_and_pairing_of_requests(i1::Int, i2::Int, inst::InstanceData)
    if i1 == inst.depot_begin || i2 == inst.depot_end
        return false
    end

    if (i1 in inst.V_p) && (i2 in inst.V_d)
        i = i1
        j = i2 - inst.n
        if i != j && is_min_t_arrival_infeasible([j, i, j + inst.n, i + inst.n], inst)
            inst.ppd.arc_removals += 1
            inst.ppd.arc_removals_is_time_window_pairing_limited += 1
            return true
        end
    end

    if (i1 in inst.V_d) && (i2 in inst.V_p)
        i = i1 - inst.n
        j = i2
        if i != j && is_min_t_arrival_infeasible([i, i + inst.n, j, j + inst.n], inst)
            inst.ppd.arc_removals += 1
            inst.ppd.arc_removals_is_time_window_pairing_limited += 1
            return true
        end
    end

    if (i1 in inst.V_p) && (i2 in inst.V_p)
        i = i1
        j = i2
        if i != j &&
           is_min_t_arrival_infeasible([i, j, i + inst.n, j + inst.n], inst) &&
           is_min_t_arrival_infeasible([i, j, j + inst.n, i + inst.n], inst)
            inst.ppd.arc_removals += 1
            inst.ppd.arc_removals_is_time_window_pairing_limited += 1
            return true
        end
    end

    if (i1 in inst.V_d) && (i2 in inst.V_d)
        i = i1 - inst.n
        j = i2 - inst.n
        if i != j &&
           is_min_t_arrival_infeasible([i, j, i + inst.n, j + inst.n], inst) &&
           is_min_t_arrival_infeasible([j, i, i + inst.n, j + inst.n], inst)
            inst.ppd.arc_removals += 1
            inst.ppd.arc_removals_is_time_window_pairing_limited += 1
            return true
        end
    end

    return false
end

function is_arc_infeasible_indirect_service(i::Int, j::Int, inst::InstanceData)
    is_indirect_request_service_impossible = false
    if (i in inst.V_p) && (j in inst.V_p_d) && (j != inst.n + i)
        if is_min_t_arrival_infeasible([i, j, i + inst.n], inst)
            is_indirect_request_service_impossible = true
        end
    end

    if is_indirect_request_service_impossible
        inst.ppd.arc_removals += 1
        inst.ppd.arc_removals_is_indirect_request_service_impossible += 1
        return true
    end

    return false
end

function is_arc_infeasible(i::Int, j::Int, inst::InstanceData)
    is_loop = i == j
    if is_loop
        inst.ppd.arc_removals += 1
        inst.ppd.arc_removals_is_loop += 1
        return true
    end

    if is_arc_infeasible_priority(i, j, inst)
        return true
    end

    if is_arc_infeasible_pairing(i, j, inst)
        return true
    end

    if is_arc_infeasible_vehicle_capacity(i, j, inst)
        return true
    end

    if is_arc_infeasible_time_windows(i, j, inst)
        return true
    end

    if is_arc_infeasible_time_windows_and_pairing_of_requests(i, j, inst)
        return true
    end

    if is_arc_infeasible_indirect_service(i, j, inst)
        return true
    end

    return false
end

function is_precede_possible(i::Int, j::Int, iprime::Int, jprime::Int, h::Int, inst::InstanceData)::Bool
    if (i == iprime) && (j == jprime)
        inst.ppd.infeas_gamma_vars_is_iprime_jprime_eq_i_j += 1
        return false
    end
    min_arrival_at_i_station = inst.eprime[i] + inst.s[i] + inst.d_bar_min[i, h]
    min_machine_arrival_at_iprime_station = min_arrival_at_i_station +
        inst.O[(inst.f[i][h], inst.f[j][h], h)] +
        inst.O[(inst.f[j][h], inst.f[iprime][h], h)]
    max_departure_from_iprime_station = inst.lprime[jprime] -
        inst.d_bar_min[jprime, h] -
        inst.O[(inst.f[iprime][h], inst.f[jprime][h], h)]
    if min_machine_arrival_at_iprime_station > max_departure_from_iprime_station
        inst.ppd.infeas_gamma_vars_is_next_mtrv_unreachable += 1
        return false
    end
    return true
end

function build_eprime_lprime!(inst::InstanceData)
    inst.eprime = copy(inst.e)
    inst.lprime = copy(inst.l)

    for i in inst.V_p
        inst.lprime[i + inst.n] = min(
            inst.l[i + inst.n],
            inst.l[inst.depot_end] - inst.dmin_vehicle[i + inst.n, inst.depot_end] - inst.s[i + inst.n]
        )
        inst.lprime[i] = min(
            inst.l[i],
            inst.l[i + inst.n] - inst.dmin_vehicle[i, i + inst.n] - inst.s[i]
        )
        inst.eprime[i] = max(
            inst.e[i],
            inst.e[inst.depot_begin] + inst.dmin_vehicle[inst.depot_begin, i]
        )
        inst.eprime[i + inst.n] = max(
            inst.e[i + inst.n],
            inst.e[i] + inst.s[i] + inst.dmin_vehicle[i, i + inst.n]
        )
    end
    return nothing
end

function preprocess_H_e!(inst::InstanceData)
    for (i, j) in inst.A_m
        feasible_machines = Int[]
        for h in inst.H_e[i][j]
            if inst.eprime[i] + inst.s[i] + inst.d_bar_min[i, h] <=
               inst.lprime[j] - inst.d_bar_min[j, h] - inst.O[(inst.f[i][h], inst.f[j][h], h)]
                push!(feasible_machines, h)
            else
                inst.ppd.machine_removal_for_an_arc += 1
            end
        end
        if isempty(feasible_machines)
            error("No feasible machines for arc ($i, $j)")
        end
        inst.H_e[i][j] = feasible_machines
    end
    return nothing
end