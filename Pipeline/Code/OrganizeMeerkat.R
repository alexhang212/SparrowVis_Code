## Organize all meerkat output files into csv with Meerkat frequency and video naem
rm(list=ls())

# Video <- "V0115_LM28_V6I_20180520"

Videos <- list.files("../MeerkatOutput/")
VideoCode <- sapply(Videos, function(x) substr(x, 1,6))


DupCode <- VideoCode[which(duplicated(VideoCode))]
AllVids <- Videos[-which(VideoCode %in% DupCode)] #all vids that are not duplicated

##for non duplicated videos
GetMeerkatFreq <- function(Video){
  Short <- read.csv(paste("../MeerkatOutput/",Video,"/FramesShort.csv", sep=""))
  Sub90 <- subset(Short,Short$MeanTime<90)
  Freq <- nrow(Sub90)
  Time <- 90 - Sub90$MeanTime[1]
  return(c(Video,Freq,Time))
}

FreqList <- lapply(AllVids, GetMeerkatFreq)
FreqDF <- data.frame(matrix(unlist(FreqList), ncol=3, byrow=T))
names(FreqDF) <- c("Video","MeerkatFreq","MeerkatTime" )


## for duplicated vids:
DupFreq <- data.frame(matrix(nrow=length(DupCode), ncol =3))
names(DupFreq) <- c("Video","MeerkatFreq", "MeerkatTime")

for(i in 1:length(DupCode)){
  Vids <- sort(Videos[which(VideoCode %in% DupCode[i])])
  if(length(Vids)!=2){
    print("Something Wrong");print(i)
  }
  Short1 <- read.csv(paste("../MeerkatOutput/",Vids[1],"/FramesShort.csv", sep=""))
  Short2 <- read.csv(paste("../MeerkatOutput/",Vids[2],"/FramesShort.csv", sep=""))
  
  ##exception for VP0107, no events in first video
  if(DupCode[i]=="VP0107"){
    Short2$RealTime <- Short2$MeanTime+49.3
    Freq <- nrow(Short1) + nrow(Short2) 
    Time <- 90-Short2$MeanTime[1]
    DupFreq[i,"Video"] <- DupCode[i]
    DupFreq[i, "MeerkatFreq"] <- Freq
    DupFreq[i,"MeerkatTime"]<- Time
    next
  }
  Short2$RealTime <- Short2$MeanTime+Short1$MeanTime[nrow(Short1)]
  Short1Sub <- subset(Short1,Short1$MeanTime<90)
  Short2Sub <- subset(Short2,Short2$MeanTime<90)
  
  Freq <- nrow(Short1Sub) + nrow(Short2Sub) 
  Time <- 90-Short1$MeanTime[1]
  
  DupFreq[i,"Video"] <- DupCode[i]
  DupFreq[i, "MeerkatFreq"] <- Freq
  DupFreq[i,"MeerkatTime"]<- Time
}


FinalDF <- rbind(FreqDF, DupFreq)
write.csv(FinalDF, "../Data/MeerkatFreq.csv")
