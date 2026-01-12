library(ggplot2)
library(gridExtra)
args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  stop("no snapshot file provided", call.=FALSE)
} 

input_file_xy <- args[1]
input_file_xz <- args[2]
input_file_yz <- args[3]

if (length(args)>=4) {
  compression_file <- args[4]
  compressed <- TRUE
  current_snap <- as.numeric(args[5])
} else {
  compressed <- FALSE
}
xy <- read.table(input_file_xy, header = T, dec =".")
xz <- read.table(input_file_xz, header = T, dec =".")
yz <- read.table(input_file_yz, header = T, dec =".")

color_palette <- colorRampPalette(c("blue", "yellow", "red"))
num <- as.numeric(xy$pressure)
if(compressed == TRUE){
  comp_info <- read.table(compression_file, header = T, dec =" ")
  vmin  <- as.numeric(comp_info$vmin[current_snap])
  delta <- as.numeric(comp_info$delta[current_snap])
  num <- vmin + (num * delta)
}
#plot(df$x, df$y, col = colors, pch=19)

#ggplot(df, aes(x = x, y = y, color = num)) +
#  geom_point(size = 3) +
#  scale_color_gradient2(low = "blue", mid = "yellow", high = "red") +
#  theme_minimal() +
#  theme(legend.position = "none")

xy_plot <- ggplot(xy, aes(x = x, y = y, fill = num)) +

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
