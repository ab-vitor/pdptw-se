from typing import List, Optional
from modules.data import InstanceData
from modules.parameters import ParameterData
from hexaly.optimizer import HxModel, HxExpression
from .entities_barlogon_hexaly_formulation import (
    BarlogonHxRoutingVars,
    BarlogonHxSchedulingVars,
)


def link_trajectories_to_routes(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarlogonHxRoutingVars,
) -> None:
    routes_array: HxExpression = rtvars.routes_array

    trajectories: List[HxExpression] = rtvars.trajectories
    origins_A_m: HxExpression = rtvars.origins_A_m
    destinies_A_m: HxExpression = rtvars.destinies_A_m

    offset: int = 1

    for h in inst.H:
        trajectory = trajectories[h]
        c = model.count(trajectory)

        def link_trajectory_route_function(i: HxExpression) -> HxExpression:
            orig = model.at(origins_A_m, trajectory[i])
            dest = model.at(destinies_A_m, trajectory[i])
            orig_offset = orig - offset
            dest_offset = dest - offset
            nb_not_found = -1

            # Case 1: arc from depot_begin
            is_arc_from_depot_begin = orig == inst.depot_begin
            route_dest_offset_index = model.find(routes_array, dest_offset)
            dest_offset_index = model.iif(
                route_dest_offset_index != nb_not_found,
                model.index(
                    model.at(routes_array, route_dest_offset_index), dest_offset
                ),
                nb_not_found,
            )

            # Case 2: arc to depot_end
            is_arc_to_depot_end = dest == inst.depot_end
            route_orig_offset_index = model.find(routes_array, orig_offset)
            orig_offset_index = model.iif(
                route_orig_offset_index != nb_not_found,
                model.index(
                    model.at(routes_array, route_orig_offset_index), orig_offset
                ),
                nb_not_found,
            )
            last_index_route_orig_offset = model.iif(
                route_orig_offset_index != nb_not_found,
                model.count(model.at(routes_array, route_orig_offset_index)) - 1,
                nb_not_found,
            )

            # Case 3: intermediate link
            # expressions already defined

            return model.iif(
                is_arc_from_depot_begin,
                dest_offset_index == 0,
                model.iif(
                    is_arc_to_depot_end,
                    model.and_(
                        route_orig_offset_index >= 0,
                        orig_offset_index == last_index_route_orig_offset,
                    ),
                    model.and_(
                        route_orig_offset_index == route_dest_offset_index,
                        orig_offset_index + 1 == dest_offset_index,
                    ),
                ),
            )

        link_trajectory_route_lambda = model.lambda_function(
            link_trajectory_route_function
        )
        model.constraint(model.and_(model.range(0, c), link_trajectory_route_lambda))

    return None


def link_routes_to_trajectories(
    inst: InstanceData, model: HxModel, rtvars: BarlogonHxRoutingVars
) -> None:

    routes: List[HxExpression] = rtvars.routes

    trajectories_array: HxExpression = rtvars.trajectories_array
    idx_A_m: HxExpression = rtvars.idx_A_m
    diff_region: HxExpression = rtvars.diff_region

    offset: int = 1

    for k in inst.K:
        route = routes[k]
        c = model.count(route)

        def link_route_trajectory_function(i: HxExpression) -> HxExpression:
            is_first = model.eq(i, 0)
            is_last = model.eq(i, c - 1)
            nb_not_found = -1

            u = model.iif(
                is_first,
                inst.depot_begin,
                route[i - 1] + offset,
            )
            v = route[i] + offset

            last_v = inst.depot_end

            arc_exists = model.at(diff_region, u, v)
            arc_idx = model.at(idx_A_m, u, v)
            arc_found = model.find(trajectories_array, arc_idx) != nb_not_found

            last_arc_exists = model.at(diff_region, v, last_v)
            last_arc_idx = model.at(idx_A_m, v, last_v)
            last_arc_found = (
                model.find(trajectories_array, last_arc_idx) != nb_not_found
            )

            return model.iif(
                is_last,
                model.and_(
                    model.iif(arc_exists, arc_found, True),
                    model.iif(last_arc_exists, last_arc_found, True),
                ),
                model.iif(arc_exists, arc_found, True),
            )

        link_route_trajectory_lambda = model.lambda_function(
            link_route_trajectory_function
        )
        link_route_trajectory = model.and_(
            model.range(0, c), link_route_trajectory_lambda
        )
        model.constraint(link_route_trajectory)


