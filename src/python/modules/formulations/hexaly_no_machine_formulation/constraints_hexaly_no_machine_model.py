from typing import List
from modules.data import InstanceData
from modules.parameters import ParameterData
from hexaly.optimizer import HxModel, HxExpression
from .entities_hexaly_no_machine_formulation import (
    MeloHxRoutingVars,
    MeloHxSchedulingVars,
)


def melo_hexaly_routing_constraints(
    inst: InstanceData, params: ParameterData, model: HxModel, rtvars: MeloHxRoutingVars
) -> None:
    """
    Add the routing constraints c1–c10 to `model`.
    """
    routes: List[HxExpression] = rtvars.routes
    routes_array: HxExpression = rtvars.routes_array
    demands: HxExpression = rtvars.demands
    offset: int = 1

    # All customers must be visited by exactly one vehicle
    model.constraint(model.partition(routes))

    # Pickups and deliveries
    for i in inst.V_p:
        p: int = i - offset
        d: int = p + inst.n
        # The same vehicle must attend the whole request (pickup and delivery)
        pick_up_list_index: HxExpression = model.find(routes_array, p)
        delivery_list_index: HxExpression = model.find(routes_array, d)
        model.constraint(pick_up_list_index == delivery_list_index)

        # Pickup is serviced before delivery
        pick_up_list: HxExpression = model.at(routes_array, pick_up_list_index)
        delivery_list: HxExpression = model.at(routes_array, delivery_list_index)
        model.constraint(model.index(pick_up_list, p) < model.index(delivery_list, d))

    # Capacity constraint
    for k in inst.K:
        sequence: HxExpression = routes[k]
        c: HxExpression = model.count(sequence)

        # The maximum load achieved in each route must not exceed the
        # vehicle capacity at any point in the sequence
        demand_lambda: HxExpression = model.lambda_function(
            lambda i, prev: prev + demands[sequence[i] + offset]
        )
        route_load: HxExpression = model.array(model.range(0, c), demand_lambda, 0)

        load_lambda: HxExpression = model.lambda_function(
            lambda i: route_load[i] <= inst.Q[k]
        )
        model.constraint(model.and_(model.range(0, c), load_lambda))


def melo_hexaly_scheduling_constraints(
    inst: InstanceData,
    model: HxModel,
    rtvars: MeloHxRoutingVars,
    schvars: MeloHxSchedulingVars,
) -> None:

    routes: HxExpression = rtvars.routes

    tstart: HxExpression = schvars.tstart
    tfinal: HxExpression = schvars.tfinal
    C: HxExpression = schvars.C
    earliest: HxExpression = schvars.earliest
    latest: HxExpression = schvars.latest
    d_matrix: HxExpression = schvars.d_matrix
    service_time: HxExpression = schvars.service_time
    service_start_time: HxExpression = schvars.service_start_time

    offset = 1

    for k in inst.K:
        sequence: HxExpression = routes[k]
        c: HxExpression = model.count(sequence)

        service_start_time_lambda: HxExpression = model.lambda_function(
            lambda i, prev: model.max(
                model.at(earliest, sequence[i] + offset),
                model.iif(
                    i == 0,
                    tstart[k]
                    + model.at(d_matrix, inst.depot_begin, sequence[i] + offset, k),
                    prev
                    + model.at(service_time, sequence[i - 1] + offset)
                    + model.at(
                        d_matrix, sequence[i - 1] + offset, sequence[i] + offset, k
                    ),
                ),
            )
        )
        service_start_time[k] = model.array(
            model.range(0, c), service_start_time_lambda, 0
        )
        ub_service_start_time_lambda: HxExpression = model.lambda_function(
            lambda i: service_start_time[k][i] <= model.at(latest, sequence[i] + offset)
        )
        model.constraint(model.and_(model.range(0, c), ub_service_start_time_lambda))

        model.constraint(
            tfinal[k]
            == model.iif(
                c > 0,
                service_start_time[k][c - 1]
                + model.at(service_time, sequence[c - 1] + offset)
                + model.at(d_matrix, sequence[c - 1] + offset, inst.depot_end, k),
                tstart[k],
            )
        )

        model.constraint(tfinal[k] <= inst.l[inst.depot_begin])
        model.constraint(tstart[k] <= tfinal[k])

        model.constraint(C[k] == tfinal[k] - tstart[k])
