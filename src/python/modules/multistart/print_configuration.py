from datetime import datetime

from modules.data import InstanceData
from .entities_mslp import AllParams


def print_configuration(inst: InstanceData, all_params: AllParams) -> None:
    now = datetime.now()
    print(
        f"""
------------------------------------------------------
[{now.time().strftime("%H:%M:%S")}] Running Multi Start Heuristic
> Experiment started at {now}
> Instance: {inst.full_name}
> Algorithm Parameters:
"""
    )

    # StopParams fields
    print("\t> Stop params:")
    for field_name, value in vars(all_params.stop).items():
        print(f"\t\t>  - {field_name}: {value}")

    # General params (assumes ParameterData is a dataclass or has __dict__)
    print("\n\t> General params:")
    for field_name, value in vars(all_params.general).items():
        print(f"\t\t>  - {field_name}: {value}")

    print("------------------------------------------------------")
