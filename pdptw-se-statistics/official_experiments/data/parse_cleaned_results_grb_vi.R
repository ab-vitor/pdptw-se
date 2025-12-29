library(readr)
library(dplyr)

benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
off_exp <- "official_experiments"
grb_vi_folder <- "mip_grb_valid_inequalities"
prefix_set <- file.path(off_exp, grb_vi_folder)
prefix_csv_input <- "csvresults_form_melo"
prefix_csv_output <- "csvresults_form_melo"
exp_set <- c("set_03", "set_03")
vi_test <- c("all_minus_one_vi", "all_vi", "no_vi", "one_vi")
ext_csv <- ".csv"

for(i in seq_along(benchmarks)){
  for (j in seq_along(vi_test)){
    csv_input_file_name <- paste0(prefix_csv_input, ext_csv)
    csv_input_file_path <- file.path("..", benchmarks[i], prefix_set, vi_test[j], exp_set[i], csv_input_file_name)
    csv_results <- read_delim(
      csv_input_file_path,
      delim = ";", 
      escape_double = FALSE, 
      trim_ws = TRUE,
      show_col_types = F
    )
    
    csv_results_filtered <- csv_results %>%
      select(
        name, group, type, full_name, time, 
        status, optimal, tle_feas, tle_not_feas, 
        gen_config_filename, gap, obj_value, bestbound,
        numnodes, constraints_used_melo_mip_str
      )
    
    csv_output_file_name <- paste0(prefix_csv_output, "_", variations[i], ext_csv)
    csv_output_file_path <- file.path(off_exp, "data", grb_vi_folder, vi_test[j], csv_output_file_name)
    print(csv_output_file_path)
    
    dir.create(dirname(csv_output_file_path), showWarnings = FALSE, recursive = TRUE)
    
    write_delim(
      csv_results_filtered,
      csv_output_file_path,
      delim = ";"
    )
  }
}