def barlogon_hexaly_routing_constraints(
    inst: InstanceData,
    params: ParameterData,
    model: HxModel,
    rtvars: BarlogonHxRoutingVars,
) -> None:
    """
    Routing constraints for both vehicles and machines
    """
    routes: List[HxExpression] = rtvars.routes
    routes_array: HxExpression = rtvars.routes_array
    trajectories: List[HxExpression] = rtvars.trajectories
    demands: HxExpression = rtvars.demands
    routes_loads: List[Optional[HxExpression]] = rtvars.routes_loads

    offset: int = 1

    # All customers must be visited by exactly one vehicle
    model.constraint(model.partition(routes))

    # Pickups and deliveries
    for i in inst.V_p:
        p: int = i - offset
        d: int = p + inst.n
        pick_up_list_index = model.find(routes_array, p)
        delivery_list_index = model.find(routes_array, d)
        model.constraint(pick_up_list_index == delivery_list_index)

        pick_up_list = model.at(routes_array, pick_up_list_index)
        delivery_list = model.at(routes_array, delivery_list_index)
        model.constraint(model.index(pick_up_list, p) < model.index(delivery_list, d))

    # Capacity constraint
    for k in inst.K:
        route = routes[k]
        c = model.count(route)

        demand_lambda = model.lambda_function(
            lambda i, prev: prev + demands[route[i] + offset]
        )
        routes_loads[k] = model.array(model.range(0, c), demand_lambda, 0)

        load_lambda = model.lambda_function(lambda i: routes_loads[k][i] <= inst.Q[k])
        model.constraint(model.and_(model.range(0, c), load_lambda))

    # At most one machine-arc visited by one machine
    model.constraint(model.disjoint(trajectories))

    # Link each trajectory to a valid position in the routes
    link_trajectories_to_routes(inst, model, rtvars)
    link_routes_to_trajectories(inst, model, rtvars)

    return None


def constraints_machine_travels_start_times(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarlogonHxRoutingVars,
    schvars: BarlogonHxSchedulingVars,
) -> None:
    trajectories: List[HxExpression] = rtvars.trajectories

    waiting_time_array: HxExpression = schvars.waiting_times_array
    machine_travels_start_times: List[Optional[HxExpression]] = (
        schvars.machine_travels_start_times
    )

    # Routing data transformed into hexaly array
    origins_A_m: HxExpression = rtvars.origins_A_m
    destinies_A_m: HxExpression = rtvars.destinies_A_m

    # Scheduling data transformed into hexaly array
    O_matrix: HxExpression = schvars.O_matrix
    f_matrix: HxExpression = schvars.f_matrix

    for h in inst.H:
        trajectory: HxExpression = trajectories[h]
        c: HxExpression = model.count(trajectory)

        def machine_travels_start_times_function(
            i: HxExpression, prev_value: HxExpression
        ) -> HxExpression:

            is_first: HxExpression = model.eq(i, 0)
            last_i: HxExpression = model.sub(i, 1)

            prev_orig: HxExpression = model.at(origins_A_m, trajectory[last_i])
            prev_dest: HxExpression = model.at(destinies_A_m, trajectory[last_i])

            orig: HxExpression = model.at(origins_A_m, trajectory[i])

            prev_station_orig = model.iif(
                is_first,
                inst.initial_station,
                model.at(f_matrix, prev_orig, h),
            )
            prev_station_dest = model.iif(
                is_first,
                inst.initial_station,
                model.at(f_matrix, prev_dest, h),
            )
            station_orig = model.at(f_matrix, orig, h)

            machine_travel_start_time = model.sum(
                prev_value,
                model.at(
                    O_matrix,
                    prev_station_orig,
                    prev_station_dest,
                    h,
                ),
                model.at(
                    O_matrix,
                    prev_station_dest,
                    station_orig,
                    h,
                ),
                model.at(waiting_time_array, trajectory[i]),
            )
            return machine_travel_start_time

        machine_travels_start_times_lambda: HxExpression = model.lambda_function(
            lambda i, prev: machine_travels_start_times_function(i, prev)
        )
        machine_travels_start_times[h] = model.array(
            model.range(0, c), machine_travels_start_times_lambda, 0
        )


