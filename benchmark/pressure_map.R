library(ggplot2)
library(ggpubr)
args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  stop("no snapshot file provided", call.=FALSE)
} 
input_file <- args[1]
if (length(args)>2) {
  compression_file <- args[2]
  compressed <- TRUE
  current_snap <- as.numeric(args[3])
} else {
  compressed <- FALSE
}
df <- read.table(input_file, header = T, dec =" ")
color_palette <- colorRampPalette(c("blue", "yellow", "red"))
num <- as.numeric(df$pressure)

if(compressed == TRUE){
  comp_info <- read.table(compression_file, header = T, dec =" ")
  vmin  <- as.numeric(comp_info$vmin[current_snap])
  delta <- as.numeric(comp_info$delta[current_snap])
  num <- vmin + (num * delta)
}
colors <- color_palette(500)[as.numeric(cut(num, breaks = 500))]
#plot(df$x, df$y, col = colors, pch=19)

#ggplot(df, aes(x = x, y = y, color = num)) +
#  geom_point(size = 3) +
#  scale_color_gradient2(low = "blue", mid = "yellow", high = "red") +
#  theme_minimal() +
#  theme(legend.position = "none")

xy <- ggplot(df, aes(x = x, y = y, fill = num)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", mid = "yellow", high = "red") +
  theme(legend.position = "left")

#ggsave(paste(input_file, "x_y.png", sep = ""), width = 8, height = 6)

xz <- ggplot(df, aes(x = x, y = z, fill = num)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", mid = "yellow", high = "red") +
  theme(legend.position = "left")

#ggsave(paste(input_file, "x_z.png", sep = ""), width = 8, height = 6)

yz <- ggplot(df, aes(x = y, y = z, fill = num)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", mid = "yellow", high = "red") +
  theme(legend.position = "left")

#ggsave(paste(input_file, "y_z.png", sep = ""), width = 8, height = 6)

pressure <- colnames(df)[4:ncol(df)]

x <- as.numeric(df[[pressure[1]]])
  
mean_vals   <- mean(x, na.rm = TRUE)
median_vals <- median(x, na.rm = TRUE)
min_vals    <- min(x, na.rm = TRUE)
max_vals    <- max(x, na.rm = TRUE)
sd_vals     <- sd(x, na.rm = TRUE)

# Create a data frame for the table
stats_df <- data.frame(
  Statistique = c("Mean", "Median", "Minimum", "Maximum", "Standard Deviation"),
  Valeur = c(
    sprintf("%.4f", mean_vals),
    sprintf("%.4f", median_vals),
    sprintf("%.4f", min_vals),
    sprintf("%.4f", max_vals),
    sprintf("%.4f", sd_vals)
  )
)

stats_table <- ggtexttable(stats_df, rows = NULL,
                           theme = ttheme("mBlue")) +
  theme(plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA))

res <- ggarrange(xy, xz, yz,stats_table, labels = c("XY Slice", "XZ Slice", "YZ Slice", "Descriptive Statistics"),ncol = 2, nrow = 2)
ggsave(paste(input_file, "_res.png", sep = ""), width = 8, height = 6)