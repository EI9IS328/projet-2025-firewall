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

#df <- read.table("../samples/sismos.sample", header = TRUE)

##################################################
#                 parameter                      #
##################################################
dt <- 0.001   # time between two steps
Fs <- 1 / dt  # freq
N  <- nrow(df)  # nb rcv



##################################################
#                 functions                      #
##################################################

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



##################################################
#             Save graph part                    #
##################################################
Ncol <- ceiling(sqrt(ncol(df)))


all_graph <- ggarrange(plotlist = plots, ncol = Ncol, nrow = Ncol)

dir.create("graph", showWarnings = FALSE)
ggsave(paste("graph/graph_freq.png"), plot = all_graph, width = 8, height = 6, dpi = 300, bg = "white")
