library(readr)
library(ggplot2)
library(dplyr)
library(purrr)

variations <- c("multi_island", "multi_floor")
prefix_set <- "official_experiments/data/grb_vs_hx"
prefix_csv_input <- "inst_by_inst_grb_vs_hx_dev_type_"

set.seed(0)

for(i in seq_along(variations)){
  csv_input_t1 <- paste0(
    prefix_set,
    "/",
    variations[i],
    "/",
    prefix_csv_input,
    1,
    ".csv"
  )
  inst_by_inst_grb_vs_hx_dev_type_1 <- read_delim(
    csv_input_t1,
    delim = ";", escape_double = FALSE, trim_ws = TRUE)
  
  csv_input_t2 <- paste0(
    prefix_set,
    "/",
    variations[i],
    "/",
    prefix_csv_input,
    2,
    ".csv"
  )
  inst_by_inst_grb_vs_hx_dev_type_2 <- read_delim(
    csv_input_t2,
    delim = ";", escape_double = FALSE, trim_ws = TRUE)
  
  
  inst_by_inst_grb_vs_hx_dev <- bind_rows(inst_by_inst_grb_vs_hx_dev_type_1, inst_by_inst_grb_vs_hx_dev_type_2)
  inst_by_inst_grb_vs_hx_dev$type <- substr(inst_by_inst_grb_vs_hx_dev$name, 3, 3)
  
  p <- ggplot(inst_by_inst_grb_vs_hx_dev, aes(x = type, y = dev_obj)) +
    geom_boxplot(outlier.shape = NA) +
    geom_point(
      aes(x = type, y = dev_obj),
      shape = 21,
      position = position_jitter(width = 0.2, height = 0),
      alpha = 0.5
    ) +
    labs(x = "Type", y = "Deviation (%)") +
    scale_y_sqrt(
      limits = c(0, 150),
      breaks = c(0, 1, 5, 10, 20, 50, 100, 150),
      labels = function(x) paste0(x)
    )
  
  
  print(p)
  filename <- paste0("./official_experiments/grb_vs_hx/plots/boxplots_dev_by_type_", variations[i], ".pdf")
  # ggsave(filename, plot = p, width = 5, height = 4) # uncomment to save the plots
}