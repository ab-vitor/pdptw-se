library(dplyr)
library(knitr)

solvers <- c("gurobi", "hexaly")
solvers_suff <- c("", "_hx")
benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_csv_output <- "grouped"
exp_set <- c("set_02", "set_02")

OPTIMAL <- 2
OPT_HX <- "HxSolutionStatus.OPTIMAL"
TIME_LIMIT <- 9
FEAS_HX <- "HxSolutionStatus.FEASIBLE"
INFEAS_HX <- "HxSolutionStatus.INFEASIBLE"
KILLED <- 11
KILLED_HX <- "KILLED"

for (i in seq_along(solvers)){
  prefix_set <- paste0("official_experiments/mip_", solvers[i])
  prefix_csv_input <- paste0("csvresults_form_melo", solvers_suff[i])
  for (j in seq_along(benchmarks)) {
    for (t in 1:2) {
      suff_output <- paste0("abs_type_", t)
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
      
      
      write.table(
        grouped_abs,
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
      
      tex_grouped_abs <-
        kable(grouped_abs, format = "latex", booktabs = TRUE)
      
      writeLines(
        tex_grouped_abs,
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
          ".tex"
        )
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
      
      write.table(
        grouped_by_n_req_abs,
        paste0(
          "../",
          benchmarks[j],
          "/",
          prefix_set,
          "/",
          exp_set[j],
          "/",
          prefix_csv_output,
          "_by_n_req_",
          suff_output,
          ".csv"
        ),
        sep = ";",
        dec = ".",
        quote = F,
        row.names = F
      )
      
      tex_grouped_by_n_req_abs <-
        kable(grouped_by_n_req_abs,
              format = "latex",
              booktabs = TRUE)
      
      writeLines(
        tex_grouped_by_n_req_abs,
        paste0(
          "../",
          benchmarks[j],
          "/",
          prefix_set,
          "/",
          exp_set[j],
          "/",
          prefix_csv_output,
          "_by_n_req_",
          suff_output,
          ".tex"
        )
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
      
      write.table(
        grouped_by_req_reg_abs,
        paste0(
          "../",
          benchmarks[j],
          "/",
          prefix_set,
          "/",
          exp_set[j],
          "/",
          prefix_csv_output,
          "_by_req_reg_",
          suff_output,
          ".csv"
        ),
        sep = ";",
        dec = ".",
        quote = F,
        row.names = F
      )
      
      tex_grouped_by_req_reg_abs <-
        kable(grouped_by_req_reg_abs,
              format = "latex",
              booktabs = TRUE)
      
      writeLines(
        tex_grouped_by_req_reg_abs,
        paste0(
          "../",
          benchmarks[j],
          "/",
          prefix_set,
          "/",
          exp_set[j],
          "/",
          prefix_csv_output,
          "_by_req_reg_",
          suff_output,
          ".tex"
        )
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
      
      write.table(
        grouped_by_req_mach_abs,
        paste0(
          "../",
          benchmarks[j],
          "/",
          prefix_set,
          "/",
          exp_set[j],
          "/",
          prefix_csv_output,
          "_by_req_mach_",
          suff_output,
          ".csv"
        ),
        sep = ";",
        dec = ".",
        quote = F,
        row.names = F
      )
      
      tex_grouped_by_req_mach_abs <-
        kable(grouped_by_req_mach_abs,
              format = "latex",
              booktabs = TRUE)
      
      writeLines(
        tex_grouped_by_req_mach_abs,
        paste0(
          "../",
          benchmarks[j],
          "/",
          prefix_set,
          "/",
          exp_set[j],
          "/",
          prefix_csv_output,
          "_by_req_mach_",
          suff_output,
          ".tex"
        )
      )
    }
  }
}
