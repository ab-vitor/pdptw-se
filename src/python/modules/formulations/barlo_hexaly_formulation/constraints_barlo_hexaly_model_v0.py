from typing import List, Optional
from modules.data import InstanceData
from modules.parameters import ParameterData
from hexaly.optimizer import HxModel, HxExpression
from .entities_barlo_hexaly_formulation import (
    BarloHxRoutingVars,
    BarloHxSchedulingVars,
)


def barlo_hexaly_routing_constraints(
    inst: InstanceData,
    params: ParameterData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
) -> None:
    """
    Routing constraints for both vehicles and machines
    """
    routes: List[HxExpression] = rtvars.routes
    routes_array: HxExpression = rtvars.routes_array
    demands: HxExpression = rtvars.demands
    routes_loads: List[Optional[HxExpression]] = rtvars.routes_loads

    trajectories: List[HxExpression] = rtvars.trajectories
    trajectories_array: HxExpression = rtvars.trajectories_array
    origins_A_m: HxExpression = rtvars.origins_A_m
    destinies_A_m: HxExpression = rtvars.destinies_A_m
    idx_A_m: HxExpression = rtvars.idx_A_m
    diff_region: HxExpression = rtvars.diff_region

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
            # expressions already calculated

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


def constraints_machine_travels_start_times_machine(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
) -> None:
    trajectories: List[HxExpression] = rtvars.trajectories

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

        def machine_travel_start_times_function(
            i: HxExpression, prev_value: HxExpression
        ) -> HxExpression:
            is_first: HxExpression = model.eq(i, 0)
            orig: HxExpression = model.at(origins_A_m, trajectory[i])

            last_i: HxExpression = model.sub(i, 1)

            prev_orig: HxExpression = model.at(origins_A_m, trajectory[last_i])
            prev_dest: HxExpression = model.at(destinies_A_m, trajectory[last_i])

            machine_arrival_time: HxExpression = model.iif(
                is_first,
                model.at(
                    O_matrix, inst.initial_station, model.at(f_matrix, orig, h), h
                ),
                model.sum(
                    prev_value,
                    model.at(
                        O_matrix,
                        model.at(f_matrix, prev_orig, h),
                        model.at(f_matrix, prev_dest, h),
                        h,
                    ),
                    model.at(
                        O_matrix,
                        model.at(f_matrix, prev_dest, h),
                        model.at(f_matrix, orig, h),
                        h,
                    ),
                ),
            )

            return machine_arrival_time

        machine_travels_start_times_lambda: HxExpression = model.lambda_function(
            machine_travel_start_times_function
        )
        machine_travels_start_times[h] = model.array(
            model.range(0, c), machine_travels_start_times_lambda, 0
        )


def constraints_service_start_times_vehicle(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
) -> None:

    routes: HxExpression = rtvars.routes

    tstart_array: HxExpression = schvars.tstart_array
    service_start_times: List[Optional[HxExpression]] = schvars.service_start_times

    # Scheduling data transformed into hexaly array
    service_time: HxExpression = schvars.service_time
    earliest: HxExpression = schvars.earliest
    d_matrix: HxExpression = schvars.d_matrix

    offset: int = 1

    for k in inst.K:
        route: HxExpression = routes[k]
        c: HxExpression = model.count(route)

        def service_start_times_function(
            i: HxExpression, prev_value: HxExpression
        ) -> HxExpression:
            is_first: HxExpression = model.eq(i, 0)
            last_i: HxExpression = model.sub(i, 1)

            curr: HxExpression = route[i]
            prev: HxExpression = route[last_i]
            curr_offset: HxExpression = model.sum(curr, offset)
            prev_offset: HxExpression = model.sum(prev, offset)

            time_window_earliest_time: HxExpression = model.at(earliest, curr_offset)

            no_machine_arrival_time_from_depot: HxExpression = model.sum(
                model.at(tstart_array, k),
                model.at(d_matrix, inst.depot_begin, curr_offset, k),
            )
            no_machine_arrival_time_general_case: HxExpression = model.sum(
                prev_value,
                model.at(service_time, prev_offset),
                model.at(d_matrix, prev_offset, curr_offset, k),
            )

            no_machine_arrival_time: HxExpression = model.iif(
                is_first,
                no_machine_arrival_time_from_depot,
                no_machine_arrival_time_general_case,
            )

            service_start_time = model.max(
                time_window_earliest_time,
                no_machine_arrival_time,
            )
            return service_start_time

        service_start_times_lambda: HxExpression = model.lambda_function(
            lambda i, prev: service_start_times_function(i, prev)
        )
        service_start_times[k] = model.array(
            model.range(0, c), service_start_times_lambda, 0
        )


