###Get correlation with meerkat data
library(tidyverse)
library(readxl)

rm(list=ls())
setwd("~/Documents/SparrowVis/Analysis/Code")

Visits <- read_excel("../Data/Raw nest visit data_2021-04-16.xlsx")
VideoInfo <- read_excel("../Data/DVD Information_2021-04-07.xlsx")
DVDSum <- read_excel("../Data/DVD recordings summary_2021-04-07.xlsx") %>%
  select(c("DVDRef","EffectiveLength"))
Videos <- list.files("../MeerkatOutput/")

#get video code from file names
VideoCode <- sapply(Videos,function(x) strsplit(x,split="_")[1])
VideoCode <- unlist(lapply(VideoCode, function(x) x[[1]]))

#preallocate data frame
Freq <- data.frame(matrix(ncol=7, nrow=length(VideoCode)))
colnames(Freq) <- c("Video", "DVDRef","MeerkatFreq","Meerkat90Freq", "FeedFreq", "AroundFreq", "MeerkatLength")

for(i in 1:length(VideoCode)){
  Freq[i,"Video"] <- VideoCode[i]
  #get video ref for that video code
  VidRef <- as.numeric(VideoInfo[which(VideoInfo$DVDNumber==VideoCode[i]),"DVDRef"])
  Freq[i, "DVDRef"] <- VidRef
  
  sub <- subset(Visits, Visits$DVDRef==VidRef)
  
  FeedSub <- subset(sub, sub$State %in% c("I","O")) #only feeding
  Freq[i,"FeedFreq"] <- nrow(FeedSub)
  Freq[i,"AroundFreq"] <- nrow(sub)
  
  #meerkat:
  Short <- read.csv(paste("../MeerkatOutput/",Videos[i],"/FramesShort.csv", sep=""))
  Short90 <- subset(Short,Short$MeanTime<90)
  Freq[i,"MeerkatFreq"]<- nrow(Short)
  Freq[i,"Meerkat90Freq"] <- nrow(Short90)
  
  ##effective lengths
  Freq[i,"MeerkatLength"] <-90-Short[1,"MeanTime"]
  
}

Freq <- Freq %>% left_join(DVDSum, by="DVDRef")


##plots
cor.test(Freq$FeedFreq, Freq$MeerkatFreq)
plot(Freq$FeedFreq,Freq$MeerkatFreq, main="FeedingFrequency and Meerkat, cor = 0.55")
cor.test(Freq$AroundFreq, Freq$MeerkatFreq)
plot(Freq$AroundFreq, Freq$MeerkatFreq, main="AroundFrequency and Meerkat, cor = 0.59")

##90 freq
cor.test(Freq$FeedFreq, Freq$Meerkat90Freq)
plot(Freq$FeedFreq,Freq$Meerkat90Freq, main="FeedingFrequency and Meerkat, cor = 0.54")
cor.test(Freq$AroundFreq, Freq$Meerkat90Freq)
plot(Freq$AroundFreq, Freq$Meerkat90Freq, main="AroundFrequency and Meerkat, cor = 0.58")

##feed rates
Freq$MeerkatRate <- Freq$Meerkat90Freq/Freq$MeerkatLength
Freq$FeedRate <- Freq$FeedFreq/Freq$EffectiveLength
Freq$AroundRate <- Freq$AroundFreq/Freq$EffectiveLength

cor.test(Freq$FeedRate, Freq$MeerkatRate)
plot(Freq$FeedRate,Freq$MeerkatRate, main="FeedingRate and MeerkatRate (Per Hour), cor = 0.53")
cor.test(Freq$AroundRate, Freq$MeerkatRate)
plot(Freq$AroundRate, Freq$MeerkatRate, main="AroundRate and MeerkatRate (Per Hour), cor = 0.58")



##z transformed
plot(scale(Freq$FeedFreq),scale(Freq$MeerkatFreq), main="z-transformed Feeding x Meerkat")
plot(scale(Freq$AroundFreq), scale(Freq$MeerkatFreq),main="z-transformed Arouund x Meerkat")

# summary(lm(scale(FeedFreq)~scale(MeerkatFreq), data=Freq))
# summary(lm(FeedFreq~MeerkatFreq, data=Freq))
# plot(Freq$FeedFreq, Freq$MeerkatFreq*0.14838)

##### Second validate: for 2013 vids only #####
Visits <- read_excel("../Data/Raw nest visit data_2021-04-16.xlsx")
VideoInfo <- read_excel("../Data/DVD Information_2021-04-07.xlsx")
DVDSum <- read_excel("../Data/DVD recordings summary_2021-04-07.xlsx") %>%
  select(c("DVDRef","EffectiveLength"))
Videos <- list.files("../MeerkatOutput/")

#get video code from file names
rm(list=ls())

Visits <- read_excel("../Data/Raw nest visit data_2021-04-16.xlsx")
VideoInfo <- read_excel("../Data/DVD Information_2021-04-07.xlsx")
DVDSum <- read_excel("../Data/DVD recordings summary_2021-04-07.xlsx") %>%
  select(c("DVDRef","EffectiveLength"))
Videos <- list.files("../MeerkatOutput/")
Videos2013 <- subset(Videos, startsWith(Videos,"VM"))


VideoCode <- sapply(Videos2013,function(x) substr(x,1,6))

#preallocate data frame
Freq <- data.frame(matrix(ncol=7, nrow=length(VideoCode)))
colnames(Freq) <- c("Video", "DVDRef","MeerkatFreq","MeerkatPrunedFreq", "FeedFreq", "AroundFreq", "MeerkatLength")

for(i in 1:length(VideoCode)){
  Freq[i,"Video"] <- VideoCode[i]
  #get video ref for that video code
  VidRef <- as.numeric(VideoInfo[which(VideoInfo$DVDNumber==VideoCode[i]),"DVDRef"])
  Freq[i, "DVDRef"] <- VidRef
  
  sub <- subset(Visits, Visits$DVDRef==VidRef)
  
  FeedSub <- subset(sub, sub$State %in% c("I","O")) #only feeding
  Freq[i,"FeedFreq"] <- nrow(FeedSub)
  Freq[i,"AroundFreq"] <- nrow(sub)
  
  #meerkat:
  Short <- read.csv(paste("../MeerkatOutput/",Videos2013[i],"/FramesShortSexPredict.csv", sep=""))
  ifelse(nrow(Short)==0, next, print(i))
  ShortPruned <- drop_na(Short, "PredictSex")
  Freq[i,"MeerkatFreq"]<- nrow(Short)
  Freq[i,"MeerkatPrunedFreq"] <- nrow(ShortPruned)
  
  ##effective lengths
  Freq[i,"MeerkatLength"] <-90-Short[1,"MeanTime"]
  
}

Freq <- Freq %>% left_join(DVDSum, by="DVDRef")

##correlation tests

cor.test(Freq$MeerkatFreq, Freq$FeedFreq)
plot(Freq$FeedFreq, Freq$MeerkatFreq)
cor.test(Freq$MeerkatPrunedFreq,Freq$FeedFreq)
plot(Freq$FeedFreq,Freq$MeerkatPrunedFreq)
