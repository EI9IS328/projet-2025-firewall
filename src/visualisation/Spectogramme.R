library(ggplot2)
library(ggpubr)

setwd("~/in-situ/projet-2025-firewall/src/visualisation")

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  stop("No file provided")
}

file <- args[1]
cat("file", file, "\n")
df <- read.table(file, header = TRUE)


dt <- 0.001          
Fs <- 1 / dt         
N  <- nrow(df)      
time <- (df$TimeStep - df$TimeStep[1]) * dt 



compute_envelope <- function(signal, window_size) {
  
  signal_abs <- abs(signal)
  N <- length(signal_abs)
 

  pad <- floor(window_size / 2)
  left_pad <- rep(signal_abs[1], pad)
  right_pad <- rep(signal_abs[N], pad)
  
  padded <- c(left_pad, signal_abs, right_pad)
  
  filt <- rep(1 / window_size, window_size)

  conv <- as.numeric(stats::filter(padded, filt, sides = 2))
  
  start <- pad + 1
  end   <- pad + N
  env <- conv[start:end]
  
  env[is.na(env)] <- signal_abs[is.na(env)]
  
  return(env)
}



plots <- list()


window_seconds <- 0.02
window_size <- max(3, round(window_seconds * Fs))


for (receiver in 2:ncol(df)) {
  
  sig <- df[, receiver]
  env <- compute_envelope(sig, window_size)
  
  tmp <- data.frame(
    time = time,
    signal = sig,
    envelope = env,
    receiver = colnames(df)[receiver]
  )
  
  plots[[receiver - 1]] <- 
    ggplot(tmp, aes(x = time)) +
    geom_line(aes(y = signal), color = "grey50", size = 0.4) +
    geom_line(aes(y = envelope), color = "red", size = 0.9) +
    theme_minimal() +
    labs(
      title = paste("Enveloppe -", colnames(df)[receiver]),
      x = "Temps (s)",
      y = "Amplitude"
    ) +
    theme(legend.position = "none")
  
}


Ncol <- ceiling(sqrt(ncol(df) - 1))
all_graph <- ggarrange(plotlist = plots, ncol = Ncol, nrow = Ncol)


dir.create("graph", showWarnings = FALSE)
ggsave("graph/graph_enveloppe.png", all_graph, width = 10, height = 8, dpi = 300, bg = "white")