def constraints_machine_travels_start_times(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
) -> None:
    routes_array: HxExpression = rtvars.routes_array
    trajectories: List[HxExpression] = rtvars.trajectories

    tstart_array: HxExpression = schvars.tstart_array
    t_array: HxExpression = schvars.t_array
    machine_travels_start_times: HxExpression = schvars.machine_travels_start_times

    # Routing data transformed into hexaly array
    origins_A_m: HxExpression = rtvars.origins_A_m
    destinies_A_m: HxExpression = rtvars.destinies_A_m

    # Scheduling data transformed into hexaly array
    service_time: HxExpression = schvars.service_time
    d_bar_matrix: HxExpression = schvars.d_bar_matrix
    O_matrix: HxExpression = schvars.O_matrix
    f_matrix: HxExpression = schvars.f_matrix

    offset: int = 1

    for h in inst.H:
        trajectory: HxExpression = trajectories[h]
        c: HxExpression = model.count(trajectory)

        def machine_travels_start_times_function(
            i: HxExpression, prev_value: HxExpression
        ) -> HxExpression:
            orig: HxExpression = model.at(origins_A_m, trajectory[i])
            dest: HxExpression = model.at(destinies_A_m, trajectory[i])
            orig_offset: HxExpression = model.sub(orig, offset)
            dest_offset: HxExpression = model.sub(dest, offset)

            nb_not_found: int = -1

            index_route_orig: HxExpression = model.find(routes_array, orig_offset)
            index_route_dest: HxExpression = model.find(routes_array, dest_offset)

            found_orig = model.neq(index_route_orig, nb_not_found)
            is_orig_depot_begin: HxExpression = model.eq(orig, inst.depot_begin)
            found_dest: HxExpression = model.neq(index_route_dest, nb_not_found)

            vehicle_arrival_time_from_depot: HxExpression = model.iif(
                model.and_(
                    is_orig_depot_begin,
                    found_dest,
                ),
                model.sum(
                    model.at(tstart_array, index_route_dest),
                    model.at(d_bar_matrix, orig, h, index_route_dest),
                ),
                prev_value,
            )

            vehicle_arrival_time_general_case: HxExpression = model.iif(
                found_orig,
                model.sum(
                    model.at(t_array, orig_offset),
                    model.at(service_time, orig),
                    model.at(d_bar_matrix, orig, h, index_route_orig),
                ),
                prev_value,
            )

            vehicle_arrival_time: HxExpression = model.iif(
                found_orig,
                vehicle_arrival_time_general_case,
                vehicle_arrival_time_from_depot,
            )

            is_first: HxExpression = model.eq(i, 0)
            last_i: HxExpression = model.sub(i, 1)

            prev_orig: HxExpression = model.at(origins_A_m, trajectory[last_i])
            prev_dest: HxExpression = model.at(destinies_A_m, trajectory[last_i])

            machine_arrival_time: HxExpression = model.iif(
                is_first,
                model.at(
                    O_matrix, inst.initial_station, model.at(f_matrix, orig, h), h
                ),
                model.sum(
                    prev_value,
                    model.at(
                        O_matrix,
                        model.at(f_matrix, prev_orig, h),
                        model.at(f_matrix, prev_dest, h),
                        h,
                    ),
                    model.at(
                        O_matrix,
                        model.at(f_matrix, prev_dest, h),
                        model.at(f_matrix, orig, h),
                        h,
                    ),
                ),
            )

            machine_travel_start_time = model.max(
                vehicle_arrival_time, machine_arrival_time
            )
            return machine_travel_start_time

        machine_travels_start_times_lambda: HxExpression = model.lambda_function(
            machine_travels_start_times_function
        )
        machine_travels_start_times[h] = model.array(
            model.range(0, c), machine_travels_start_times_lambda, 0
        )


