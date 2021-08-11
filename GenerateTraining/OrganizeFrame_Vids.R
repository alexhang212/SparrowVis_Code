#!/usr/bin/env Rscript
# Runs all scripts to generate datafiles of frames for one video for CNN
rm(list=ls())

setwd("/rds/general/user/hhc4317/home/ModelTraining/Code/")

library(abind)
library(parallel)

iter <-as.numeric(Sys.getenv("PBS_ARRAY_INDEX")) # get iteration
source("ProcessFrameInfo.R")
source("GenerateTraining.R")
source("ProcessVideos.R")

Files <- list.files("../MeerkatOutput2013/")

#split files into equal chunks:
Indicies <- splitIndices(length(Files),100)
#Manual <- c(16,17,18,21,22,24,27) #delete later, for manual run

#debug:
# FileName <- "VO0018_VP11_LM40_20150505"
# 

#Initialize arrays and vectors
length <-7 # length of clips, by seconds
# MainArray <- array(data=NA, dim=c(1,(7*5)+1,3,256,144)) 
# MainVect <- c()
# MainSexVect <- c()

# get the index for that iteration
#iter <- Manual[iter]
IndexVect <- Indicies[[iter]]
# IndexVect <- 1:length(Files) # for local testing

for(i in IndexVect){
  #browser()
  FileName <- Files[i]
  print(paste("Organizing video", FileName))
  
  VidCode <- strsplit(FileName,"_")[[1]][1]
  Process_framecsv(FileName)
  CodefrmExcel(FileName,VidCode)
  
  data <- read.csv(paste("../MeerkatOutput2013/",FileName,"/","FramesShortCoded.csv", sep=""))
  # data <- na.omit(data,data$EventDes)
  
  if(nrow(data) >0){ #check if all data was removed
  
  ProcessVideo(FileName, data)
  Output <- ProcessClips(FileName, data,imagescale=10, length=length)

  VidInfo <- read.csv("../Data/VideoInfo.csv")
  
  if(VidInfo[which(VidInfo$FileName==FileName), "Type"]=="Training"){
   #if video is of "Training" type, save into big Array
   MainArray <- abind(MainArray,Output[[1]],along=1)
   MainVect <- c(MainVect, Output[[2]])
   MainSexVect <- c(MainSexVect, Output[[3]])
  }else{
   #do nothing
  }
  }
}

MainArray <- MainArray[-1,,,,]  #remove first layer, initialization array

#Switch back to channels_last format
MainArray <- aperm(MainArray, c(1,2,4,5,3))
MainVect <- as.numeric(MainVect)


save(MainArray, file=paste("../ClipArrays/MainArray_5-", iter,".rda", sep=""))
save(MainVect, file=paste("../ClipArrays/MainVect-", iter,".rda", sep=""))
save(MainSexVect, file=paste("../ClipArrays/MainSexVect-", iter,".rda", sep=""))
save(Val.Array, file="../ClipArrays/ValArray.rda")
save(Val.Vect, file="../ClipArrays/ValVect.rda")
