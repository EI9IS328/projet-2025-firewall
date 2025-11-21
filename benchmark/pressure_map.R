library(ggplot2)
library(ggpubr)
args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  stop("no snapshot file provided", call.=FALSE)
} 
input_file <- args[1]

df <- read.table(input_file, header = T, dec =" ")
color_palette <- colorRampPalette(c("blue", "yellow", "red"))
num <- as.numeric(df$pressure)
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

res <- ggarrange(xy, xz, yz, labels = c("XY Slice", "XZ Slice", "YZ Slice"),ncol = 2, nrow = 2)
ggsave(paste(input_file, "_res.png", sep = ""), width = 8, height = 6)