library(dplyr)
library(xtable)
library(readr)

# Parameters
variations <- c("multi_island", "multi_floor")
prefix_set <- "official_experiments/data/mslp_preliminary"
prefix_input <- "grouped_avrg_alpha"

prefix_output <- "official_experiments/mslp"
output_dir <- "alpha_comparison"
mean_cols <- c("mean_minrpd", "mean_meanrpd", "mean_maxrpd")
sd_cols   <- c("sd_minrpd", "sd_meanrpd", "sd_maxrpd")
mean_cols_b <- c("mean_minrpd_T1", "mean_meanrpd_T1", "mean_maxrpd_T1", "mean_minrpd_T2", "mean_meanrpd_T2", "mean_maxrpd_T2")
sd_cols_b   <- c("sd_minrpd_T1", "sd_meanrpd_T1", "sd_maxrpd_T1", "sd_minrpd_T2", "sd_meanrpd_T2", "sd_maxrpd_T2")
types <- c(1, 2)

for (j in seq_along(variations)) {
  merged_data <- list()  # store both types
  
  for(t in types){
    # --- Input ---
    suff_path <- paste0("_type_", t, "_", variations[j], ".csv")
    filename <- paste0(prefix_input, suff_path)
    input_path <- file.path(prefix_set, "grouped", filename)
    grouped_avrg_alpha <- read.csv(input_path, sep = ";")
    
    # round numeric columns
    grouped_avrg_alpha <- grouped_avrg_alpha %>%
      mutate(across(where(is.numeric), ~ round(.x, 2)))
    
    # save for merging
    merged_data[[t]] <- grouped_avrg_alpha
    
    # Combine mean ± sd
    for(i in seq_along(mean_cols)){
      grouped_avrg_alpha[[mean_cols[i]]] <- paste0(
        grouped_avrg_alpha[[mean_cols[i]]], " $\\pm$ ", grouped_avrg_alpha[[sd_cols[i]]]
      )
    }
    
    # Remove original sd columns
    grouped_avrg_alpha <- grouped_avrg_alpha %>% select(-all_of(sd_cols))
    
    # Save individual type table
    digits_vec <- rep(2, ncol(grouped_avrg_alpha)+1)
    latex_table <- xtable(grouped_avrg_alpha, caption = paste("Alpha comparison - Type", t), digits = digits_vec)
    
    output_file <- paste0("grouped_avrg_alpha_type_", t, "_", variations[j], ".tex")
    output_path <- file.path(prefix_output, "preliminary", output_dir, output_file)
    # sink(output_path)
    # print(latex_table, include.rownames = FALSE, sanitize.text.function = identity) # comment to save latex table for each type
    # sink()
  }
  
  # --- Merge types side by side ---
  merged_df_side <- cbind(
    merged_data[[1]] %>% rename_with(~ paste0(.x, "_T1")),
    merged_data[[2]] %>% rename_with(~ paste0(.x, "_T2"))
  )
  
  # Combine mean ± sd
  for(i in seq_along(mean_cols_b)){
    merged_df_side[[mean_cols_b[i]]] <- paste0(
      merged_df_side[[mean_cols_b[i]]], " $\\pm$ ", merged_df_side[[sd_cols_b[i]]]
    )
  }
  
  merged_df_side <- merged_df_side %>% select(-all_of(sd_cols_b))
  
  # Build LaTeX table
  digits_vec_merged <- rep(2, ncol(merged_df_side)+1)  # all numeric columns rounded already
  latex_table_merged <- xtable(
    merged_df_side,
    caption = paste("Side-by-side Alpha comparison for", variations[j]),
    digits = digits_vec_merged
  )
  
  # Prepare multi-row header
  n_col_type1 <- ncol(merged_data[[1]])
  n_col_type2 <- ncol(merged_data[[2]])
  
  add_header <- list()
  add_header$pos <- list(-1)  # add before first row
  add_header$command <- paste0(
    "\\multicolumn{", n_col_type1, "}{c}{Type 1} & ",
    "\\multicolumn{", n_col_type2, "}{c}{Type 2} \\\\ \n"
  )
  
  # Save merged table with multi-header
  output_file_merged <- paste0("grouped_avrg_alpha_merged_", variations[j], ".tex")
  output_path_merged <- file.path(prefix_output, "preliminary", output_dir, output_file_merged)
  dir.create(dirname(output_path_merged), showWarnings = FALSE, recursive = TRUE)
  sink(output_path_merged)
  print(
    latex_table_merged,
    include.rownames = FALSE,
    add.to.row = add_header,
    sanitize.text.function = identity,
    hline.after = c(-1, 0, nrow(merged_df_side))
  )
  sink()
  
  
}
