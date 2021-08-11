###Calculate Meerkat Return Rate from 8 UG vids
rm(list=ls())
library(tidyverse)
library(readxl)
library(caret)

RealData <- read.csv("../Data/MasterTraining.csv")
UGData <- read_excel("../Data/ParentalBehaviour_Summary.xlsx")


Videos <- list.files("../MeerkatOutputUG/")
MeerkatReturn <- data.frame(matrix(ncol=4, nrow=length(Videos)))
names(MeerkatReturn) <- c("Video", "MeerkatReturnRate","UndergradRate","MaskRCNNRate")

AllEvents <- data.frame(matrix(ncol=7))
names(AllEvents) <- c("Event","PredictSex", "Sex","Behav","VGGSex", "CodedSex", "CodedBehav")

for(i in 1:length(Videos)){
  ##Meerkat Return Rate
  Vid <- Videos[i]
  VidCode <- substr(Vid, 1,6)
  RealSub <- filter(RealData,RealData$DVDNumber==VidCode) %>%
    select(c(StartTime,EndTime, State,Sex))
  
  LongDF<- gather(RealSub, TimeType, Time, StartTime:EndTime)%>%
    mutate(State= ifelse(State=="I" & TimeType=="EndTime", "OUT", State))%>%
    mutate(State=ifelse(State=="I", "IN", State)) %>%
    filter(State!= "A")
  
  Manual <- read.csv(paste("../MeerkatOutputUG/",Vid,"/FramesShortSexPredict_AC.csv",sep=""))%>%
    select(c(MeanTime, Behav,Sex)) %>%
    filter(Behav %in% c("IN", "OUT", "OF"))
  
  ##Calculate return Rate
  ManualNum <- nrow(Manual)
  
  ##RealData Number:
  if(sum(LongDF$State %in% c("O"))>1){
    #there are feeding from outside
    RealDataNum <- nrow(LongDF) - (sum(LongDF$State %in% c("O"))/2) #minus the number of OFs divided by 2, each OF is just 1 event
  }else{
    RealDataNum <- nrow(LongDF)
  }
  
  ReturnRate <-ManualNum/RealDataNum
  print(ReturnRate)
  
  ##UG Return Rates
  UGSub <- subset(UGData, UGData$Video==VidCode)
  Observers <- unique(UGSub$Observer)
  RateVect <- c()
  for(j in 1:length(Observers)){
    ObSub <- subset(UGSub, UGSub$Observer==Observers[j])
    Rate <- (sum(ObSub$TotalNoIN*2)+sum(ObSub$TotalNoOF,na.rm = T))/RealDataNum
    RateVect <- c(RateVect,Rate)
  }
  UGRate <- mean(RateVect)
  
  ### MaskRCNN Return Rate
  Annotated <-  Manual <- read.csv(paste("../MeerkatOutputUG/",Vid,"/FramesShortSexPredict_AC.csv",sep=""))%>%
    filter(Behav %in% c("IN", "OUT", "A"))
  MaskReturn <- 1-(sum(is.na(Annotated$PredictSex))/ nrow(Annotated))
  
  MeerkatReturn[i,] <- c(VidCode,ReturnRate,UGRate, MaskReturn)
  
  ##Sex Estimate Confusion Matrix
  AnnotatedShort <- Annotated %>% select(Event,PredictSex, Sex,Behav)
  VGGDF <-read.csv(paste("../MeerkatOutput/",Vid, "/FramesShortSexPredictVGG.csv", sep=""))%>%
    mutate(VGGSex = PredictSex)%>%
    select(c(Event,VGGSex))%>%
    right_join(AnnotatedShort)
  
  ###see auto match event accuracy
  ShortCoded <- read.csv(paste("../MeerkatOutputUG/",Vid,"/FramesShortCoded.csv", sep=""))%>%
    mutate(CodedSex = Sex)%>%
    mutate(CodedBehav = EventDes)%>%
    select(Event, CodedBehav, CodedSex)
    
  VGGDF <- left_join(VGGDF, ShortCoded)
  AllEvents <- rbind(AllEvents,VGGDF)
    
}


write.csv(MeerkatReturn, file="../Data/MeerkatReturn.csv")

#Return Rates for Table 4
MeerkatReturn$MeerkatReturnRate <- as.numeric(MeerkatReturn$MeerkatReturnRate)
MeerkatReturn$UndergradRate <- as.numeric(MeerkatReturn$UndergradRate)
MeerkatReturn$MaskRCNNRate <- as.numeric(MeerkatReturn$MaskRCNNRate)

#meerkat rates
median(MeerkatReturn$MeerkatReturnRate)
max(MeerkatReturn$MeerkatReturnRate)
min(MeerkatReturn$MeerkatReturnRate)

#undergrad rates
median(MeerkatReturn$UndergradRate)
max(MeerkatReturn$UndergradRate)
min(MeerkatReturn$UndergradRate)

#MaskRCNN Rates
median(MeerkatReturn$MaskRCNNRate)
max(MeerkatReturn$MaskRCNNRate)
min(MeerkatReturn$MaskRCNNRate)

##Confusion matrix for sex accuracy:
AllEvents$Match <- AllEvents$Sex==AllEvents$PredictSex
sum(AllEvents$Match, na.rm = T)/nrow(AllEvents)

AllEvents$VGGMatch <- AllEvents$VGGSex==AllEvents$Sex
sum(AllEvents$VGGMatch, na.rm = T)/nrow(AllEvents)

confusionMatrix(as.factor(AllEvents$PredictSex), as.factor(AllEvents$Sex))
confusionMatrix(as.factor(AllEvents$VGGSex), as.factor(AllEvents$Sex))

##accuracy of coded data
CodedData <- AllEvents %>% drop_na(CodedBehav)%>%
  filter(CodedBehav != "OutsideFeeding")%>%
  mutate(CodedBehav = case_when(CodedBehav == "Around" ~ "A",
                                CodedBehav == "In" ~ "IN", 
                                CodedBehav == "Out"~ "OUT"))%>%
  mutate(CodedMatch = CodedSex == Sex & CodedBehav == Behav)

sum(CodedData$CodedMatch)/nrow(CodedData)

