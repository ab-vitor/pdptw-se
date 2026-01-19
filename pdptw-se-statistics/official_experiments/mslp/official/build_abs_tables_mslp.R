library(dplyr)
library(readr)
library(purrr)

variations <- c("multi_island", "multi_floor")
prefix_path_mslp <- "official_experiments/data/mslp_official"
ext_csv <- ".csv"
types <- c(1, 2)

prefix_input_csvr_mslp <- "csvresults_heur_mslp"
prefix_output <- "official_experiments/mslp/official/tables"

for (j in seq_along(variations)) {
  var <- variations[j]
  grouped_abs_tables_list <- list()
  for (t in types) {
    suff_type <- paste0("_type_", t, ".csv")
    
    mslp_input_name <- paste0(prefix_input_csvr_mslp, "_", var, ext_csv)
    mslp_input_path <- file.path(prefix_path_mslp, mslp_input_name)
    csvr_mslp_complete <-
      read.csv(
        file = mslp_input_path,
        sep = ";"
      )
    
    csvr_mslp <- csvr_mslp_complete %>%
      filter(n > 12, type == paste0("t", t)) %>%
      mutate(value = ifelse(is.infinite(value), NA, value))
    
    grouped_abs_group_instname_mslp <- csvr_mslp %>%
      group_by(full_name, group) %>%
      summarise(
        feas_exec = sum(feasible),
        exec = n(),
        .groups = "drop"
      ) %>%
      mutate(
        all_feas = ifelse(feas_exec == exec, 1, 0),
        not_all_feas = ifelse(feas_exec != exec, 1, 0),
        geq_one_not_all_feas = ifelse(feas_exec > 0 & feas_exec < exec, 1, 0)
      )
    
    grouped_abs_mslp <- grouped_abs_group_instname_mslp %>%
      group_by(group) %>%
      summarise(
        sum_all_feas = sum(all_feas),
        # sum_not_all_feas = sum(not_all_feas),
        sum_geq_one_not_all_feas = sum(geq_one_not_all_feas),
        mean_geq_one_not_all_feas = ifelse(sum(geq_one_not_all_feas)>0 , mean(feas_exec[geq_one_not_all_feas == 1], na.rm=T), NA),
        .groups = "drop"
      )
    
    grouped_abs_tables_list[[t]] <- grouped_abs_mslp
    output_file_name_mslp <- paste0("grouped_abs_mslp_", var, suff_type)
    output_file_path_mslp <- file.path(prefix_output, output_file_name_mslp)
    write_delim(
      grouped_abs_mslp,
      file = output_file_path_mslp,
      delim = ";",
    )
  }
  
  grouped_abs_tables_list_renamed <- imap(grouped_abs_tables_list, function(tbl, idx) {
    cols <- setdiff(names(tbl), "group")
    tbl <- rename_with(tbl, ~ paste0(.x, "_t", idx), all_of(cols))
    tbl
  })
  merged_abs_table <- reduce(grouped_abs_tables_list_renamed, full_join, by = "group")
  output_file_name_merged_mslp <- paste("grouped_abs_mslp", var, "merged.csv", sep="_")
  output_file_path_merged_mslp <- file.path(prefix_output, output_file_name_merged_mslp)
  write_delim(
    merged_abs_table,
    file = output_file_path_merged_mslp,
    delim = ";"
  )
}