def constraints_services_start_times(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarlogonHxRoutingVars,
    schvars: BarlogonHxSchedulingVars,
) -> None:

    routes: HxExpression = rtvars.routes
    trajectories_array: HxExpression = rtvars.trajectories_array

    tstart_array: List[HxExpression] = schvars.tstart_array
    machine_travels_start_times: List[HxExpression] = (
        schvars.machine_travels_start_times
    )
    machine_travels_start_times_array: HxExpression = model.array(
        machine_travels_start_times
    )
    services_start_times: List[Optional[HxExpression]] = schvars.services_start_times

    # Routing data transformed into hexaly array
    idx_A_m: HxExpression = rtvars.idx_A_m

    # Scheduling data transformed into hexaly array
    d_bar_matrix: HxExpression = schvars.d_bar_matrix
    O_matrix: HxExpression = schvars.O_matrix
    f_matrix: HxExpression = schvars.f_matrix
    service_time: HxExpression = schvars.service_time
    earliest: HxExpression = schvars.earliest
    latest: HxExpression = schvars.latest
    d_matrix: HxExpression = schvars.d_matrix

    offset: int = 1

    for k in inst.K:
        route: HxExpression = routes[k]
        c: HxExpression = model.count(route)

        def services_start_times_function(
            i: HxExpression, prev_value: HxExpression
        ) -> HxExpression:
            is_first: HxExpression = model.eq(i, 0)
            last_i: HxExpression = model.sub(i, 1)
            nb_not_found: int = -1

            curr: HxExpression = route[i]
            prev: HxExpression = route[last_i]
            curr_offset: HxExpression = model.sum(curr, offset)
            prev_offset: HxExpression = model.sum(prev, offset)

            time_window_earliest_time: HxExpression = model.at(earliest, curr_offset)

            arc_orig: HxExpression = model.iif(is_first, inst.depot_begin, prev_offset)
            arc_dest: HxExpression = curr_offset
            index_A_m: HxExpression = model.at(idx_A_m, arc_orig, arc_dest)

            h: HxExpression = model.iif(
                model.neq(index_A_m, nb_not_found),
                model.find(trajectories_array, index_A_m),
                nb_not_found,
            )

            index_arc_in_h: HxExpression = model.iif(
                model.neq(h, nb_not_found),
                model.index(
                    model.at(trajectories_array, h),
                    index_A_m,
                ),
                nb_not_found,
            )

            machine_travel_potential_start_time: HxExpression = model.iif(
                model.neq(index_arc_in_h, nb_not_found),
                model.at(machine_travels_start_times_array, h, index_arc_in_h),
                0,
            )

            vehicle_arrival_time_at_station_using_machine: HxExpression = model.iif(
                model.neq(h, nb_not_found),
                model.sum(
                    prev_value,
                    model.at(service_time, arc_orig),
                    model.at(d_bar_matrix, arc_orig, h, k),
                ),
                0,
            )

            machine_travel_start_time = model.max(
                machine_travel_potential_start_time,
                vehicle_arrival_time_at_station_using_machine,
            )
            station_orig = model.at(f_matrix, arc_orig, h)
            station_dest = model.at(f_matrix, arc_dest, h)
            using_machine_arrival_time: HxExpression = model.iif(
                model.neq(h, nb_not_found),
                model.sum(
                    machine_travel_start_time,
                    model.at(
                        O_matrix,
                        station_orig,
                        station_dest,
                        h,
                    ),
                    model.at(d_bar_matrix, arc_dest, h, k),
                ),
                0,
            )

            no_machine_arrival_time: HxExpression = model.sum(
                prev_value,
                model.at(service_time, arc_orig),
                model.at(d_matrix, arc_orig, arc_dest, k),
            )
            service_start_time: HxExpression = model.max(
                time_window_earliest_time,
                no_machine_arrival_time,
                using_machine_arrival_time,
            )

            return service_start_time

        services_start_times_lambda: HxExpression = model.lambda_function(
            lambda i, prev: services_start_times_function(i, prev)
        )
        services_start_times[k] = model.array(
            model.range(0, c), services_start_times_lambda, model.at(tstart_array, k)
        )
        ub_services_start_times_lambda: HxExpression = model.lambda_function(
            lambda i: model.leq(
                model.at(services_start_times[k], i),
                model.at(latest, route[i] + offset),
            )
        )
        model.constraint(
            model.and_(
                model.range(0, c),
                ub_services_start_times_lambda,
            )
        )

        # lb_services_start_times_lambda: HxExpression = model.lambda_function(
        #     lambda i: model.geq(
        #         model.at(services_start_times[k], i),
        #         model.at(earliest, route[i] + offset),
        #     )
        # )
        # model.constraint(
        #     model.and_(
        #         model.range(0, c),
        #         lb_services_start_times_lambda,
        #     )
        # )


