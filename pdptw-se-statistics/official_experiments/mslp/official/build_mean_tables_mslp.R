library(dplyr)
library(readr)
library(purrr)

benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_path_mslp <- "official_experiments/multistartlp/official"
sets <- c("set_01", "set_01")

prefix_input_csvr_mslp <- "csvresults_heur_mslp"
prefix_output <- "official_experiments/mslp/official/tables"

for (j in 1:2) {
  var <- variations[j]
  grouped_mean_tables_list <- list()
  for (t in 1:2) {
    suff_type <- paste0("type_", t, ".csv")
    
    mslp_input_name <- paste(prefix_input_csvr_mslp, suff_type, sep="_")
    mslp_input_path <- file.path(
      "..",
      benchmarks[j],
      prefix_path_mslp,
      sets[j],
      mslp_input_name
    )
    csvr_mslp_complete <-
      read.csv(
        file = mslp_input_path,
        sep = ";"
      )
    
    csvr_mslp <- csvr_mslp_complete %>%
      select(
        fullname, group, value, iteration, 
        iterationToBest, timeToBest, 
        totalTimeElapsed, seed, n, feasible
      ) %>%
      rename(full_name = fullname) %>%
      filter(n > 12) %>%
      mutate(
        feasible = ifelse(feasible == "true", T, F),
        value = ifelse(is.infinite(value), NA, value)
      )
    
    grouped_avrg_group_instname_mslp <- csvr_mslp %>%
      group_by(full_name, group) %>%
      summarise(
        minbestsol = ifelse(all(!is.na(value)), min(value, na.rm = T), NA),
        meanbestsol = ifelse(all(!is.na(value)), mean(value, na.rm = T), NA),
        meancputimetobest = ifelse(all(!is.na(timeToBest)), mean(timeToBest, na.rm = T), NA),
        meancputime = ifelse(all(!is.na(totalTimeElapsed)), mean(totalTimeElapsed, na.rm = T), NA),
        .groups = "drop"
      )
    

    grouped_mean_mslp <- grouped_avrg_group_instname_mslp %>%
      group_by(group) %>%
      summarise(
        "min. sol." = mean(minbestsol, na.rm = T),
        "mean sol." = mean(meanbestsol, na.rm = T),
        "time (s)" = mean(meancputime, na.rm = T),
        "ttb (s)" = mean(meancputimetobest, na.rm = T)
      )
    
    grouped_mean_tables_list[[t]] <- grouped_mean_mslp
    output_file_name_mslp <- paste("grouped_mean_mslp", var, suff_type, sep="_")
    output_file_path_mslp <- file.path(prefix_output, output_file_name_mslp)
    write_delim(
      grouped_mean_mslp,
      file = output_file_path_mslp,
      delim = ";",
    )
  }
  grouped_mean_tables_list_renamed <- imap(grouped_mean_tables_list, function(tbl, idx) {
    cols <- setdiff(names(tbl), "group")
    tbl <- rename_with(tbl, ~ paste0(.x, "_t", idx), all_of(cols))
    tbl
  })
  merged_mean_table <- reduce(grouped_mean_tables_list_renamed, full_join, by = "group")
  
  merged_mean_table <- merged_mean_table %>%
    add_column(space1 = "\\hspace{0.1cm}", .after = "group") %>%
    add_column(space2 = "\\hspace{0.2cm}", .after = "ttb (s)_t1")
    
  output_file_name_merged_mslp <- paste("grouped_mean_mslp", var, "merged.csv", sep="_")
  output_file_path_merged_mslp <- file.path(prefix_output, output_file_name_merged_mslp)
  write_delim(
    merged_mean_table,
    file = output_file_path_merged_mslp,
    delim = ";",
  )
}
