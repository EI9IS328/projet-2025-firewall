library(ggplot2)
library(ggpubr)
args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  stop("no snapshot file provided", call.=FALSE)
} 

input_file_xy <- args[1]
input_file_xz <- args[2]
input_file_yz <- args[3]

xy <- read.table(input_file_xy, header = T, dec =" ")
xz <- read.table(input_file_xz, header = T, dec =" ")
yz <- read.table(input_file_yz, header = T, dec =" ")

color_palette <- colorRampPalette(c("blue", "yellow", "red"))
num <- as.numeric(xy$recomputedPressure)
colors <- color_palette(500)[as.numeric(cut(num, breaks = 500))]
#plot(df$x, df$y, col = colors, pch=19)

#ggplot(df, aes(x = x, y = y, color = num)) +
#  geom_point(size = 3) +
#  scale_color_gradient2(low = "blue", mid = "yellow", high = "red") +
#  theme_minimal() +
#  theme(legend.position = "none")

xy_plot <- ggplot(xy, aes(x = x, y = y, fill = num)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", mid = "yellow", high = "red") +
  theme(legend.position = "left")

#ggsave(paste(input_file, "x_y.png", sep = ""), width = 8, height = 6)

xz_plot <- ggplot(xz, aes(x = x, y = z, fill = num)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", mid = "yellow", high = "red") +
  theme(legend.position = "left")

#ggsave(paste(input_file, "x_z.png", sep = ""), width = 8, height = 6)

yz_plot <- ggplot(yz, aes(x = y, y = z, fill = num)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", mid = "yellow", high = "red") +
  theme(legend.position = "left")

#ggsave(paste(input_file, "y_z.png", sep = ""), width = 8, height = 6)

res <- ggarrange(xy_plot, xz_plot, yz_plot, labels = c("XY Slice", "XZ Slice", "YZ Slice"),ncol = 2, nrow = 2)
ggsave(paste(input_file, "_res.png", sep = ""), width = 8, height = 6)