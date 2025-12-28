library(readr)
library(dplyr)

benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_set <- "official_experiments/mip_grb_valid_inequalities"
prefix_csv_input <- "csvresults_form_melo_simplified"
prefix_csv_output <- "csvresults_form_melo"
exp_set <- c("set_03", "set_03")
vi_test <- c("all_minus_one_vi", "all_vi", "no_vi", "one_vi")
path_to_csv_output <- "official_experiments/mip_grb_vi/tables_per_instance/"

for(i in seq_along(benchmarks)){
  csv_input_vi_test_1 <- paste0(
    "../",
    benchmarks[i],
    "/",
    prefix_set,
    "/",
    vi_test[1],
    "/",
    exp_set[i],
    "/",
    prefix_csv_input,
    ".csv"
  )
  csv_results_vi_test_1 <- read_delim(
    csv_input_vi_test_1,
    delim = ";", 
    escape_double = FALSE, 
    trim_ws = TRUE
  )
  
  csv_input_vi_test_2 <- paste0(
    "../",
    benchmarks[i],
    "/",
    prefix_set,
    "/",
    vi_test[2],
    "/",
    exp_set[i],
    "/",
    prefix_csv_input,
    ".csv"
  )
  csv_results_vi_test_2 <- read_delim(
    csv_input_vi_test_2,
    delim = ";", 
    escape_double = FALSE, 
    trim_ws = TRUE
  )
  
  csv_input_vi_test_3 <- paste0(
    "../",
    benchmarks[i],
    "/",
    prefix_set,
    "/",
    vi_test[3],
    "/",
    exp_set[i],
    "/",
    prefix_csv_input,
    ".csv"
  )
  csv_results_vi_test_3 <- read_delim(
    csv_input_vi_test_3,
    delim = ";", 
    escape_double = FALSE, 
    trim_ws = TRUE
  )
  
  csv_input_vi_test_4 <- paste0(
    "../",
    benchmarks[i],
    "/",
    prefix_set,
    "/",
    vi_test[4],
    "/",
    exp_set[i],
    "/",
    prefix_csv_input,
    ".csv"
  )
  csv_results_vi_test_4 <- read_delim(
    csv_input_vi_test_4,
    delim = ";", 
    escape_double = FALSE, 
    trim_ws = TRUE
  )
  
  csv_results_vi_test <- rbind(
    csv_results_vi_test_1, csv_results_vi_test_2, 
    csv_results_vi_test_3, csv_results_vi_test_4
  )
  
  csv_results_vi_test <- csv_results_vi_test %>%
    select(-gen_config_filename)
  
  dir.create(path_to_csv_output, showWarnings = FALSE)

  unique_full_names <- unique(csv_results_vi_test$full_name)

  for (full_name in unique_full_names) {
    table_per_instance <- csv_results_vi_test %>% filter(full_name == !!full_name)
    output_file <- file.path(
      path_to_csv_output,
      paste0(variations[i], "_", gsub("[^A-Za-z0-9_]", "_", full_name), ".csv")
    )
    write_delim(table_per_instance, output_file, delim = ";")
  }
}