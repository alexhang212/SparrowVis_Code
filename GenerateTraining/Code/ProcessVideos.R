#read in images, crop it and save array
# rm(list=ls())
library(magick)


# #For Testing:
# FileName <- "VN0383_VP7_LM4_20140612"
# data <- read.csv(paste("../MeerkatOutput/",FileName,"/","FramesShortCoded.csv", sep=""))
# data <- na.omit(data, data$EventDes)
# ProcessClips(FileName,data)

#testing stuff

# reads short format data, trims video and ouput clips
ProcessVideo <- function(FileName, data){
  try(system(paste("mkdir ", "../TrainingClips/", FileName, sep=""))) #try make directory if it doesnt exist
  for(i in 1:nrow(data)){
    event <- data[i,"Event"]
    StartFrame <- data[i, "StartFrame"]
    StartFrameNum <- floor(StartFrame/25)-1 #get format for ffmpeg
    #ephDir <- "/rds/general/user/hhc4317/ephemeral/" # get directory for ephemeral
    ephDir <- "../" # if testing locally

    system(paste("ffmpeg ","-y ", "-ss ", StartFrameNum, " -i ", ephDir,"RawVideos/", 
                 FileName, ".MP4 ", "-t ", "7 ", "-c:v ", "libx264 ","-an ", "../TrainingClips/",FileName,"/E",event,".",data[i,"Sex"],".", data[i,"EventDes"], ".MP4", 
                 sep=""))
    
  }
  
}



### Function to process all clips to arrays
# FileName <- "VO0018_VP11_LM40_20150505"
# data <- read.csv(paste("../MeerkatOutput/",FileName,"/","FramesShortCoded.csv", sep=""))
# data <- na.omit(data, data$EventDes)


ProcessClips <- function(FileName, data,imagescale=10, length=7){
  # length specifies length of the clip in seconds
  
  #desired height and width
  ht <- 720/imagescale
  wt <- 1280/imagescale
  
  #get num of clips:
  Clips <- sort(list.files(paste("../TrainingClips/", FileName, "/", sep="")))
  VidArray <- array(data=NA, dim=c(length(Clips), (length*5)+1,3,wt,ht ))
  
  for(i in 1:length(Clips)){
  ClipName <- Clips[which(startsWith(Clips, paste("E",data$Event[i],".",sep="")))] #get name of clip
  Vid <- image_read(paste("../TrainingClips/", FileName, "/", ClipName, sep=""))
  
  VidScale <- image_scale(Vid, paste(wt,"x",ht, sep="")) #scale down video
  
  interval <- seq(0,(length*25), by=5) #interval of extracted frames
  interval[1] <- 1 #replace first frame to 1 instead of 0
  ClipArray <- array(data=NA, dim=c((length*5)+1,3,wt,ht))
  
  for(j in 1:length(interval)){
    #browser
    ClipArray[j , , ,] <- as.integer(VidScale[[(interval[j])]])
    # browser()
    # plot(VidScale[(interval[j])])
  }
  
  #save into array
  VidArray[i , , , ,] <- ClipArray
  
  }
  
  save(VidArray, file=paste("../ClipArrays/",FileName,"_ClipArray_5.rda", sep=""))
  
  #Get Y vector for behaviour:
  #change behaviour codes to numbers
  data <- data %>% mutate(EventDes= ifelse(EventDes=="In", 1,EventDes)) %>%
    mutate(EventDes= ifelse(EventDes=="Out", 2,EventDes)) %>%
    #mutate(EventNum= ifelse(EventDes=="OutsideFeeding", 3,EventDes)) %>%
    mutate(EventDes= ifelse(is.na(EventDes)|EventDes=="Around"|EventDes=="OutsideFeeding", 0,EventDes))
  
  BehavVect <- data$EventDes
  
  #Get Y vector for Sex:
  SexVect <- data$Sex
  
  #save vectors
  save(BehavVect, file=paste("../ClipArrays/",FileName,"_ClipVect.rda", sep=""))
  save(SexVect, file=paste("../ClipArrays/",FileName,"_SexVect.rda", sep=""))
  
  
  #Get Behaviour matrix for multi-label classification:
  #yo <- matrix(unlist(lapply(data$EventDes, GetBehav)), ncol =2, byrow=T)
  
  return(list(VidArray, BehavVect,SexVect))
}


#Code Outputs for multi label (afterwards)
# GetBehav <- function(Behav){
#   if(Behav=="In"){
#     Output <- c(1,0)
#   }else{
#     if(Behav=="Out"){
#       Output <- c(0,1)
#     }else{
#       Output <- c(0,0)
#     }
#   }
#   return(Output)
# }
