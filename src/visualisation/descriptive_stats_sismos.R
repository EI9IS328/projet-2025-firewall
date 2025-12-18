##################################################
#                 Library                        #
##################################################
library(ggplot2)
library(ggpubr)

##################################################
#             File reader part                   #
##################################################
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) stop("No file provided")

file <- args[1]
df <- read.table(file, header = TRUE)

##################################################
#                Reshape                         #
##################################################
values <- unlist(df[, 2:ncol(df)])
receivers <- rep(colnames(df)[2:ncol(df)], each = nrow(df))

long_df <- data.frame(
  receiver = receivers,
  pressure = values
)

##################################################
#                   Boxplot                      #
##################################################
graph <- ggplot(long_df, aes(x = receiver, y = pressure)) +
  geom_boxplot(outlier.alpha = 0.3) +
  labs(
    title = "Statistiques descriptives des sismos",
    x = "Receiver",
    y = "Pression"
  )


##################################################
#             Save graph part                    #
##################################################
dir.create("graph", showWarnings = FALSE)
ggsave("graph/graph_descriptive_stats_sismos.png",
       graph, width = 10, height = 8, dpi = 300, bg = "white")


##################################################
#             Save mean medianne                 #
##################################################

receivers <- colnames(df)[2:ncol(df)]

mean_vals   <- numeric(length(receivers))
median_vals <- numeric(length(receivers))
min_vals    <- numeric(length(receivers))
max_vals    <- numeric(length(receivers))
sd_vals     <- numeric(length(receivers))

for (i in seq_along(receivers)) {
  x <- df[[receivers[i]]]
  
  mean_vals[i]   <- mean(x, na.rm = TRUE)
  median_vals[i] <- median(x, na.rm = TRUE)
  min_vals[i]    <- min(x, na.rm = TRUE)
  max_vals[i]    <- max(x, na.rm = TRUE)
  sd_vals[i]     <- sd(x, na.rm = TRUE)
}

stats_df <- rbind(
  mean   = mean_vals,
  median = median_vals,
  min    = min_vals,
  max    = max_vals,
  sd     = sd_vals
)

colnames(stats_df) <- receivers

write.table(stats_df, file = "stats_sismos_basic.txt", sep = " ", row.names = TRUE, col.names = NA, quote = FALSE)
