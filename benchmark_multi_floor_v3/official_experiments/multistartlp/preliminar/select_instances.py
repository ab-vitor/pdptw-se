import random

rng = random.Random(1)

types = [1,2]

groups = [
    "08R_08V_02F_04M",
    "08R_08V_04F_04M",
    "12R_12V_02F_04M",
    "12R_12V_04F_04M",
]
n_machs = [3,4]

for i in range(4):
    for j in range(len(n_machs)):
        for k in range(len(types)):
            inst = rng.randint(1, 5) + 5
            print(f"lr{types[k]}{inst:02d} {groups[i]} {n_machs[j]}")

groups = [
    "40R_40V_02F_06M",
    "40R_40V_04F_06M",
    "60R_60V_02F_06M",
    "60R_60V_04F_06M",
]
n_machs = [5,6]

for i in range(4):
    for j in range(len(n_machs)):
        for k in range(len(types)):
            inst = rng.randint(1, 5) + 5
            print(f"LR{types[k]}_2_{inst} {groups[i]} {n_machs[j]}")