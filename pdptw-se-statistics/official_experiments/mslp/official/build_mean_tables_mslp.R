library(dplyr)
library(readr)
library(purrr)
library(tibble)

variations <- c("multi_island", "multi_floor")
prefix_path_mslp <- "official_experiments/data/mslp_official"
types <- c(1, 2)

prefix_input_csvr_mslp <- "csvresults_heur_mslp"
prefix_output <- "official_experiments/mslp/official/tables"
ext_csv <- ".csv"

for (j in seq_along(variations)) {
  var <- variations[j]
  grouped_mean_tables_list <- list()
  for (t in types) {
    suff_type = paste0("_type_", t)
    mslp_input_name <- paste0(prefix_input_csvr_mslp, "_", var, ext_csv)
    mslp_input_path <- file.path(prefix_path_mslp,mslp_input_name)
    csvr_mslp_complete <-
      read.csv(
        file = mslp_input_path,
        sep = ";"
      )
    csvr_mslp_complete <- csvr_mslp_complete %>%
      filter(type == paste0("t", t))
    
    csvr_mslp <- csvr_mslp_complete %>%
      filter(n > 12) %>%
      mutate(value = ifelse(is.infinite(value), NA, value))
  
    grouped_avrg_group_instname_mslp <- csvr_mslp %>%
      group_by(full_name, group) %>%
      summarise(
        minbestsol = ifelse(all(!is.na(value)), min(value, na.rm = T), NA),
        meanbestsol = ifelse(all(!is.na(value)), mean(value, na.rm = T), NA),
        meancputimetobest = ifelse(all(!is.na(time_to_best)), mean(time_to_best, na.rm = T), NA),
        meancputime = ifelse(all(!is.na(total_time_elapsed)), mean(total_time_elapsed, na.rm = T), NA),
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
    output_file_name_mslp <- paste0("grouped_mean_mslp_", var, suff_type, ext_csv)
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
