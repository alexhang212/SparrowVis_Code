## Go from meerkat output to video clips

#!/usr/bin/env Rscript
# Runs all scripts to generate datafiles of frames for one video for CNN
rm(list=ls())

#setwd("/rds/general/user/hhc4317/home/ModelTraining/Code/")

library(abind)
library(parallel)

# iter <-as.numeric(Sys.getenv("PBS_ARRAY_INDEX")) # get iteration
source("ProcessFrameInfo.R")

Files <- list.files("../MeerkatOutput/")
print(Files)

lapply(Files, Process_framecsv)

