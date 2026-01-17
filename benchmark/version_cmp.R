library(ggplot2)
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  stop("no output file provided", call. = FALSE)
}
input_file <- args[1]

df <- read.table(input_file, header = T, sep = ",")

ggplot(df, aes(x = Ex, y = Total.Time)) +
  geom_line(color = "#161B33") +
  geom_point(size = 2, color = "#D991BA") +
  theme(legend.position = "none") +
  xlab("Side size (ex=ey=ez)") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_nodes.png", sep = ""), width = 8, height = 6)

ggplot(df, aes(x = Ex, y = Total.Time, color = Snapshot.Enabled)) +
  geom_line(aes(group = Snapshot.Enabled)) +
  geom_point(size = 2) +
  scale_color_manual(values = c("#D991BA", "#58508D")) +
  scale_y_log10() +
  theme(
    legend.position = c(0.05, 0.95),
    legend.justification = c("left", "top"),
    legend.background = element_rect(fill = "white", color = NA),
    plot.title = element_text(face = "bold"),
  ) +
  guides(color = guide_legend(title = "Snapshot enabled")) +
  xlab("Side size (ex=ey=ez)") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_snapshot_cmp.png", sep = ""), width = 8, height = 6)

ggplot(df, aes(x = Snapshot.Interval, y = Total.Time)) +
  geom_line(color = "#161B33") +
  geom_point(size = 2, color = "#D991BA") +
  theme(legend.position = "none") +
  xlab("Snapshots interval (iteration)") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_snapshot_interval.png", sep = ""), width = 8, height = 6)

ggplot(df, aes(x = Receivers, y = Total.Time)) +
  geom_line(color = "#161B33") +
  geom_point(size = 2, color = "#D991BA") +
  theme(legend.position = "none") +
  xlab("Number of receivers") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_receivers.png", sep = ""), width = 8, height = 6)

ggplot(df, aes(x = Ex, y = Total.Time, color = Snapshot.Interval)) +
  geom_line(aes(group = Snapshot.Interval)) +
  geom_point(size = 2) +
  # scale_color_manual(values = c("#D991BA","#58508D", "#7b2d8fff")) +
  scale_y_log10() +
  theme(
    legend.position = c(0.05, 0.95),
    legend.justification = c("left", "top"),
    legend.background = element_rect(fill = "white", color = NA),
    plot.title = element_text(face = "bold"),
  ) +
  guides(color = guide_legend(title = "Snapshot interval")) +
  xlab("Side size (ex=ey=ez)") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_snapshot_interval.png", sep = ""), width = 8, height = 6)

ggplot(df, aes(x = Ex, y = Total.Time, color = Snapshot.Slices)) +
  geom_line(aes(group = Snapshot.Slices)) +
  geom_point(size = 2) +
  # scale_color_manual(values = c("#D991BA","#58508D", "#7b2d8fff")) +
  scale_y_log10() +
  theme(
    legend.position = c(0.05, 0.95),
    legend.justification = c("left", "top"),
    legend.background = element_rect(fill = "white", color = NA),
    plot.title = element_text(face = "bold"),
  ) +
  guides(color = guide_legend(title = "Snapshot slices")) +
  xlab("Side size (ex=ey=ez)") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_snapshot_slices.png", sep = ""), width = 8, height = 6)

df$Experiment <- "Reference"

df$Experiment[df$Snapshot.Enabled == "true" & df$Snapshot.Slices == "false"] <- "Snapshots"

df$Experiment[df$Snapshot.Slices == "true"] <- "Slices"

df$Experiment[df$In.situ == "true"] <- "In-situ"

df$Experiment <- factor(df$Experiment, levels = c("Reference", "In-situ", "Snapshots", "Slices"))

ggplot(df, aes(x = Ex, y = Total.Time, color = Experiment)) +
  geom_line(aes(group = Experiment)) +
  geom_point(size = 2) +
  scale_color_manual(values = c(
    "Reference" = "black",
    "In-situ" = "#E69F00",
    "Snapshots" = "#56B4E9",
    "Slices" = "#009E73"
  )) +
  scale_y_log10() +
  theme(
    legend.position = c(0.05, 0.95),
    legend.justification = c("left", "top"),
    legend.background = element_rect(fill = "white", color = NA),
    plot.title = element_text(face = "bold"),
  ) +
  guides(color = guide_legend(title = "Experiment Type")) +
  xlab("Side size (ex=ey=ez)") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_experiment.png", sep = ""), width = 8, height = 6)


ggplot(df, aes(x = Ex, y = Mean.Snapshot.Size, color = Experiment)) +
  geom_line(aes(group = Experiment)) +
  geom_point(size = 2) +
  scale_color_manual(values = c(
    "Reference" = "black",
    "In-situ" = "#E69F00",
    "Snapshots" = "#56B4E9",
    "Slices" = "#009E73"
  )) +
  scale_y_log10() +
  theme(
    legend.position = c(0.05, 0.95),
    legend.justification = c("left", "top"),
    legend.background = element_rect(fill = "white", color = NA),
    plot.title = element_text(face = "bold"),
  ) +
  guides(color = guide_legend(title = "Experiment Type")) +
  xlab("Side size (ex=ey=ez)") +
  ylab("Total Time (s)")

ggsave(paste(input_file, "_experiment_size.png", sep = ""), width = 8, height = 6)