def constraints_lower_bound_waiting_times(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarlogonHxRoutingVars,
    schvars: BarlogonHxSchedulingVars,
) -> None:
    routes_array: HxExpression = rtvars.routes_array
    trajectories: HxExpression = rtvars.trajectories_array

    tstart_array: List[HxExpression] = schvars.tstart_array
    services_start_times_array: HxExpression = model.array(schvars.services_start_times)
    waiting_times_array: HxExpression = schvars.waiting_times_array
    machine_travels_start_times: List[HxExpression] = (
        schvars.machine_travels_start_times
    )

    # Routing data transformed into hexaly array
    origins_A_m: HxExpression = rtvars.origins_A_m
    destinies_A_m: HxExpression = rtvars.destinies_A_m

    # Scheduling data transformed into hexaly array
    d_bar_matrix: HxExpression = schvars.d_bar_matrix
    O_matrix: HxExpression = schvars.O_matrix
    f_matrix: HxExpression = schvars.f_matrix
    service_time: HxExpression = schvars.service_time
    earliest: HxExpression = schvars.earliest
    latest: HxExpression = schvars.latest
    d_matrix: HxExpression = schvars.d_matrix

    for h in inst.H:
        trajectory = trajectories[h]
        c = model.count(trajectory)

        def lb_waiting_times_function(i: HxExpression) -> HxExpression:
            # find arc_orig in routes
            # compute h_arr in station orig
            # compute k_arr in station orig
            # waiting time >= max(0, k_arr - h_arr)
            is_first = model.eq(i, 0)
            last_i = model.sub(i, 1)
            arc: HxExpression = trajectory[i]
            arc_orig: HxExpression = model.at(origins_A_m, arc)
            arc_dest: HxExpression = model.at(destinies_A_m, arc)
            nb_not_found: int = -1

            prev_arc = trajectory[last_i]
            prev_arc_orig: HxExpression = model.at(origins_A_m, prev_arc)
            prev_arc_dest: HxExpression = model.at(destinies_A_m, prev_arc)

            prev_station_orig = model.iif(
                is_first, inst.initial_station, model.at(f_matrix, prev_arc_orig, h)
            )
            prev_station_dest = model.iif(
                is_first, inst.initial_station, model.at(f_matrix, prev_arc_dest, h)
            )
            station_orig = model.at(f_matrix, arc_orig, h)
            e0 = model.iif(
                is_first,
                0,
                model.sub(
                    model.at(machine_travels_start_times[h], last_i),
                    model.at(waiting_times_array, prev_arc),
                ),
            )
            h_arr = model.sum(
                e0,
                model.at(O_matrix, prev_station_orig, prev_station_dest, h),
                model.at(O_matrix, prev_station_dest, station_orig, h),
            )

            k = model.iif(
                model.eq(arc_orig, inst.depot_begin),
                model.find(routes_array, arc_dest),
                model.find(routes_array, arc_orig),
            )
            idx_in_k = model.iif(
                model.and_(
                    model.neq(k, nb_not_found),
                    model.neq(arc_orig, inst.depot_begin),
                ),
                model.index(model.at(routes_array, k), arc_orig),
                nb_not_found,
            )
            k_tstart = model.iif(
                model.neq(arc_orig, inst.depot_begin),
                model.at(services_start_times_array, k, idx_in_k),
                model.at(tstart_array, k),
            )
            k_arr = model.sum(
                k_tstart,
                model.at(service_time, arc_orig),
                model.at(d_bar_matrix, arc_orig, h, k),
            )

            calculated_waiting_time = model.max(0, model.sub(k_arr, h_arr))

            return model.geq(
                model.at(waiting_times_array, arc), calculated_waiting_time
            )

        lb_waiting_times_lambda = model.lambda_function(
            lambda i: lb_waiting_times_function(i)
        )
        model.constraint(model.and_(model.range(0, c), lb_waiting_times_lambda))


def get_waiting_times_used(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarlogonHxRoutingVars,
    schvars: BarlogonHxSchedulingVars,
) -> None:
    trajectories: HxExpression = rtvars.trajectories_array

    waiting_times_array: HxExpression = schvars.waiting_times_array
    waiting_times_used: HxExpression = schvars.waiting_times_used

    for h in inst.H:
        trajectory = trajectories[h]
        c = model.count(trajectory)

        waiting_time_lambda = model.lambda_function(
            lambda i: model.at(waiting_times_array, trajectory[i])
        )

        waiting_times_used[h] = model.sum(model.array(model.range(0, c), waiting_time_lambda))
    
    



