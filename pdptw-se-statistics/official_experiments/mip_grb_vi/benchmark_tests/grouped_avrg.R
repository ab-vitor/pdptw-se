library(dplyr)

variations <- c("multi_island", "multi_floor")
prefix_csv_output <- "grouped"
types <- c(1, 2)

prefix_set <- "official_experiments/data/mip_grb_valid_inequalities/official"
prefix_csv_input <- "csvresults_form_mip"
for (j in seq_along(variations)) {
  for (t in types) {
    suff_output <- paste0("avrg_type_", t)
    file_name <- paste0(prefix_csv_input, "_", variations[j], ".csv")
    file_path <- file.path(prefix_set, file_name)
    csv_results_df <- read.csv(
      file = file_path,
      sep = ";"
    )

    csv_results_df <- csv_results_df %>%
      filter(type == paste0("t", t))

    csv_results_df <- csv_results_df %>%
      rename_with(~ sub("(_grb)+$", "", .x))
    
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

    output_file <- paste0(prefix_csv_output, "_", suff_output, "_", variations[j], ".csv")
    output_path <- file.path(prefix_set, "grouped_avrg", output_file)
    dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
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