def constraints_service_start_times(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
) -> None:

    routes: HxExpression = rtvars.routes
    trajectories_array: HxExpression = rtvars.trajectories_array

    tstart_array: HxExpression = schvars.tstart_array
    service_start_times: List[Optional[HxExpression]] = schvars.service_start_times
    alpha_array: List[Optional[HxExpression]] = schvars.alpha_array

    # Routing data transformed into hexaly array
    idx_A_m: HxExpression = rtvars.idx_A_m
    diff_region: HxExpression = rtvars.diff_region

    # Scheduling data transformed into hexaly array
    d_bar_matrix: HxExpression = schvars.d_bar_matrix
    O_matrix: HxExpression = schvars.O_matrix
    f_matrix: HxExpression = schvars.f_matrix
    service_time: HxExpression = schvars.service_time
    earliest: HxExpression = schvars.earliest
    d_matrix: HxExpression = schvars.d_matrix

    offset: int = 1

    for k in inst.K:
        route: HxExpression = routes[k]
        c: HxExpression = model.count(route)

        def service_start_times_function(
            i: HxExpression, prev_value: HxExpression
        ) -> HxExpression:
            is_first: HxExpression = model.eq(i, 0)
            last_i: HxExpression = model.sub(i, 1)

            curr: HxExpression = route[i]
            prev: HxExpression = route[last_i]
            curr_offset: HxExpression = model.sum(curr, offset)
            prev_offset: HxExpression = model.sum(prev, offset)

            time_window_earliest_time: HxExpression = model.at(earliest, curr_offset)

            using_machine: HxExpression = model.at(
                diff_region, prev_offset, curr_offset
            )
            using_machine_from_depot: HxExpression = model.at(
                diff_region, inst.depot_begin, curr_offset
            )

            index_arc_in_A_m: HxExpression = model.at(idx_A_m, prev_offset, curr_offset)
            index_arc_in_A_m_from_depot: HxExpression = model.at(
                idx_A_m, inst.depot_begin, curr_offset
            )

            index_machine_arc_in_A_m: HxExpression = model.find(
                trajectories_array, index_arc_in_A_m
            )
            index_machine_arc_in_A_m_from_depot: HxExpression = model.find(
                trajectories_array, index_arc_in_A_m_from_depot
            )

            using_machine_arrival_time_from_depot = model.iif(
                using_machine_from_depot,
                model.sum(
                    model.at(
                        alpha_array,
                        index_arc_in_A_m_from_depot,
                    ),
                    model.at(
                        O_matrix,
                        model.at(
                            f_matrix,
                            inst.depot_begin,
                            index_machine_arc_in_A_m_from_depot,
                        ),
                        model.at(
                            f_matrix,
                            curr_offset,
                            index_machine_arc_in_A_m_from_depot,
                        ),
                        index_machine_arc_in_A_m_from_depot,
                    ),
                    model.at(
                        d_bar_matrix,
                        curr_offset,
                        index_machine_arc_in_A_m_from_depot,
                        k,
                    ),
                ),
                prev_value,
            )

            using_machine_arrival_time_general_case: HxExpression = model.iif(
                using_machine,
                model.sum(
                    model.at(
                        alpha_array,
                        index_arc_in_A_m,
                    ),
                    model.at(
                        O_matrix,
                        model.at(
                            f_matrix,
                            prev_offset,
                            index_machine_arc_in_A_m,
                        ),
                        model.at(
                            f_matrix,
                            curr_offset,
                            index_machine_arc_in_A_m,
                        ),
                        index_machine_arc_in_A_m,
                    ),
                    model.at(
                        d_bar_matrix,
                        curr_offset,
                        index_machine_arc_in_A_m,
                        k,
                    ),
                ),
                prev_value,
            )

            using_machine_arrival_time: HxExpression = model.iif(
                is_first,
                using_machine_arrival_time_from_depot,
                using_machine_arrival_time_general_case,
            )

            no_machine_arrival_time_from_depot: HxExpression = model.sum(
                model.at(tstart_array, k),
                model.at(d_matrix, inst.depot_begin, curr_offset, k),
            )
            no_machine_arrival_time_general_case: HxExpression = model.sum(
                prev_value,
                model.at(service_time, prev_offset),
                model.at(d_matrix, prev_offset, curr_offset, k),
            )

            no_machine_arrival_time: HxExpression = model.iif(
                is_first,
                no_machine_arrival_time_from_depot,
                no_machine_arrival_time_general_case,
            )

            service_start_time = model.max(
                time_window_earliest_time,
                no_machine_arrival_time,
                using_machine_arrival_time,
            )

            return service_start_time

        service_start_times_lambda: HxExpression = model.lambda_function(
            lambda i, prev: service_start_times_function(i, prev)
        )
        service_start_times[k] = model.array(
            model.range(0, c), service_start_times_lambda, 0
        )


