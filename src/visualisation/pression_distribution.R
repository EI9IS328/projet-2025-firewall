##################################################
#                 Library                        #
##################################################
library(ggplot2)
library(ggpubr)

##################################################
#             File reader part                   #
##################################################
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  stop("No file provided")
}

file <- args[1]

df <- read.table(file, header = TRUE)

##################################################
#                 function                       #
##################################################
# Combine all receiver columns (exclude the first TimeStep column)
if (ncol(df) < 2) {
  stop("No receiver columns found")
}
pression <- as.numeric(unlist(df$pressure))
dataframe <- data.frame(pres = pression)

graph <- ggplot(dataframe, aes(x = pres)) +
  geom_histogram(fill = "darkorchid4", color = "darkgray", bins = 10) +
  scale_x_continuous(name = "Pressure") +
  ylab("Count") +
  theme_minimal()


##################################################
#             Save graph part                    #
##################################################
dir.create("graph", showWarnings = FALSE)
ggsave(paste("graph/graph_pression_distribution.png"), plot = graph, width = 8, height = 6, dpi = 300, bg = "white")
