library(dplyr)

solvers <- c("gurobi", "hexaly")
solvers_suff <- c("", "_hx")
benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_csv_output <- "grouped"
exp_set <- c("set_02", "set_02")

for (i in seq_along(solvers)){
  prefix_set <- paste0("official_experiments/mip_", solvers[i])
  prefix_csv_input <- paste0("csvresults_form_melo", solvers_suff[i])
  for (j in seq_along(benchmarks)) {
    for (t in 1:2) {
      suff_output <- paste0("avrg_type_", t)
      csv_results_df <-
        read.csv(
          file = paste0(
            "../",
            benchmarks[j],
            "/",
            prefix_set,
            "/",
            exp_set[j],
            "/",
            prefix_csv_input,
            "_type_",
            t,
            ".csv"
          ),
          sep = ";"
        )

      csv_results_df <- csv_results_df %>%
        rename(obj_value = any_of("objValue"))
      
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
      
      write.table(
        grouped_avrg,
        paste0(
          "../",
          benchmarks[j],
          "/",
          prefix_set,
          "/",
          exp_set[j],
          "/",
          prefix_csv_output,
          "_",
          suff_output,
          ".csv"
        ),
        sep = ";",
        dec = ".",
        quote = F,
        row.names = F
      )
    }
  }
}