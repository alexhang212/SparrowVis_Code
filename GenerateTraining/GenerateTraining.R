#Takes long/ short format and compares with excel file to generate training/ verification files
# rm(list=ls())
library(readxl)
library(DescTools)

# default: for testing
# FileName <- "VO0206_VP11_W22_20150628"
# # Process_framecsv(FileName)
# VidCode <- strsplit(FileName, "_")[[1]][1]# code for excel
# CodefrmExcel(FileName, VidCode)

#Modified FindClosest: finds the ones that cannot be confidently coded, then throws it out
FindClosest <- function(Short,mergedf){
  #browser()
  DiffMat <- apply(matrix(mergedf$Time), 1, function(x) abs(Short$MeanTime-x)) #matrix of difference of coded and meerkat time values
  
  #check if it is a matrix, since if there is only 1 row, it becomes vector
  if(isTRUE(is.matrix(DiffMat))==FALSE){
    #not a matrix, probably became vector
    DiffMat <- t(DiffMat)
  }
  
  MinIndex <- apply(DiffMat, 2, function(x) which.min(x)) #finding index with lowest abs difference
  MinVal <- apply(DiffMat,2,min) #value for the minimum difference
  
  mergedf$X <- 1:nrow(mergedf) # add index
  mergedf$MatchIndex <- MinIndex
  mergedf$MinDiff <- MinVal
  
  DupNum <- unique(MinIndex[duplicated(MinIndex)]) #these index numbers are duplicated
  GoodMatch <- subset(mergedf, !(mergedf$MatchIndex %in% DupNum )) #remove all the duplicated matches
  GoodMatch <- subset(GoodMatch, GoodMatch$MinDiff<0.1) #further filtering it
  
  if(nrow(GoodMatch)>1){
    #if there are some events left
  Prob <- nrow(GoodMatch)/nrow(mergedf)
  print(paste("Threw away ", Prob, "of event from Julia's dataset"))
  #update Short dataframe according to new index
  #browser()
  Short <- merge(Short, GoodMatch[, names(GoodMatch) %in% c("Time","Sex","EventDes", "MatchIndex")], by="MatchIndex", all=T)
  
  ##newly added: remove events that are within 7 seconds of each other##
  ShortTemp <- na.omit(Short,Short$EventDes)
  ShortTemp$Diff <- c(100000,diff(ShortTemp$StartFrame))
  
  Remove <- which(ShortTemp$Diff<7*25) #find index of large diffs
  RemoveIndex <- ShortTemp[c(Remove,Remove-1),"MatchIndex"]
  
  Short[RemoveIndex, c("Time","Sex","EventDes")] <- NA
  
  }else{
    #all the events are removed
    Short <- merge(Short, GoodMatch[, names(GoodMatch) %in% c("Time","Sex","EventDes", "MatchIndex")], by="MatchIndex", all=T)
    
    print("All Events threw away!!!! :((((( ")
    Prob <- 1
    
  }
  
  return(list(Short,Prob))
}




#### New####
# #found out there is a new dataframe with all visit data in one data file, using that instead of excels
# FileName <- "VN0383_VP7_LM4_20140612"
# VidCode <- strsplit(FileName, "_")[[1]][1]# code for excel
# #Year <- "2015"
# CodefrmExcel(FileName, VidCode)

CodefrmExcel<- function(FileName,VidCode){
 # browser()
  Short <- read.csv(paste("../MeerkatOutput/",FileName,"/FramesShort.csv", sep=""))
  Short$MatchIndex <- 1:nrow(Short)
  MasterTrain <- read.csv("../Data/MasterTraining.csv")
    
  VidSub <- subset(MasterTrain, MasterTrain$DVDNumber==VidCode)
  
  #smaller subsets:
  INdf <- subset(VidSub, VidSub$State=="I")
  Adf <- subset(VidSub, VidSub$State=="A")
  Odf <- subset(VidSub, VidSub$State=="O")
  
  #for going in: split into going in and out times
  if(nrow(INdf)>0){
  InOutTimeVect <- c(INdf$StartTime,INdf$EndTime)
  InOutSexVect <- c(INdf$Sex,INdf$Sex)
  InOutEvtVect <- c(rep("In", nrow(INdf)), rep("Out",nrow(INdf)))
  }else{
    InOutTimeVect <- c()
    InOutSexVect <- c()
    InOutEvtVect <- c() 
  }
  #for Around and outside feeding: get average time
  if(nrow(Adf)>0){
    #if around exists
    #browser()
  Adf$MeanTime <- (Adf$StartTime+Adf$EndTime)/2
  ATimeVect <- Adf$MeanTime
  ASexVect <- Adf$Sex
  }else{#else just make empty vectors
    ATimeVect <- c()
    ASexVect <- c()
  }
  
  if(nrow(Odf)>0){
    #if outside feeding exists
    Odf$MeanTime <- (Odf$StartTime+ Odf$EndTime)/2
    OTimeVect <- Odf$MeanTime
    OSexVect <- Odf$Sex
  }else{
    OTimeVect <- Odf$MeanTime
    OSexVect <- Odf$Sex
  }
  
  mergedf <- data.frame(Time=c(InOutTimeVect, ATimeVect,OTimeVect), 
                        Sex=c(InOutSexVect, ASexVect, OSexVect),
                        EventDes=c(InOutEvtVect,rep("Around", length(ATimeVect)),rep("OutsideFeeding", length(OTimeVect))))
  # Short$Time <- NA
  # Short$Sex <- NA
  # Short$EventDes <- NA
  
  ClosestOutput <- FindClosest(Short,mergedf) 
  Short <- ClosestOutput[[1]]
  Prob <- ClosestOutput[[2]]
  
  write.csv(Short, file=paste("../MeerkatOutput/",FileName,"/FramesShortCoded.csv", sep=""))
  
  #Convert Short back to Long
  Long <- read.csv(paste("../MeerkatOutput/",FileName,"/FramesLong.csv", sep=""))
  
  ShortMerge <- Short[,names(Short) %in% c("Event","Sex","EventDes")]
  
  #removes duplicates:
  #added if else, if there are no errors, will have integer(0) error
  if(sum(duplicated(ShortMerge$Event))>0){
    ShortMerge <- ShortMerge[-which(duplicated(ShortMerge$Event)),]
  }else{}
  
  require(dplyr)
  NewLong <- full_join(Long,ShortMerge)
  #used dplyr join instead, because merge shuffles the order
  #NewLong <- merge(Long,ShortMerge,by="Event", all=T)
  
  ###NEWLY ADDED CHUNK####
  #change behaviour codes to numbers:
  NewLong <- NewLong %>% mutate(EventDes= ifelse(EventDes=="In", 1,EventDes)) %>%
    mutate(EventDes= ifelse(EventDes=="Out", 2,EventDes)) %>%
    #mutate(EventNum= ifelse(EventDes=="OutsideFeeding", 3,EventDes)) %>%
    mutate(EventDes= ifelse(is.na(EventDes)|EventDes=="Around"|EventDes=="OutsideFeeding", 0,EventDes))
  
  ####
  
  
  write.csv(NewLong, file=paste("../MeerkatOutput/",FileName,"/FramesLongCoded.csv", sep=""))
  
  return(Prob)
}
