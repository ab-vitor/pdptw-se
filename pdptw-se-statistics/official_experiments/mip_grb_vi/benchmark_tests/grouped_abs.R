library(dplyr)
library(knitr)
library(glue)

# Refactored by chat-gpt

variations <- c("multi_island", "multi_floor")
prefix_csv_output <- "grouped"
prefix_set <- "official_experiments/data/mip_grb_valid_inequalities/official"
prefix_csv_input <- "csvresults_form_mip"
types <- c(1, 2)

OPTIMAL <- 2
TIME_LIMIT <- 9
KILLED <- 11

# ---- Helper functions ----

process_results <- function(csv_results_df, type) {
  csv_results_df <- csv_results_df %>%
    filter(type == paste0("t", t))
  
  csv_results_df <- csv_results_df %>%
    rename_with(~ sub("(_grb)+$", "", .x))
  
  csv_results_df %>%
    mutate(
      found_sol = pmax(optimal, tle_feas),
      n_req = as.integer(substr(group, 1, 2)),
      feas_sol = found_sol == 1,
      tle = pmax(tle_feas, tle_not_feas),
      killed = if_else(status == KILLED, 1, 0)
    ) %>%
    select(name, group, optimal, n_req, status, tle, tle_feas, tle_not_feas, killed, feas_sol, status)
}

write_outputs <- function(df, suffix, prefix_csv_output, prefix_set, var, j) {
  csv_path <- file.path(prefix_set, "grouped_abs", glue("{prefix_csv_output}_{suffix}_{var}.csv"))
  tex_path <- file.path(prefix_set, "grouped_abs", glue("{prefix_csv_output}_{suffix}_{var}.tex"))
  dir.create(dirname(csv_path), showWarnings = FALSE, recursive = TRUE)
  
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

for (j in seq_along(variations)) {
  for (t in types) {
    suff_output <- glue("abs_type_{t}")
    file_name <- glue("{prefix_csv_input}_{variations[j]}.csv")
    input_path <- file.path(prefix_set, file_name)
    
    csv_results_df <- read.csv(file = input_path, sep = ";") |> process_results(type = t)
    
    # ---- 1. Group by group ----
    grouped_abs <- summarize_by(csv_results_df, group)
    write_outputs(grouped_abs, suff_output, prefix_csv_output, prefix_set, variations[j], j)
    
    # ---- 2. Group by n_req ----
    grouped_by_n_req_abs <- summarize_by(csv_results_df, n_req)
    write_outputs(grouped_by_n_req_abs, glue("by_n_req_{suff_output}"),
                  prefix_csv_output, prefix_set, variations[j], j)
    
    # ---- 3. Group by req_reg ----
    csv_results_df <- csv_results_df %>% mutate(req_reg = substr(group, 1, 11))
    grouped_by_req_reg_abs <- summarize_by(csv_results_df, req_reg)
    write_outputs(grouped_by_req_reg_abs, glue("by_req_reg_{suff_output}"),
                  prefix_csv_output, prefix_set, variations[j], j)
    
    # ---- 4. Group by req_mach ----
    csv_results_df <- csv_results_df %>%
      mutate(req_mach = paste(substr(group, 1, 7), substr(group, 13, 15), sep = "_"))
    grouped_by_req_mach_abs <- summarize_by(csv_results_df, req_mach)
    write_outputs(grouped_by_req_mach_abs, glue("by_req_mach_{suff_output}"),
                  prefix_csv_output, prefix_set, variations[j], j)
  }
}
