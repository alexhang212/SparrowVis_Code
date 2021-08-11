## validation plots for LRCN Networks
rm(list=ls())
library(ggplot2)


OverallAcc <- read.csv("../Data/TestDataAccuracy.csv")
SexAcc <- read.csv("../Data/SexEventAccuracy-BestModelSex-5.csv")
BehavAcc <- read.csv("../Data/SexEventAccuracy-BestModelBehav-2.csv")


UnqVid <- unique(SexAcc$FileName)
for(i in 1:length(UnqVid)){
  SexSub <- subset(SexAcc,SexAcc$FileName == UnqVid[i])
  BehavSub <- subset(BehavAcc, BehavAcc$FileName==UnqVid[i])
  Sex <- sum(SexSub$match)/nrow(SexSub)
  Behav <- sum(BehavSub$match)/nrow(BehavSub)
  
  OverallAcc[which(OverallAcc$FileName==UnqVid[i]),c("SexAccuracy","BehavAccuracy")] <- c(Sex,Behav)
  
}
median(OverallAcc$SexAccuracy)
median(OverallAcc$BehavAccuracy)

write.csv(OverallAcc, file="../Data/TestDataAccuracy.csv")

## Sex:
boxplot(SexAcc$SexPredict~SexAcc$Actual, ylim=c(0,1))
plot(SexAcc$SexPredict~jitter(SexAcc$Actual,0.5), ylim=c(0,1))


Male <- subset(SexAcc,SexAcc$Actual==1)
Female <- subset(SexAcc,SexAcc$Actual==0)

MalPlot <- hist(Male$SexPredict, plot=F)
FemPlot <- hist(Female$SexPredict, plot=F)

plot(MalPlot, col="#00FF0033", xlim=c(0,1),ylim=c(0,110), main="SexPredictions", xlab="Prediction Confidence")
plot(FemPlot,col="#FF000033", xlim=c(0,1), add = T )
#male is green, female is red

boxplot(SexAcc$SexPredict~SexAcc$FileName, ylim=c(0,1), main="Variability of Predictions")
aggregate(SexAcc$SexPredict, by=list(FileName=(SexAcc$FileName)), FUN=sd)
VN0813 <- subset(SexAcc,SexAcc$FileName=="VN0813_VP11_LF2_20140802")

#ROC curve:
UnqFile <- unique(SexAcc$FileName)
TruePosVect<- rep(NA, length(UnqFile))
FalsePosVect <- rep(NA, length(UnqFile))

for(i in seq_along(along.with = UnqFile)){
  Sub <- subset(SexAcc, SexAcc$FileName==UnqFile[i])
  MalSub <- subset(Sub,Sub$Actual==1)
  FemSub <- subset(Sub,Sub$Actual==0)
  
  TruPos <- sum(MalSub$match)/nrow(MalSub)
  FalsePos <- sum(FemSub$match==FALSE)/nrow(FemSub) 
  
  TruePosVect[i] <- TruPos
  FalsePosVect[i] <- FalsePos
  
}

plot(FalsePosVect,TruePosVect)
lines(0:1,0:1)
#y axis: given its male, how much does it predicts its male
# x axis: given its female, how much does it predict its male

#DO THIS FOR TRAINING DATA
UnqFile <- unique(SexAcc$FileName)
PredictVect <- rep(NA, length(UnqFile))
RatioVect <- rep(NA, length(UnqFile))
AccVect <- rep(NA, length(UnqFile))

for(i in seq_along(along.with = UnqFile)){
  Sub <- subset(SexAcc, SexAcc$FileName==UnqFile[i])
  MedPredict <- median(Sub$SexPredict)
  SexRatio <- sum(Sub$Actual==1)/ nrow(Sub)
  Accuracy <- sum(Sub$match)/nrow(Sub)
  
  PredictVect[i] <- MedPredict
  RatioVect[i] <- SexRatio
  AccVect[i] <- Accuracy
  
}

plot(RatioVect, PredictVect)


###



#Behaviour:
InSub <- subset(BehavAcc,BehavAcc$Actual==1)
OutSub <- subset(BehavAcc,BehavAcc$Actual==2)

hist(InSub$X2, xlim=c(0,1))

Plot1 <- hist(InSub$X2, plot=FALSE)
Plot2 <- hist(InSub$X3, plot=FALSE)

plot(Plot1, col="#00FF0033", xlim=c(0,1), main="IN Behaviour", xlab="Prediction Confidence")
plot(Plot2,col="#FF000033", xlim=c(0,1), add = T )
#Green is correct classification, red is wrong

Plot3 <- hist(OutSub$X2, plot=FALSE)
Plot4 <- hist(OutSub$X3, plot=FALSE)

plot(Plot4, col="#00FF0033", xlim=c(0,1), main="OUT Behaviour", xlab="Prediction Confidence")
plot(Plot3,col="#FF000033", xlim=c(0,1), add = T )
#Green is correct classification, red is wrong

##more plots:
BehavAcc$IN <- ifelse(BehavAcc$Actual==1, 1,0)
BehavAcc$OUT <- ifelse(BehavAcc$Actual==2, 1,0)
BehavAcc$A <- ifelse(BehavAcc$Actual==0, 1,0)

plot(jitter(BehavAcc$A,0.2),BehavAcc$X1, ylim=c(0,1), main="Around")
plot(jitter(BehavAcc$IN,0.2),BehavAcc$X2, ylim=c(0,1), main="IN")
plot(jitter(BehavAcc$OUT,0.2),BehavAcc$X3, ylim=c(0,1), main="OUT")
