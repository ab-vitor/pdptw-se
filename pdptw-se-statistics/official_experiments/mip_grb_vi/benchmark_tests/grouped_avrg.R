library(dplyr)

benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_csv_output <- "grouped"
exp_set <- c("set_01", "set_01")

prefix_set <- "official_experiments/mip_grb_valid_inequalities/official"
prefix_csv_input <- "csvresults_form_melo"
for (j in seq_along(benchmarks)) {
  for (t in 1:2) {
    suff_output <- paste0("avrg_type_", t)
    file_name <- paste0(prefix_csv_input, "_type_", t, ".csv")
    file_path <- file.path("..", benchmarks[j], prefix_set, exp_set[j], file_name)
    csv_results_df <-
      read.csv(
        file = file_path,
        sep = ";"
      )
    
    csv_results_df <- csv_results_df %>%
      mutate(
        found_sol = pmax(optimal, tle_feas)
      )
    
    grouped_avrg <- csv_results_df %>%
      group_by(group) %>%
      summarise(
        "Sol." = mean(obj_value[found_sol == 1], na.rm = T),
        "Gap" = mean(gap[found_sol == 1], na.rm = T),
        "Time (s)" = mean(time[found_sol == 1], na.rm = T),
      )
    
    output_file <- paste0(prefix_csv_output, "_", suff_output, ".csv")
    output_path <- file.path("..", benchmarks[j], prefix_set, exp_set[j], output_file)
    write.table(
      grouped_avrg,
      file = output_path,
      sep = ";",
      dec = ".",
      quote = F,
      row.names = F
    )
  }
}