def constraints_tfinal(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarlogonHxRoutingVars,
    schvars: BarlogonHxSchedulingVars,
) -> None:
    routes: HxExpression = rtvars.routes
    trajectories_array: HxExpression = rtvars.trajectories_array

    tstart: List[HxExpression] = schvars.tstart
    tfinal: List[HxExpression] = schvars.tfinal
    services_start_times: List[HxExpression] = schvars.services_start_times
    machine_travels_start_times: List[HxExpression] = (
        schvars.machine_travels_start_times
    )
    machine_travels_start_times_array: HxExpression = model.array(
        machine_travels_start_times
    )

    # Routing data transformed into hexaly array
    idx_A_m: HxExpression = rtvars.idx_A_m

    # Scheduling data transformed into hexaly array
    service_time: HxExpression = schvars.service_time
    d_matrix: HxExpression = schvars.d_matrix
    d_bar_matrix: HxExpression = schvars.d_bar_matrix
    O_matrix: HxExpression = schvars.O_matrix
    f_matrix: HxExpression = schvars.f_matrix

    offset: int = 1

    for k in inst.K:
        route: HxExpression = routes[k]
        c: HxExpression = model.count(route)

        nb_not_found: int = -1
        last_index: HxExpression = model.sub(c, 1)
        last_orig: HxExpression = model.sum(model.at(route, last_index), offset)

        arc_orig: HxExpression = last_orig
        arc_dest: HxExpression = inst.depot_end
        index_A_m = model.at(idx_A_m, arc_orig, arc_dest)

        h: HxExpression = model.iif(
            model.neq(index_A_m, nb_not_found),
            model.find(trajectories_array, index_A_m),
            nb_not_found,
        )

        index_arc_in_h: HxExpression = model.iif(
            model.neq(h, nb_not_found),
            model.index(
                model.at(trajectories_array, h),
                index_A_m,
            ),
            nb_not_found,
        )

        machine_travel_potential_start_time: HxExpression = model.iif(
            model.neq(index_arc_in_h, nb_not_found),
            model.at(machine_travels_start_times_array, h, index_arc_in_h),
            0,
        )

        vehicle_arrival_time_at_station_using_machine: HxExpression = model.iif(
            model.neq(h, nb_not_found),
            model.sum(
                model.at(services_start_times[k], last_index),
                model.at(service_time, arc_orig),
                model.at(d_bar_matrix, arc_orig, h, k),
            ),
            0,
        )

        machine_travel_start_time = model.max(
            machine_travel_potential_start_time,
            vehicle_arrival_time_at_station_using_machine,
        )

        station_orig = model.at(f_matrix, arc_orig, h)
        station_dest = model.at(f_matrix, arc_dest, h)
        arrival_time_from_machine: HxExpression = model.iif(
            model.neq(h, nb_not_found),
            model.sum(
                machine_travel_start_time,
                model.at(
                    O_matrix,
                    station_orig,
                    station_dest,
                    h,
                ),
                model.at(d_bar_matrix, arc_dest, h, k),
            ),
            0,
        )
        arrival_time_no_machine: HxExpression = model.sum(
            model.at(services_start_times[k], last_index),
            model.at(service_time, arc_orig),
            model.at(d_matrix, arc_orig, arc_dest, k),
        )

        tfinal_lowerbound: HxExpression = model.iif(
            model.gt(c, 0),
            model.geq(
                tfinal[k],
                model.max(arrival_time_no_machine, arrival_time_from_machine),
            ),
            True,
        )
        model.constraint(tfinal_lowerbound)

        model.constraint(model.geq(tfinal[k], tstart[k]))


def constraints_completion_time(
    inst: InstanceData,
    model: HxModel,
    schvars: BarlogonHxSchedulingVars,
) -> None:
    tstart: List[HxExpression] = schvars.tstart
    tfinal: List[HxExpression] = schvars.tfinal

    C: List[HxExpression] = schvars.C

    for k in inst.K:
        model.constraint(model.geq(C[k], model.sub(tfinal[k], tstart[k])))


def barlogon_hexaly_scheduling_constraints(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarlogonHxRoutingVars,
    schvars: BarlogonHxSchedulingVars,
    params: ParameterData,
) -> None:
    """
    Scheduling constraints envolving vehicles and machines
    """

    constraints_machine_travels_start_times(inst, model, rtvars, schvars)
    constraints_services_start_times(inst, model, rtvars, schvars)

    # constraints_lower_bound_waiting_times(inst, model, rtvars, schvars)
    get_waiting_times_used(inst, model, rtvars, schvars)

    constraints_tfinal(inst, model, rtvars, schvars)
    constraints_completion_time(inst, model, schvars)