def constraints_equalize_machine_travels_start_times_with_alpha_array(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
    params: ParameterData,
) -> None:
    trajectories: HxExpression = rtvars.trajectories
    alpha_array: HxExpression = schvars.alpha_array

    diff_machine_travel_start_time_alpha = [None] * len(inst.H)
    for h in inst.H:
        trajectory: HxExpression = trajectories[h]
        c: HxExpression = model.count(trajectory)

        diff_machine_travel_start_time_alpha_lambda: HxExpression = (
            model.lambda_function(
                lambda i: model.abs(
                    model.sub(
                        model.at(alpha_array, trajectory[i]),
                        model.at(schvars.machine_travels_start_times[h], i),
                    )
                )
            )
        )

        diff_machine_travel_start_time_alpha[h] = model.sum(
            model.array(
                model.range(0, c),
                diff_machine_travel_start_time_alpha_lambda,
            )
        )

    sum_diff_machine_travel_start_time_alpha: HxExpression = model.sum(
        diff_machine_travel_start_time_alpha
    )
    model.constraint(
        model.leq(
            sum_diff_machine_travel_start_time_alpha,
            params.epsilon,
        )
    )
    # model.minimize(
    #     sum_diff_machine_travel_start_time_alpha,
    # )


def constraints_equalize_service_start_times_with_t_array(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
    params: ParameterData,
) -> None:
    routes: HxExpression = rtvars.routes
    t_array: HxExpression = schvars.t_array

    diff_service_start_time_t_array = [None] * len(inst.K)
    for k in inst.K:
        route: HxExpression = routes[k]
        c: HxExpression = model.count(route)

        diff_service_start_time_t_array_lambda: HxExpression = model.lambda_function(
            lambda i: model.abs(
                model.sub(
                    model.at(t_array, route[i]),
                    model.at(schvars.service_start_times[k], i),
                )
            )
        )

        diff_service_start_time_t_array[k] = model.sum(
            model.array(
                model.range(0, c),
                diff_service_start_time_t_array_lambda,
            )
        )

    sum_diff_service_start_time_t_array: HxExpression = model.sum(
        diff_service_start_time_t_array
    )
    model.constraint(
        model.leq(
            sum_diff_service_start_time_t_array,
            params.epsilon,
        )
    )
    # model.minimize(
    #     sum_diff_service_start_time_t_array,
    # )


