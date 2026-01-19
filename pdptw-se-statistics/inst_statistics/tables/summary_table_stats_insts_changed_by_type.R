library(dplyr)
library(readr)
library(tibble)

variations <- c("multi_island", "multi_floor")
variations_desc <- c("Multi-island", "Multi-floor")
folder_variations <- c("multi_island/", "multi_floor/")
profiles <- c("small", "big")
suff_prof <- c("", "_big")


merged_data <- list()
# --- Main loop ---
for (i in seq_along(variations)) {
  var <- variations[i]
  df <- read.csv(
    file = paste0("./inst_statistics/", folder_variations[i], "tw_cap_change_", var, ".csv"),
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
  
  merged_data[[var]] <- df_summary
}

merged_df_side <- cbind(
  merged_data[[variations[1]]] %>% rename_with(~ paste0(.x, "_", variations[1])),
  merged_data[[variations[2]]] %>% rename_with(~ paste0(.x, "_", variations[2]))
)

write_delim(
  merged_df_side,
  file = file.path("inst_statistics", "tables", "summary_table.csv"),
  delim = ";"
)