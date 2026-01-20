library(dplyr)
library(knitr)
library(readr)

solvers <- c("gurobi", "hexaly")
solvers_suff <- c("", "_hx")
variations <- c("multi_island", "multi_floor")
prefix_csv_output <- "grouped"
types <- c(1, 2)

OPTIMAL <- 2
OPT_HX <- "HxSolutionStatus.OPTIMAL"
TIME_LIMIT <- 9
FEAS_HX <- "HxSolutionStatus.FEASIBLE"
INFEAS_HX <- "HxSolutionStatus.INFEASIBLE"
KILLED <- 11
KILLED_HX <- "KILLED"

for (i in seq_along(solvers)){
  prefix_set <- paste0("official_experiments/data/mip_", solvers[i])
  prefix_csv_input <- paste0("csvresults_form_mip", solvers_suff[i])
  for (j in seq_along(variations)) {
    for (t in types) {
      suff_output <- paste0("abs_type_", t)
      csvr_df_file_name <- paste0(prefix_csv_input, "_", variations[j], ".csv")
      csvr_file_path <- file.path(prefix_set, csvr_df_file_name)
      csv_results_df <- read_delim(
        file = csvr_file_path,
        delim = ";"
      )

      csv_results_df <- csv_results_df %>%
        filter(type == paste0("t", t))

      csv_results_df <- csv_results_df %>%
        rename_with(~ sub("(_grb|_hx)+$", "", .x))
      
      csv_results_df <- csv_results_df %>%
        mutate(
          n_req = as.integer(substr(group, 1, 2)),
          feas_sol = n_vehicles_used != 0 & !is.na(n_vehicles_used) | status == OPT_HX | status == FEAS_HX,
          tle = status == TIME_LIMIT | status == FEAS_HX | status == INFEAS_HX,
          killed = status == KILLED | status == KILLED_HX,
          optimal = status == OPTIMAL | status == OPT_HX
        ) %>%
        select(name, group, optimal, tle, killed, feas_sol, n_vehicles_used, status, obj_value)

      grouped_abs <- csv_results_df %>%
        group_by(group) %>%
        summarise(
          Optimal = sum(optimal, na.rm = TRUE),
          TLE = sum(tle, na.rm = TRUE),
          Killed = sum(killed),
          "Feas. Sol." = sum(feas_sol),
        )
      
      grouped_abs_file_name <- paste0(
        prefix_csv_output,
        "_",
        suff_output,
        "_",
        variations[j],
        ".csv"
      )
      grouped_abs_file_path <- file.path(
        prefix_set,
        "grouped_abs",
        grouped_abs_file_name
      )
      dir.create(dirname(grouped_abs_file_path), showWarnings = FALSE, recursive = TRUE)

      
      write.table(
        grouped_abs,
        grouped_abs_file_path,
        sep = ";",
        dec = ".",
        quote = F,
        row.names = F
      )
      
      tex_grouped_abs <-
        kable(grouped_abs, format = "latex", booktabs = TRUE)

      tex_grouped_abs_file_name <- paste0(
        prefix_csv_output,
        "_",
        suff_output,
        "_",
        variations[j],
        ".tex"
      )
      tex_grouped_abs_file_path <- file.path(
        prefix_set,
        "grouped_abs",
        tex_grouped_abs_file_name
      )
      dir.create(dirname(tex_grouped_abs_file_path), showWarnings = FALSE, recursive = TRUE)
      
      writeLines(
        tex_grouped_abs,
        tex_grouped_abs_file_path
      )
      
      ##############################################
      
      grouped_by_n_req_abs <- csv_results_df %>%
        mutate(
          n_req = as.integer(substr(group, 1, 2)),
          feas_sol = n_vehicles_used != 0 & !is.na(n_vehicles_used) | status == OPT_HX | status == FEAS_HX,
          tle = status == TIME_LIMIT | status == FEAS_HX | status == INFEAS_HX,
          killed = status == KILLED | status == KILLED_HX,
          optimal = status == OPTIMAL | status == OPT_HX
        ) %>%
        group_by(n_req) %>%
        summarise(
          Optimal = sum(optimal, na.rm = TRUE),
          TLE = sum(tle, na.rm = TRUE),
          Killed = sum(killed),
          "Feas. Sol." = sum(feas_sol),
        )

      grouped_by_n_req_abs_file_name <- paste0(
        prefix_csv_output,
        "_by_n_req_",
        suff_output,
        "_",
        variations[j],
        ".csv"
      )
      grouped_by_n_req_abs_file_path <- file.path(
        prefix_set,
        "grouped_abs",
        grouped_by_n_req_abs_file_name
      )

      dir.create(dirname(grouped_by_n_req_abs_file_path), showWarnings = FALSE, recursive = TRUE)
      
      write.table(
        grouped_by_n_req_abs,
        grouped_by_n_req_abs_file_path,
        sep = ";",
        dec = ".",
        quote = F,
        row.names = F
      )
      
      tex_grouped_by_n_req_abs <-
        kable(grouped_by_n_req_abs,
              format = "latex",
              booktabs = TRUE)

      tex_grouped_by_n_req_abs_file_name <- paste0(
        prefix_csv_output,
        "_by_n_req_",
        suff_output,
        "_",
        variations[j],
        ".tex"
      )
      tex_grouped_by_n_req_abs_file_path <- file.path(
        prefix_set,
        "grouped_abs",
        tex_grouped_by_n_req_abs_file_name
      )
      dir.create(dirname(tex_grouped_by_n_req_abs_file_path), showWarnings = FALSE, recursive = TRUE)

      writeLines(
        tex_grouped_by_n_req_abs,
        tex_grouped_by_n_req_abs_file_path
      )
      
      ##############################################
      
      grouped_by_req_reg_abs <- csv_results_df %>%
        mutate(
          req_reg = substr(group, 1, 11),
          feas_sol = n_vehicles_used != 0 & !is.na(n_vehicles_used) | status == OPT_HX | status == FEAS_HX,
          tle = status == TIME_LIMIT | status == FEAS_HX | status == INFEAS_HX,
          killed = status == KILLED | status == KILLED_HX,
          optimal = status == OPTIMAL | status == OPT_HX
        ) %>%
        group_by(req_reg) %>%
        summarise(
          Optimal = sum(optimal, na.rm = TRUE),
          TLE = sum(tle, na.rm = TRUE),
          Killed = sum(killed),
          "Feas. Sol." = sum(feas_sol, na.rm = TRUE),
        )

      grouped_by_req_reg_abs_file_name <- paste0(
        prefix_csv_output,
        "_by_req_reg_",
        suff_output,
        "_",
        variations[j],
        ".csv"
      )
      grouped_by_req_reg_abs_file_path <- file.path(
        prefix_set,
        "grouped_abs",
        grouped_by_req_reg_abs_file_name
      )
      dir.create(dirname(grouped_by_req_reg_abs_file_path), showWarnings = FALSE, recursive = TRUE)

      write.table(
        grouped_by_req_reg_abs,
        grouped_by_req_reg_abs_file_path,
        sep = ";",
        dec = ".",
        quote = F,
        row.names = F
      )
      
      tex_grouped_by_req_reg_abs <-
        kable(grouped_by_req_reg_abs,
              format = "latex",
              booktabs = TRUE)

      tex_grouped_by_req_reg_abs_file_name <- paste0(
        prefix_csv_output,
        "_by_req_reg_",
        suff_output,
        "_",
        variations[j],
        ".tex"
      )
      tex_grouped_by_req_reg_abs_file_path <- file.path(
        prefix_set,
        "grouped_abs",
        tex_grouped_by_req_reg_abs_file_name
      )
      dir.create(dirname(tex_grouped_by_req_reg_abs_file_path), showWarnings = FALSE, recursive = TRUE)

      writeLines(
        tex_grouped_by_req_reg_abs,
        tex_grouped_by_req_reg_abs_file_path
      )
      
      ##############################################
      
      grouped_by_req_mach_abs <- csv_results_df %>%
        mutate(
          req_mach = paste(substr(group, 1, 7), substr(group, 13, 15), sep = "_"),
          feas_sol = n_vehicles_used != 0 & !is.na(n_vehicles_used) | status == OPT_HX | status == FEAS_HX,
          tle = status == TIME_LIMIT | status == FEAS_HX | status == INFEAS_HX,
          killed = status == KILLED | status == KILLED_HX,
          optimal = status == OPTIMAL | status == OPT_HX
        ) %>%
        group_by(req_mach) %>%
        summarise(
          n_insts = n(),
          type = t,
          optimal = sum(optimal, na.rm = TRUE),
          tle = sum(tle, na.rm = TRUE),
          killed = sum(killed),
          feas_sol = sum(feas_sol),
        )

      grouped_by_req_mach_abs_file_name <- paste0(
        prefix_csv_output,
        "_by_req_mach_",
        suff_output,
        "_",
        variations[j],
        ".csv"
      )
      grouped_by_req_mach_abs_file_path <- file.path(
        prefix_set,
        "grouped_abs",
        grouped_by_req_mach_abs_file_name
      )
      dir.create(dirname(grouped_by_req_mach_abs_file_path), showWarnings = FALSE, recursive = TRUE)

      write.table(
        grouped_by_req_mach_abs,
        grouped_by_req_mach_abs_file_path,
        sep = ";",
        dec = ".",
        quote = F,
        row.names = F
      )
      
      tex_grouped_by_req_mach_abs <-
        kable(grouped_by_req_mach_abs,
              format = "latex",
              booktabs = TRUE)

      tex_grouped_by_req_mach_abs_file_name <- paste0(
        prefix_csv_output,
        "_by_req_mach_",
        suff_output,
        "_",
        variations[j],
        ".tex"
      )
      tex_grouped_by_req_mach_abs_file_path <- file.path(
        prefix_set,
        "grouped_abs",
        tex_grouped_by_req_mach_abs_file_name
      )
      dir.create(dirname(tex_grouped_by_req_mach_abs_file_path), showWarnings = FALSE, recursive = TRUE)

      writeLines(
        tex_grouped_by_req_mach_abs,
        tex_grouped_by_req_mach_abs_file_path
      )
    }
  }
}
