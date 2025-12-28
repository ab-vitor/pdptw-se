library(dplyr)
library(readr)


######## DO NOT RUN TWICE #########
######## DO NOT RUN TWICE #########
######## DO NOT RUN TWICE #########
######## DO NOT RUN TWICE #########
######## DO NOT RUN TWICE #########
######## DO NOT RUN TWICE #########

benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_set <- "official_experiments/multistartlp/preliminar"
csv_input_filename <- "csvresults_heur_mslp.csv"
prefix_output <- "grouped_avrg_group_instname_alpha"
exp_set <- c("set_01", "set_01")

wrong_exp <- c(
  "lr109_t1_08R_08V_02I_04M", "lr209_t2_08R_08V_02I_04M", "lr110_t1_08R_08V_04I_04M",
  "lr209_t2_08R_08V_04I_04M", "lr109_t1_12R_12V_02I_04M", "lr208_t2_12R_12V_02I_04M",
  "lr110_t1_12R_12V_04I_04M", "lr207_t2_12R_12V_04I_04M", "LR1_2_6_t1_40R_40V_02I_06M",
  "LR2_2_10_t2_40R_40V_02I_06M", "LR1_2_10_t1_40R_40V_04I_06M", "LR2_2_7_t2_40R_40V_04I_06M",
  "LR1_2_6_t1_60R_60V_02I_06M", "LR2_2_8_t2_60R_60V_02I_06M", "LR1_2_6_t1_60R_60V_04I_06M",
  "LR2_2_8_t2_60R_60V_04I_06M", 
  "lr107_t1_08R_08V_02F_04M", "lr210_t2_08R_08V_02F_04M", "lr106_t1_08R_08V_04F_04M",
  "lr209_t2_08R_08V_04F_04M", "lr109_t1_12R_12V_02F_04M", "lr207_t2_12R_12V_02F_04M",
  "lr106_t1_12R_12V_04F_04M", "lr209_t2_12R_12V_04F_04M", "LR1_2_6_t1_40R_40V_02F_06M",
  "LR2_2_9_t2_40R_40V_02F_06M", "LR1_2_10_t1_40R_40V_04F_06M", "LR2_2_6_t2_40R_40V_04F_06M",
  "LR1_2_6_t1_60R_60V_02F_06M", "LR2_2_6_t2_60R_60V_02F_06M", "LR1_2_9_t1_60R_60V_04F_06M",
  "LR2_2_7_t2_60R_60V_04F_06M"
)

for (j in seq_along(benchmarks)) {
  csv_results_file <- file.path(
    "..",
    benchmarks[j],
    prefix_set,
    exp_set[j],
    csv_input_filename
  )
  csv_results <-
    read.csv(
      file = csv_results_file,
      sep = ";"
    )

  csv_results_mutated <- csv_results %>%
    mutate(
      fullname_seed_alpha = paste0(fullname, "_", seed, "_", alpha)
    ) 
  
  # csv_results_selected <- csv_results_mutated %>%
  #   select(fullname, seed, alpha, fullname_seed_alpha)
  
  csv_results_filtered <- csv_results_mutated %>%
    group_by(fullname_seed_alpha) %>%
    mutate(
      n_inst = n(),
      row_id = row_number(),
      is_last = row_id == max(row_id)
    ) %>%
    ungroup() %>%
    filter(
      !(fullname %in% wrong_exp) | n_inst == 2
    ) %>%
    filter(
      n_inst == 1 | is_last
    ) %>%
    select(-n_inst, -row_id, -is_last, -fullname_seed_alpha)
  
  write_delim(
    csv_results_filtered,
    file = csv_results_file,
    delim = ";"
  )
}