import random

rng = random.Random(1)


def i_to_type(n):
    pattern = [1, 2, 2, 1]
    return pattern[n % 4]

def i_to_n_machs(n):
    pattern = [4, 3, 3, 4]
    return pattern[n % 4]


groups = [
    "06R_06V_02F_04M",
    "06R_06V_04F_04M",
    "08R_08V_02F_04M",
    "08R_08V_04F_04M",
    "10R_10V_02F_04M",
    "10R_10V_04F_04M",
    "12R_12V_02F_04M",
    "12R_12V_04F_04M",
]

for i in range(8):
    inst = rng.randint(1, 5) + 5
    type = i_to_type(i)
    n_machs = i_to_n_machs(i)
    print(f"lr{type}{inst:02d} {groups[i]} {n_machs}")
