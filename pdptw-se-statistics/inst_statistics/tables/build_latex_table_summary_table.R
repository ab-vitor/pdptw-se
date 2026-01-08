library(dplyr)
library(readr)
library(tidyr)
library(knitr)
library(kableExtra)
library(glue)

df <- read_delim(
  "inst_statistics/tables/summary_table.csv", 
  delim = ";", escape_double = FALSE, trim_ws = TRUE
)

df_long <- df %>%
  pivot_longer(
    cols = everything(),
    names_to = c(".value", "scenario"),
    names_pattern = "(.*)_(multi_island|multi_floor)"
  ) %>%
  mutate(
    scenario = recode(scenario, multi_island="multi-island", multi_floor="multi-floor"),
    inst_size = tolower(inst_size),
    type = as.character(type),
    across(c(modified, tw_shift, cap_incr), as.numeric)
  ) %>%
  distinct(scenario, inst_size, type, .keep_all = TRUE)   # ensures unique rows

col_order <- list(
  c("small","multi-island","1"), c("small","multi-island","2"), 
  c("small","multi-floor","1"), c("small","multi-floor","2"),
  c("big","multi-island","1"),   c("big","multi-island","2"),   
  c("big","multi-floor","1"),   c("big","multi-floor","2")
)

get_val <- function(metric, size, scenario_val, type_val){
  val <- df_long %>%
    filter(inst_size == size,
           .data$scenario == scenario_val,
           type == type_val) %>%
    pull({{ metric }})
  val[1]  # if you still want just the first value
}



metrics <- c("modified","tw_shift","cap_incr")
rows <- lapply(metrics, function(m){
  vapply(col_order, function(x){
    sprintf("%.2f\\%%", get_val(m, x[1], x[2], x[3]))
  }, FUN.VALUE = character(1))
})
print(rows)
names(rows) <- metrics


# Save merged table with multi-header
output_path_merged <- "inst_statistics/tables/summary_table.tex"
sink(output_path_merged)
cat("\\begin{table}[!ht]\n",
    "    \\centering\n",
    "    \\caption{Overview of the instance changes}\n",
    "    \\label{tab:inst_change_overview}\n",
    "    \\scriptsize\n",
    "    \\begin{tabular}{lr rrrr r rrrr}\\toprule\n",
    "        \\multirow{3}{*}{} &\\multicolumn{4}{c}{6 to 12 requests} & &\\multicolumn{4}{c}{40 and 60 requests} \\\\\n",
    "        \\cmidrule{2-9}\n",
    "        &\\multicolumn{2}{c}{Multi-island} &\\multicolumn{2}{c}{Multi-floor} & &\\multicolumn{2}{c}{Multi-island} &\\multicolumn{2}{c}{Multi-floor} \\\\\n",
    "        \\cmidrule{2-9}\n",
    "        &Type 1 &Type 2 &Type 1 &Type 2 & &Type 1 &Type 2 &Type 1 &Type 2 \\\\\n",
    "        \\midrule\n",
    "        Instances modified (TW/Cap) &", paste(rows$modified, collapse = " & "), " \\\\\n",
    "        Instances with TW shift &", paste(rows$tw_shift, collapse = " & "), " \\\\\n",
    "        Instances with Cap increase &", paste(rows$cap_incr, collapse = " & "), " \\\\\n",
    "        \\bottomrule\n",
    "\\end{tabular}\n",
    "\\end{table}\n",
    sep = "")
sink()