library(readr)
library(dplyr)

benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("multi_island", "multi_floor")
exp_set <- c("set_02", "set_02")
off_exp <- "official_experiments"
grb_folder <- "mip_gurobi"
hx_folder <- "mip_hexaly"
set_grb_path_b <- file.path(off_exp, grb_folder)
set_hx_path_b <- file.path(off_exp, hx_folder)
csv_input_grb <- "csvresults_form_melo"
csv_input_hx <- "csvresults_form_melo_hx"
ext_csv <- ".csv"

for(i in seq_along(benchmarks)){
  csvr_df_grb_file_name <- paste0(csv_input_grb, ext_csv)
  csvr_df_grb_file_path <- file.path("..", benchmarks[i], set_grb_path_b, exp_set[i], csvr_df_grb_file_name)
  
  csvr_df_grb <- read_delim(
    file = csvr_df_grb_file_path,
    delim = ";"
  )
  
  csvr_df_hx_file_name <- paste0(csv_input_hx, ext_csv)
  csvr_df_hx_file_path <- file.path("..", benchmarks[i], set_hx_path_b, exp_set[i], csvr_df_hx_file_name)
  
  csvr_df_hx <- read_delim(
    file = csvr_df_hx_file_path,
    delim = ";"
  )
  
  csvr_df_grb <- csvr_df_grb %>%
    rename(obj_value = any_of("objValue")) %>%
    select(name, group, type, full_name, obj_value, gap, n_vehicles_used, time, status, optimal, tle_feas, tle_not_feas, constraints_used_melo_mip_str) %>%
    rename(
      obj_value_grb = obj_value,
      gap_grb = gap,
      n_vehicles_used_grb = n_vehicles_used,
      time_grb = time
    ) %>%
    mutate(
      obj_value_grb = ifelse(n_vehicles_used_grb != 0 & obj_value_grb != Inf & !is.na(obj_value_grb), obj_value_grb, NA)
    )
  
  csvr_df_hx <- csvr_df_hx %>%
    rename(obj_value = any_of("objValue")) %>%
    select(name, group, type, full_name, obj_value, gap, n_vehicles_used, time, status, optimal, tle_feas, tle_not_feas) %>%
    rename(
      obj_value_hx = obj_value,
      gap_hx = gap,
      n_vehicles_used_hx = n_vehicles_used,
      time_hx = time
    ) %>%
    mutate(
      obj_value_hx = ifelse(n_vehicles_used_hx != 0 & obj_value_hx != Inf & !is.na(obj_value_hx), obj_value_hx, NA)
    )
  
  csvr_df_grb_file_name <- paste0(csv_input_grb, "_", variations[i], ext_csv)
  csvr_df_hx_file_name <- paste0(csv_input_hx, "_", variations[i], ext_csv)
  csvr_df_grb_file_path <- file.path(off_exp, "data", grb_folder, csvr_df_grb_file_name)
  csvr_df_hx_file_path <- file.path(off_exp, "data", hx_folder, csvr_df_hx_file_name)
  
  write_delim(
    csvr_df_grb,
    file = csvr_df_grb_file_path,
    delim = ";"
  )
  write_delim(
    csvr_df_hx,
    file = csvr_df_hx_file_path,
    delim = ";"
  )
}
