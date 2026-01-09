mf=$1

# Group 06R_06V_02F_04M
python3.9 small_inst_gen_floors.py --group pdptw_100_li_lim --req 6 --vehi 6 --floors 2 --mach 4 --min_mach 3 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

# Group 06R_06V_04F_04M
python3.9 small_inst_gen_floors.py --group pdptw_100_li_lim --req 6 --vehi 6 --floors 4 --mach 4 --min_mach 3 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

# Group 08R_08V_02F_04M
python3.9 small_inst_gen_floors.py --group pdptw_100_li_lim --req 8 --vehi 8 --floors 2 --mach 4 --min_mach 3 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

# Group 08R_08V_04F_04M
python3.9 small_inst_gen_floors.py --group pdptw_100_li_lim --req 8 --vehi 8 --floors 4 --mach 4 --min_mach 3 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

# Group 10R_10V_02F_04M
python3.9 small_inst_gen_floors.py --group pdptw_100_li_lim --req 10 --vehi 10 --floors 2 --mach 4 --min_mach 3 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

# Group 10R_10V_04F_04M
python3.9 small_inst_gen_floors.py --group pdptw_100_li_lim --req 10 --vehi 10 --floors 4 --mach 4 --min_mach 3 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

# Group 12R_12V_02F_04M
python3.9 small_inst_gen_floors.py --group pdptw_100_li_lim --req 12 --vehi 12 --floors 2 --mach 4 --min_mach 3 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

# Group 12R_12V_04F_04M
python3.9 small_inst_gen_floors.py --group pdptw_100_li_lim --req 12 --vehi 12 --floors 4 --mach 4 --min_mach 3 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

# Group 40R_40V_02F_06M
python3.9 small_inst_gen_floors.py --group pdptw_200_li_lim --req 40 --vehi 40 --floors 2 --mach 6 --min_mach 5 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

# Group 40R_40V_04F_06M
python3.9 small_inst_gen_floors.py --group pdptw_200_li_lim --req 40 --vehi 40 --floors 4 --mach 6 --min_mach 5 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

# Group 60R_60V_02F_06M
python3.9 small_inst_gen_floors.py --group pdptw_200_li_lim --req 60 --vehi 60 --floors 2 --mach 6 --min_mach 5 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

# Group 60R_60V_04F_06M
python3.9 small_inst_gen_floors.py --group pdptw_200_li_lim --req 60 --vehi 60 --floors 4 --mach 6 --min_mach 5 --var_cap 20 --mach_spd 0.2 --ams --mf ${mf}

