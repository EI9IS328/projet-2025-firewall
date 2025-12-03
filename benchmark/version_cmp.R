library(ggplot2)
args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  stop("no output file provided", call.=FALSE)
} 
input_file <- args[1]

df <- read.table(input_file, header = T, sep =",")

ggplot(df, aes(x = Nodes, y = Total.Time)) +
  geom_line(color = "#161B33") +
  geom_point(size= 2, color = "#D991BA") +
  theme_minimal() +
  theme(legend.position = "none") +
  xlab("Nodes") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_nodes.png", sep = ""), width = 8, height = 6)

ggplot(df, aes(x = Nodes, y = Total.Time, color = Snapshot.Enabled)) +
  geom_line(aes(group = Snapshot.Enabled)) +
  geom_point(size= 2) +
  scale_color_manual(values = c("#D991BA","#58508D")) +
  theme_minimal() +
  theme(
    legend.position = c(0.05, 0.95),
    legend.justification = c("left", "top"),
    legend.background = element_rect(fill = "white", color = NA),
    plot.title = element_text(face = "bold"),
  ) +
  guides(color = guide_legend(title = "Snapshot enabled")) +
  xlab("Nodes") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_snapshot_cmp.png", sep = ""), width = 8, height = 6)

ggplot(df, aes(x = Snapshot.Interval, y = Total.Time)) +
  geom_line(color = "#161B33") +
  geom_point(size= 2, color = "#D991BA") +
  theme_minimal() +
  theme(legend.position = "none") +
  xlab("Snapshots interval (iteration)") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_snapshot_interval.png", sep = ""), width = 8, height = 6)

ggplot(df, aes(x = Receivers, y = Total.Time)) +
  geom_line(color = "#161B33") +
  geom_point(size= 2, color = "#D991BA") +
  theme_minimal() +
  theme(legend.position = "none") +
  xlab("Number of receivers") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_receivers.png", sep = ""), width = 8, height = 6)

