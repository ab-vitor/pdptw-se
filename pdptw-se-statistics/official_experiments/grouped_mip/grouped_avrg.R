library(dplyr)

solvers <- c("gurobi", "hexaly")
solvers_suff <- c("", "_hx")
variations <- c("multi_island", "multi_floor")
prefix_csv_output <- "grouped"
types <- c(1, 2)

for (i in seq_along(solvers)){
  prefix_set <- paste0("official_experiments/data/mip_", solvers[i])
  prefix_csv_input <- paste0("csvresults_form_mip", solvers_suff[i])
  for (j in seq_along(variations)) {
    for (t in types) {
      suff_output <- paste0("avrg_type_", t)
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
      
      grouped_avrg_file_name <- paste0(
        prefix_csv_output,
        "_",
        suff_output,
        "_",
        variations[j],
        ".csv"
      )
      grouped_avrg_file_path <- file.path(
        prefix_set,
        "grouped_avrg",
        grouped_avrg_file_name
      )
      dir.create(dirname(grouped_avrg_file_path), showWarnings = FALSE, recursive = TRUE)

      write.table(
        grouped_avrg,
        grouped_avrg_file_path,
        sep = ";",
        dec = ".",
        quote = F,
        row.names = F
      )
    }
  }
}