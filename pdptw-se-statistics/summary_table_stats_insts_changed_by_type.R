library(dplyr)
library(readr)

inst_set <- c("I5", "F3")
inst_set_desc <- c("Multi-island", "Multi-floor")
folder_inst_set <- c("multi_island_v5/", "multi_floor_v3/")
profiles <- c("small", "big")
suff_prof <- c("", "_big")


merged_data <- list()
# --- Main loop ---
for (i in seq_along(inst_set)) {
  inst <- inst_set[i]
  df <- read.csv(
    file = paste0("./inst_statistics/", folder_inst_set[i], "tw_cap_change_", inst, ".csv"),
    sep = ";"
  )
  df <- df %>%
    mutate(
      reqs = as.numeric(substr(group, 1, 2)),
      type = substr(instname, 3, 3),
      tw_shift = as.numeric(tw_shift),
      cap_incr = as.numeric(cap_incr),
      modified = pmax(tw_shift, cap_incr),
      inst_size = if_else(reqs <= 12, "small", "big")
    ) %>%
    select(group, reqs, instname, type, tw_shift, cap_incr, modified, inst_size)
  
  df_summary <- df %>%
    group_by(inst_size, type) %>%
    summarise(
      modified = sum(modified)/n()*100,
      tw_shift = sum(tw_shift)/n()*100,
      cap_incr = sum(cap_incr)/n()*100,
      .groups = "drop"
    )
  
  merged_data[[inst]] <- df_summary
}

merged_df_side <- cbind(
  merged_data[["I5"]] %>% rename_with(~ paste0(.x, "_I5")),
  merged_data[["F3"]] %>% rename_with(~ paste0(.x, "_F3"))
)

write_delim(
  merged_df_side,
  file = file.path("inst_statistics", "tables", "summary_table.csv"),
  delim = ";"
)