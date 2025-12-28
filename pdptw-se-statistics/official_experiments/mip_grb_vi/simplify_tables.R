library(readr)
library(dplyr)

benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_set <- "official_experiments/mip_grb_valid_inequalities"
prefix_csv_input <- "csvresults_form_melo"
prefix_csv_output <- "csvresults_form_melo_simplified"
exp_set <- c("set_03", "set_03")
vi_test <- c("all_minus_one_vi", "all_vi", "no_vi", "one_vi")

for(i in seq_along(benchmarks)){
  for (j in seq_along(vi_test)){
    csv_input <- paste0(
      "../",
      benchmarks[i],
      "/",
      prefix_set,
      "/",
      vi_test[j],
      "/",
      exp_set[i],
      "/",
      prefix_csv_input,
      ".csv"
    )
    csv_results <- read_delim(
      csv_input,
      delim = ";", 
      escape_double = FALSE, 
      trim_ws = TRUE
    )
    
    csv_results_filtered <- csv_results %>%
      select(
        name, group, type, full_name, time, 
        status, optimal, tle_feas, tle_not_feas, 
        gen_config_filename, gap, obj_value, bestbound,
        numnodes, constraints_used_melo_mip_str
      )
    
    csv_output <- paste0(
      "../",
      benchmarks[i],
      "/",
      prefix_set,
      "/",
      vi_test[j],
      "/",
      exp_set[i],
      "/",
      prefix_csv_output,
      ".csv"
    )
    
    write.table(
      csv_results_filtered,
      csv_output,
      sep = ";",
      dec = ".",
      quote = F,
      row.names = F
    )
  }
}