library(ggplot2)
library(gridExtra)
args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  stop("no snapshot file provided", call.=FALSE)
} 

input_file_xy <- args[1]
input_file_xz <- args[2]
input_file_yz <- args[3]

xy <- read.table(input_file_xy, header = T, dec =".")
xz <- read.table(input_file_xz, header = T, dec =".")
yz <- read.table(input_file_yz, header = T, dec =".")

# xy plot
xy_plot <- ggplot(xy, aes(x = x, y = y, fill = pressure)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", mid = "yellow", high = "red") +
  theme(legend.position = "left") +
  ggtitle("XY Slice")

# xz plot
xz_plot <- ggplot(xz, aes(x = x, y = z, fill = pressure)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", mid = "yellow", high = "red") +
  theme(legend.position = "left") +
  ggtitle("XZ Slice")

# yz plot
yz_plot <- ggplot(yz, aes(x = y, y = z, fill = pressure)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", mid = "yellow", high = "red") +
  theme(legend.position = "left") +
  ggtitle("YZ Slice")

res <- arrangeGrob(xy_plot, xz_plot, yz_plot, ncol = 2, nrow = 2)
ggsave(paste(input_file_xy, "_res.png", sep = ""), plot = res, width = 8, height = 6)