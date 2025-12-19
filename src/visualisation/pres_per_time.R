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
  stop("No file provide")
}

file <- args[1]
df <- read.table(file, header = TRUE)
#print(head(df))

##################################################
#                 functions                      #
##################################################
plots <- list()


for(receiver in 2:ncol(df)){
  colname <- colnames(df)[receiver]
  plots[[receiver - 1]] <- ggplot(df) + geom_line(aes(x = Time, y = .data[[colname]])) + labs(y = colname)
}

##################################################
#             Save graph part                    #
##################################################
Ncol <- ceiling(sqrt(ncol(df)))
dir.create("graph", showWarnings = FALSE)
all_graph <- ggarrange(plotlist = plots, ncol = Ncol, nrow = Ncol)

ggsave(paste("graph/graph_pres_per_time.png"), plot = all_graph, width = 8, height = 6, dpi = 300)


                                                                                                      