def constraints_ub_service_start_time_no_sync(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
):
    routes: HxExpression = rtvars.routes
    trajectories_array: HxExpression = rtvars.trajectories_array

    tstart: List[HxExpression] = schvars.tstart
    tfinal: List[HxExpression] = schvars.tfinal
    service_start_times: List[HxExpression] = schvars.service_start_times
    machine_travels_start_times: List[HxExpression] = (
        schvars.machine_travels_start_times
    )

    t_array: HxExpression = schvars.t_array
    alpha_array: HxExpression = schvars.alpha_array

    C: List[HxExpression] = schvars.C

    # Routing data transformed into hexaly array
    idx_A_m: HxExpression = rtvars.idx_A_m

    # Scheduling data transformed into hexaly array
    service_time: HxExpression = schvars.service_time
    latest: HxExpression = schvars.latest
    d_matrix: HxExpression = schvars.d_matrix
    d_bar_matrix: HxExpression = schvars.d_bar_matrix
    O_matrix: HxExpression = schvars.O_matrix
    f_matrix: HxExpression = schvars.f_matrix

    offset: int = 1

    for k in inst.K:
        route: HxExpression = routes[k]
        c: HxExpression = model.count(route)

        ub_service_start_time_lambda: HxExpression = model.lambda_function(
            lambda i: model.leq(
                # model.at(t_array, model.at(route, i)),
                model.at(service_start_times[k], i),
                model.at(latest, model.sum(model.at(route, i), offset)),
            )
        )
        ub_service_start_time = model.and_(
            model.range(0, c), ub_service_start_time_lambda
        )
        model.constraint(ub_service_start_time)


def constraints_ub_service_start_time_sync(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
):
    routes: HxExpression = rtvars.routes
    t_array: HxExpression = schvars.t_array

    # Scheduling data transformed into hexaly array
    latest: HxExpression = schvars.latest

    offset: int = 1

    for k in inst.K:
        route: HxExpression = routes[k]
        c: HxExpression = model.count(route)

        ub_service_start_time_lambda: HxExpression = model.lambda_function(
            lambda i: model.leq(
                model.at(t_array, model.at(route, i)),
                model.at(latest, model.sum(model.at(route, i), offset)),
            )
        )
        ub_service_start_time = model.and_(
            model.range(0, c), ub_service_start_time_lambda
        )
        model.constraint(ub_service_start_time)


def constraints_tfinal_no_sync(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
):
    routes: HxExpression = rtvars.routes

    tfinal: List[HxExpression] = schvars.tfinal
    service_start_times: List[HxExpression] = schvars.service_start_times

    # Scheduling data transformed into hexaly array
    service_time: HxExpression = schvars.service_time
    d_matrix: HxExpression = schvars.d_matrix

    offset: int = 1

    for k in inst.K:
        route: HxExpression = routes[k]
        c: HxExpression = model.count(route)

        last_index: HxExpression = model.sub(c, 1)
        last_orig: HxExpression = model.sum(model.at(route, last_index), offset)

        arrival_time_from_last_node: HxExpression = model.iif(
            model.gt(c, 0),
            model.geq(
                tfinal[k],
                model.sum(
                    model.at(service_start_times[k], last_index),
                    model.at(
                        service_time,
                        last_orig,
                    ),
                    model.at(
                        d_matrix,
                        last_orig,
                        inst.depot_end,
                        k,
                    ),
                ),
            ),
            True,
        )
        model.constraint(arrival_time_from_last_node)


