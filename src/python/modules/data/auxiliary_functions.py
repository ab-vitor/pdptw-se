import math

from .entities import InstanceData, Point

def euclidean_dist(p1: Point, p2: Point, elev: int) -> float:
    d = math.sqrt((p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2 + elev * (p1.z - p2.z) ** 2)
    return round(d, 2)

def is_min_t_arrival_infeasible(nodes: list[int], inst: InstanceData) -> bool:
    for k in inst.K:
        t = inst.eprime[nodes[0]]
        for idx in range(1, len(nodes)):
            prev = nodes[idx - 1]
            curr = nodes[idx]
            t = max(inst.eprime[curr], t + inst.s[prev] + inst.d[prev, curr, k])

        if t <= inst.lprime[nodes[-1]]:
            return False
        
    return True

def is_min_t_arrival_infeasible_k(nodes: list[int], inst: InstanceData, k: int) -> bool:
    t = inst.eprime[nodes[0]]
    for idx in range(1, len(nodes)):
        prev = nodes[idx - 1]
        curr = nodes[idx]
        t = max(inst.eprime[curr], t + inst.s[prev] + inst.d[prev, curr, k])

    if t <= inst.lprime[nodes[-1]]:
        return False
        
    return True


def valid_path(nodes: list[int], inst: InstanceData, w: int) -> bool:
    for idx in range(w):
        if not inst.in_A[nodes[idx], nodes[idx + 1]]:
            return False
    return True


def valid_path_m(nodes: list[int], inst: InstanceData, w: int) -> bool:
    for idx in range(w):
        if not inst.in_A_m[nodes[idx], nodes[idx + 1]]:
            return False
    return True