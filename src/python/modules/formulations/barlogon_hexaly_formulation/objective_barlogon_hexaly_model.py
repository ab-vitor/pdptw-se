from hexaly.optimizer import HxModel, HxExpression
from modules.data import InstanceData
from .entities_barlogon_hexaly_formulation import BarlogonHxSchedulingVars

def barlogon_hexaly_objective_function(
    model: HxModel, inst: InstanceData, schvars: BarlogonHxSchedulingVars
) -> None:
    C = schvars.C
    total_completion_time = model.sum([C[(k)] for k in inst.K])
    model.minimize(total_completion_time)

    # services_start_times = [model.sum(schvars.services_start_times[k]) for k in inst.K]
    # services_start_times_array = model.array(services_start_times)
    # model.minimize(model.sum(services_start_times_array))

    # waiting_times_used = schvars.waiting_times_used
    # waiting_times_used_array = model.array(waiting_times_used)
    # model.maximize(model.sum(waiting_times_used_array))