def constraints_tfinal_sync(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
):
    routes: HxExpression = rtvars.routes
    trajectories_array: HxExpression = rtvars.trajectories_array

    tstart: List[HxExpression] = schvars.tstart
    tfinal: List[HxExpression] = schvars.tfinal
    service_start_times: List[HxExpression] = schvars.service_start_times
    machine_travels_start_times: List[HxExpression] = (
        schvars.machine_travels_start_times
    )

    t_array: HxExpression = schvars.t_array
    alpha_array: HxExpression = schvars.alpha_array

    C: List[HxExpression] = schvars.C

    # Routing data transformed into hexaly array
    idx_A_m: HxExpression = rtvars.idx_A_m

    # Scheduling data transformed into hexaly array
    service_time: HxExpression = schvars.service_time
    latest: HxExpression = schvars.latest
    d_matrix: HxExpression = schvars.d_matrix
    d_bar_matrix: HxExpression = schvars.d_bar_matrix
    O_matrix: HxExpression = schvars.O_matrix
    f_matrix: HxExpression = schvars.f_matrix

    offset: int = 1

    for k in inst.K:
        route: HxExpression = routes[k]
        c: HxExpression = model.count(route)

        last_index: HxExpression = model.sub(c, 1)
        last_orig: HxExpression = model.sum(model.at(route, last_index), offset)
        index_A_m = model.at(idx_A_m, last_orig, inst.depot_end)

        machine_last_arc: HxExpression = model.find(trajectories_array, index_A_m)
        nb_not_found: int = -1
        arrival_time_from_machine: HxExpression = model.iif(
            model.gt(c, 0),
            model.geq(
                tfinal[k],
                model.iif(
                    model.neq(machine_last_arc, nb_not_found),
                    model.sum(
                        model.at(alpha_array, index_A_m),
                        model.at(
                            O_matrix,
                            model.at(f_matrix, last_orig, machine_last_arc),
                            model.at(f_matrix, inst.depot_end, machine_last_arc),
                            machine_last_arc,
                        ),
                        model.at(
                            d_bar_matrix,
                            model.at(f_matrix, inst.depot_end, machine_last_arc),
                            machine_last_arc,
                            k,
                        ),
                    ),
                    tstart[k],
                ),
            ),
            True,
        )
        model.constraint(arrival_time_from_machine)
        arrival_time_from_last_node: HxExpression = model.iif(
            model.gt(c, 0),
            model.geq(
                tfinal[k],
                model.sum(
                    # model.at(t_array, model.at(route, last_index)),
                    model.at(service_start_times[k], last_index),
                    model.at(
                        service_time,
                        last_orig,
                    ),
                    model.at(
                        d_matrix,
                        last_orig,
                        inst.depot_end,
                        k,
                    ),
                ),
            ),
            True,
        )
        model.constraint(arrival_time_from_last_node)


def constraints_completion_time(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
):
    tstart: List[HxExpression] = schvars.tstart
    tfinal: List[HxExpression] = schvars.tfinal

    C: List[HxExpression] = schvars.C

    for k in inst.K:
        model.constraint(model.geq(tfinal[k], tstart[k]))
        model.constraint(model.geq(C[k], model.sub(tfinal[k], tstart[k])))


def barlo_hexaly_scheduling_constraints(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
    params: ParameterData,
) -> None:
    """
    Scheduling constraints envolving vehicles and machines
    """

    if params.validate_synchronization:
        constraints_machine_travels_start_times(inst, model, rtvars, schvars)
        constraints_service_start_times(inst, model, rtvars, schvars)
        constraints_equalize_machine_travels_start_times_with_alpha_array(
            inst, model, rtvars, schvars, params
        )
        constraints_equalize_service_start_times_with_t_array(
            inst, model, rtvars, schvars, params
        )
        constraints_ub_service_start_time_sync(inst, model, rtvars, schvars)
        constraints_tfinal_sync(inst, model, rtvars, schvars)
    else:
        constraints_machine_travels_start_times_machine(inst, model, rtvars, schvars)
        constraints_service_start_times_vehicle(inst, model, rtvars, schvars)
        constraints_ub_service_start_time_no_sync(inst, model, rtvars, schvars)
        constraints_tfinal_no_sync(inst, model, rtvars, schvars)

    constraints_completion_time(inst, model, rtvars, schvars)
