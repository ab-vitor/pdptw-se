library(dplyr)
library(ggplot2)
library(tidyr)
library(stringr)



prefix <- "official_experiments/mip_grb_vi"
input_dir <- "tables_per_configuration"
input_file <- "composite_score_per_vi_config.csv"
path_to_csv_input <- file.path(prefix, input_dir, input_file)

composite_score_per_vi_config <- read_delim(
  file = path_to_csv_input, 
  delim = ";"
)


# Plot composite score per configuration
p <- ggplot(
  composite_score_per_vi_config, 
  aes(
    x = composite_score, 
    y = reorder(vi_config, composite_score)
  )
) +
  geom_col(fill="steelblue") +
  labs(
    x="Score",
    y="Valid inequality configuration", 
    title="Score per valid inequality configuration"
  ) +
  scale_x_continuous(
    limits = c(0,1),
    breaks = seq(0, 1, by = 0.2)
  )


print(p)

ggsave(
  filename = "composite_score_plot_vi_configurations.pdf",
  plot = p,
  path = "official_experiments/mip_grb_vi/plots/",
  width = 8, height = 6,
  units = "in"
)