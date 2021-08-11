##Validate Model on Test Datasets
rm(list=ls())
library(tidyverse)
library(caret)

VidInfo <- read.csv("../Data/VideoInfo.csv")
Test <- subset(VidInfo, VidInfo$Type=="Test")
Test$CNNRate <- NA
Test$VGGRate <- NA
AllEvents <- data.frame(matrix(nrow = 0, ncol = 7))
names(AllEvents) <- c("Sex", "PredictSex","VGGPredict", "CNNMatch","VGGMatch")

#valdiate MaskRCNN results
for(i in 1:nrow(Test)){
  Vid <- Test$FileName[i]
  CodedShort <- read.csv(paste("../MeerkatOutput/",Vid, "/FramesShortCoded.csv", sep=""))
  SexDF <-read.csv(paste("../MeerkatOutput/",Vid, "/FramesShortSexPredict.csv", sep="")) %>%
    select(c(Event,PredictSex))
    
  VGGDF <-read.csv(paste("../MeerkatOutput/",Vid, "/FramesShortSexPredictVGG.csv", sep=""))%>%
    mutate(VGGPredict = PredictSex)%>%
    select(c(Event,VGGPredict))

  CodedShort <-left_join(CodedShort, SexDF) %>%
    left_join(VGGDF, by="Event") %>%
    drop_na(Sex) %>%
    mutate(CNNMatch = Sex ==PredictSex )%>%
    mutate(VGGMatch = Sex ==VGGPredict)
  
  VGGRate <- sum(CodedShort$VGGMatch, na.rm = T)/ nrow(CodedShort)
  CNNRate <-sum(CodedShort$CNNMatch, na.rm=T)/ nrow(CodedShort)
  
  #rate with NA removed, remove error from MAskRCNN
  NoNA <- drop_na(CodedShort)
  VGGRateNA <- sum(CodedShort$VGGMatch, na.rm = T)/ nrow(NoNA)
  CNNRateNA <-sum(CodedShort$CNNMatch, na.rm=T)/ nrow(NoNA)
  
  Test[i,"CNNRate"] <- CNNRate
  Test[i,"VGGRate"] <- VGGRate
  Test[i, "CNNRateNA"] <- CNNRateNA
  Test[i, "VGGRateNA"] <- VGGRateNA
  
  ShortMini <- CodedShort %>% select(c(Sex, PredictSex,VGGPredict, CNNMatch,VGGMatch))
  AllEvents <- rbind(AllEvents, ShortMini)
  
  }

RemoveNAMask <- drop_na(AllEvents,VGGMatch)
median(Test$VGGRate, na.rm = T)
median(Test$CNNRate, na.rm = T)
sum(AllEvents$CNNMatch, na.rm = T)/nrow(AllEvents)
sum(AllEvents$VGGMatch, na.rm=T)/ nrow(AllEvents)

#with error from MAskRCNN removed:
median(Test$VGGRateNA, na.rm = T)
median(Test$CNNRateNA, na.rm = T)
sum(AllEvents$CNNMatch, na.rm = T)/nrow(RemoveNAMask)
sum(AllEvents$VGGMatch, na.rm=T)/ nrow(RemoveNAMask)

##confusion matrix
confusionMatrix(as.factor(AllEvents$PredictSex), as.factor(AllEvents$Sex))
confusionMatrix(as.factor(AllEvents$VGGPredict), as.factor(AllEvents$Sex))

211+156+186+122
nrow(drop_na(AllEvents, VGGPredict))/nrow(AllEvents)



