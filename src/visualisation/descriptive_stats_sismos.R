library(ggplot2)
library(ggpubr)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  stop("No file provide")
}

file <- args[1]
df <- read.table(file, header = TRUE)

graph <- ggplot(df) 

for(receiver in 2:ncol(df)){
  graph <- graph + geom_boxplot(aes(x = df$receiver, y = df[ ,receiver]))
}

ggsave("graph/graph_descriptive_stats_sismos.png", graph, width = 10, height = 8, dpi = 300, bg = "white")