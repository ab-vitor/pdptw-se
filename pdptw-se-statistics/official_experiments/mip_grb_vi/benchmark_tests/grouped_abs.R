library(dplyr)
library(knitr)
library(glue)

benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_csv_output <- "grouped"
exp_set <- c("set_01", "set_01")
prefix_set <- "official_experiments/mip_grb_valid_inequalities/official"
prefix_csv_input <- "csvresults_form_melo"

OPTIMAL <- 2
TIME_LIMIT <- 9
KILLED <- 11

# ---- Helper functions ----

process_results <- function(csv_results_df) {
  csv_results_df %>%
    mutate(
      found_sol = pmax(optimal, tle_feas),
      n_req = as.integer(substr(group, 1, 2)),
      feas_sol = found_sol == 1,
      tle = pmax(tle_feas, tle_not_feas),
      killed = if_else(status == KILLED, 1, 0)
    ) %>%
    select(name, group, optimal, n_req, status, tle, tle_feas, tle_not_feas, killed, feas_sol, n_vehicles_used, status, obj_value)
}

write_outputs <- function(df, suffix, prefix_csv_output, benchmarks, prefix_set, exp_set, j) {
  csv_path <- file.path("..", benchmarks[j], prefix_set, exp_set[j],
                        glue("{prefix_csv_output}_{suffix}.csv"))
  tex_path <- file.path("..", benchmarks[j], prefix_set, exp_set[j],
                        glue("{prefix_csv_output}_{suffix}.tex"))
  
  write.table(df, file = csv_path, sep = ";", dec = ".", quote = FALSE, row.names = FALSE)
  tex_table <- kable(df, format = "latex", booktabs = TRUE)
  writeLines(tex_table, tex_path)
}

summarize_by <- function(df, group_var) {
  df %>%
    group_by({{ group_var }}) %>%
    summarise(
      Optimal = sum(optimal, na.rm = TRUE),
      TLE = sum(tle, na.rm = TRUE),
      Killed = sum(killed),
      "Feas. Sol." = sum(feas_sol, na.rm = TRUE),
      .groups = "drop"
    )
}

# ---- Main loop ----

for (j in seq_along(benchmarks)) {
  for (t in 1:2) {
    
    suff_output <- glue("abs_type_{t}")
    file_name <- glue("{prefix_csv_input}_type_{t}.csv")
    input_path <- file.path("..", benchmarks[j], prefix_set, exp_set[j], file_name)
    
    csv_results_df <- read.csv(file = input_path, sep = ";") |> process_results()
    
    # ---- 1. Group by group ----
    grouped_abs <- summarize_by(csv_results_df, group)
    write_outputs(grouped_abs, suff_output, prefix_csv_output, benchmarks, prefix_set, exp_set, j)
    
    # ---- 2. Group by n_req ----
    grouped_by_n_req_abs <- summarize_by(csv_results_df, n_req)
    write_outputs(grouped_by_n_req_abs, glue("by_n_req_{suff_output}"),
                  prefix_csv_output, benchmarks, prefix_set, exp_set, j)
    
    # ---- 3. Group by req_reg ----
    csv_results_df <- csv_results_df %>% mutate(req_reg = substr(group, 1, 11))
    grouped_by_req_reg_abs <- summarize_by(csv_results_df, req_reg)
    write_outputs(grouped_by_req_reg_abs, glue("by_req_reg_{suff_output}"),
                  prefix_csv_output, benchmarks, prefix_set, exp_set, j)
    
    # ---- 4. Group by req_mach ----
    csv_results_df <- csv_results_df %>%
      mutate(req_mach = paste(substr(group, 1, 7), substr(group, 13, 15), sep = "_"))
    grouped_by_req_mach_abs <- summarize_by(csv_results_df, req_mach)
    write_outputs(grouped_by_req_mach_abs, glue("by_req_mach_{suff_output}"),
                  prefix_csv_output, benchmarks, prefix_set, exp_set, j)
  }
}
