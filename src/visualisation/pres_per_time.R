library(ggplot2)
library(ggpubr)
setwd("~/in-situ/projet-2025-firewall/src/visualisation")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  stop("No file provide")
}

file <- args[1]
df <- read.table(file, header = TRUE)
#print(head(df))

plots <- list()

for(receiver in 2:ncol(df)){
  graph <- ggplot(df) + geom_line(aes(x=TimeStep, y=df[ ,receiver]))
  plots[[receiver - 1]]<-graph
  #ggsave(paste("graph/graph",receiver, ".png"), plot = graph, width = 8, height = 6, dpi = 300)
}

Ncol <- ceiling(sqrt(ncol(df)))

# Agencement avec ggarrange
all_graph <- ggarrange(plotlist = plots, ncol = Ncol, nrow = Ncol)

#ggsave(paste("graph/graph.png"), plot = multGraph, width = 8, height = 6, dpi = 300)

#ggplot(df)+geom_line(aes(x=TimeStep, y=recv2))+geom_line(aes(x=TimeStep, y=recv1))
                                                                                                      