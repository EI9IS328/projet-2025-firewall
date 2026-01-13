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


##################################################
#                 pres_per_time                  #
##################################################

plots <- list()


for(receiver in 2:ncol(df)){
  colname <- colnames(df)[receiver]
  plots[[receiver - 1]] <- ggplot(df) + geom_line(aes(x = Time, y = .data[[colname]])) + labs(y = colname, title = "Pressure per time")
}

Ncol <- ceiling(sqrt(ncol(df) - 1))

all_graph <- ggarrange(plotlist = plots, ncol = Ncol, nrow = Ncol)

ggsave(paste(file, "_pres_per_time.png", sep = ""), plot = all_graph, width = 8, height = 6, dpi = 300)

##################################################
#            desscriptive_stats_sismos           #
##################################################

values <- unlist(df[, 2:ncol(df)])
receivers <- rep(colnames(df)[2:ncol(df)], each = nrow(df))

long_df <- data.frame(
  receiver = receivers,
  pressure = values
)

graph <- ggplot(long_df, aes(x = receiver, y = pressure)) +
  geom_boxplot(outlier.alpha = 0.3) +
  labs(
    title = "Descriptive statistics of the sismos",
    x = "Receiver",
    y = "Pression"
  )


ggsave(paste(file, "descriptive_stats.png", sep = ""),
       graph, width = 10, height = 8, dpi = 300, bg = "white")

##################################################
#                 freq_per_time                  #
##################################################

dt <- 0.001   # time between two steps
Fs <- 1 / dt  # freq
N  <- nrow(df)  # nb rcv

compute_fft <- function(signal, Fs) {
  N <- length(signal)
  fft_vals <- fft(signal)
  
 
  half <- floor(N / 2)
  amplitude <- Mod(fft_vals)[1:half]
  freq <- seq(0, Fs / 2, length.out = half)
  
  return(data.frame(freq = freq, amplitude = amplitude))
}

plots <- list()


for (receiver in 2:ncol(df)) {
  fft_tmp <- compute_fft(df[, receiver], Fs)
  fft_tmp$receiver <- factor(colnames(df)[receiver], levels = colnames(df)[2:ncol(df)])
  

  plots[[receiver - 1]] <- ggplot(fft_tmp, aes(x = freq, y = amplitude, color = receiver)) + 
    geom_line() + 
    theme_minimal() +
    labs(
      title = paste("frequentiel analysis - ", colnames(df)[receiver]),
      x = "Frequence (Hz)",
      y = "Amplitude FFT"
    ) +
    theme(legend.position = "none")
}

Ncol <- ceiling(sqrt(ncol(df) - 1))

all_graph <- ggarrange(plotlist = plots, ncol = Ncol, nrow = Ncol)

ggsave(paste(file, "_freq.png", sep = ""), plot = all_graph, width = 8, height = 6, dpi = 300, bg = "white")

##################################################
#                 Spectrogram                    #
##################################################

time <- (df$Time- df$Time[1]) * dt 

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
      title = paste("Spectrogram -", colnames(df)[receiver]),
      x = "Time (s)",
      y = "Amplitude"
    ) +
    theme(legend.position = "none")
  
}

Ncol <- ceiling(sqrt(ncol(df) - 1))
all_graph <- ggarrange(plotlist = plots, ncol = Ncol, nrow = Ncol)

ggsave(paste(file, "_spectrogram.png", sep = ""), all_graph, width = 10, height = 8, dpi = 300, bg = "white")

##################################################
#              pression_distribution             #
##################################################

if (ncol(df) < 2) {
  stop("No receiver columns found")
}
pression <- as.numeric(unlist(df[ , -1]))
dataframe <- data.frame(pres = pression)

graph <- ggplot(dataframe, aes(x = pres)) +
  geom_histogram(fill = "darkorchid4", color = "darkgray", bins = 10) +
  scale_x_continuous(name = "Pressure") +
  ylab("Count") +
  theme_minimal() +
  labs(
    title = "pression distribution"
  )

ggsave(paste(file, "_pression_distribution.png", sep = ""), plot = graph, width = 8, height = 6, dpi = 300, bg = "white")



