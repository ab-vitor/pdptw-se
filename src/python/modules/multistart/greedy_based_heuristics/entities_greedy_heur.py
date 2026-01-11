from dataclasses import dataclass, field
from typing import List


@dataclass
class PossibleMachineTravel:
    found: bool  # whether a travel was found
    deltaT: float  # time between service and next vehicle stop
    h: int  # index of machine used
    h_pos: int  # index in machine h where travel is inserted
    st: float  # start time of travel
    orig: int  # origin node in V_prime
    dest: int  # destination node in V_prime
    vehicle_ind: int  # vehicle index where travel is inserted


@dataclass
class InsertionData:
    is_feasible: bool
    cost: float
    pPos: int  # pickup insertion position
    dPos: int  # delivery insertion position
    pJob: int  # pickup job index
    dJob: int  # delivery job index
    k: int  # vehicle index
    machine_travels: List[List[PossibleMachineTravel]] = field(default_factory=list)


@dataclass
class CheckInsertionData:
    feasible: bool
    cost: float
    possibleMachineTravels: List[List[PossibleMachineTravel]] = field(
        default_factory=list
    )
