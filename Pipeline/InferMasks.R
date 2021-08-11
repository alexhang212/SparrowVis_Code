##run through masks of each video event and infer sex using model
Sys.setenv("CUDA_VISIBLE_DEVICES" = -1)

library(reticulate)
use_condaenv("RKeras", required = TRUE)
library(abind)
library(keras)
library(doParallel)
library(magick)


model <- load_model_hdf5("../Models/BestModelSex-158")

#Testing
# Video <- "VM0028-S1-7P-08052013"
# InferMask(Video)

InferMask <- function(Video){
  Short <- read.csv(paste("../MeerkatOutput/",Video, "/FramesShort.csv", sep=""))
  if(nrow(Short)==0){
    write.csv(Short, paste("../MeerkatOutput/",Video, "/FramesShortSexPredict.csv", sep=""))
    return(NULL)
  }
  
  Short[,"PredictSex"] <- NA
  Short[, "ConfidenceScore"] <- NA
  
  
  
  for(i in 1:nrow(Short)){
    images <- list.files(paste("../OutputMasks/",Video,"/Event",i,sep="")) #get all images
    if(length(images)==0){
      #no instances
      next
    }
    
    OutArray <- array(data=NA, dim=c(length(images),3,256,144))# preallocation
    
    for(j in 1:length(images)){
      image <- image_read(paste("../OutputMasks/",Video,"/Event",i,"/",images[j], sep=""))
      OutArray[j, , , ] <- as.integer(image[[1]])/255
    }
    
    OutArray <- aperm(OutArray, c(1,3,4,2))
    Prediction <- predict(model, OutArray)
    MeanScore <- mean(Prediction)
    if(MeanScore>0.5){
      #predict male
      Sex = 1
      Confidence = MeanScore
    }else{
      #predict female
      Sex = 0
      Confidence = 1-MeanScore
    }
    Short[i,"PredictSex"] <- Sex
    Short[i, "ConfidenceScore"] <- Confidence
    
    
  }
  
  write.csv(Short, paste("../MeerkatOutput/",Video, "/FramesShortSexPredict.csv", sep=""))
  
}

AllVids <- list.files("../OutputMasks/")

registerDoParallel(cores=32)
###Run inference for all videos

# mclapply(AllVids, InferMask, mc.cores = 32)
lapply(AllVids, InferMask)
stopImplicitCluster()


