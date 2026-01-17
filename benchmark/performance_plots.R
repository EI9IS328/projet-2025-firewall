#!/usr/bin/env Rscript

# Check for ggplot2 and install if missing
if (!require("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2", repos='http://cran.us.r-project.org')
  library(ggplot2)
}

# Capture command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("Usage: Rscript plot_performance.R <csv_file_path>")
}

csv_path <- args[1]
output_path <- "performance_plot.png"

# Load data
if (!file.exists(csv_path)) {
  stop(paste("File not found:", csv_path))
}
df <- read.csv(csv_path)

# Create the plot
p <- ggplot(df, aes(x = problem_size, y = execution_time_seconds)) +
  geom_line(color = "#2c3e50", size = 1) +
  geom_point(color = "#e74c3c", size = 3) +
  labs(
    title = "Post-treatment time depending ont the size of the problem",
    subtitle = paste("Source:", csv_path),
    x = "Problem Size (N)",
    y = "Post-treatment Time (seconds)"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5)
  )

# Save
ggsave(output_path, plot = p, width = 10, height = 6, dpi = 300)
cat(paste("Success: Performance plot saved to", output_path, "\n"))