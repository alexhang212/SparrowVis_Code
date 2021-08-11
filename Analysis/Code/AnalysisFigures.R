##Make forest plots for MCMC results
rm(list=ls())
graphics.off()
library(tidyverse)
library(ggplot2)
library(MCMCglmm)
library(ggpubr)

ModelResults <-data.frame(matrix(ncol=8))
names(ModelResults) <- c("Type", "EffectType","EffectName","Response","ProvType",
                         "Mode", "upper","lower")

##Create dataframe For brood results
Vect <- 1:12
TypeVect <- c(rep("Manual",6),rep("Meerkat",6))
ResVect <- rep(c("Recruit","Fledge"),6)
ProvVect <- rep(c("Avg","Avg","Day7","Day7","Day11","Day11"),2)
for(i in 1:length(Vect)){
 # browser()
  load(paste("../FinalResults/MCMCBroodOut_",Vect[i],".rda", sep=""))

  ##Fixed Effects
  Mode <- posterior.mode(Model$Sol)
  FixedInterval <- HPDinterval(Model$Sol)
  FixedDF <- data.frame(cbind(FixedInterval, Mode))
  FixedDF$EffectType <- "Fixed Effects"
  FixedDF$EffectName <- rownames(FixedDF)
  
  ##Random Effects
  Mode <- posterior.mode(Model$VCV)
  RandInterval <- HPDinterval(Model$VCV)
  RandDF <- data.frame(cbind(RandInterval, Mode))
  RandDF$EffectType <- "Random Effects"
  RandDF$EffectName <- rownames(RandDF)
  
  ##Merge:
  OutDF <- rbind(FixedDF, RandDF)
  OutDF$Type <- TypeVect[i]
  OutDF$Response <- ResVect[i]
  OutDF$ProvType <- ProvVect[i]
  
  ModelResults <- rbind(ModelResults,OutDF)
}

ModelResults <- ModelResults %>% mutate(EffectName= 
                                          ifelse(startsWith(EffectName, "z_"),"Provision Rate",EffectName)) %>%
                mutate(Significance = ifelse(lower<0 & upper>0, "Not Significant", "Significant")) %>%
                mutate(EffectName = case_when(EffectName == "poly(HatchBroodSize, 2)2" ~ "Hatch Brood Size^2",
                                              EffectName=="HatchBroodSize" ~ "Hatch Brood Size",
                                              EffectName == "poly(HatchDateCode, 2)2" ~ "Hatch Date^2",
                                              EffectName == "poly(HatchDateCode, 2)1" ~ "Hatch Date",
                                              EffectName == "MaleAge" ~ "Male Age",
                                              EffectName == "FemaleAge" ~ "Female Age",
                                              EffectName == "units" ~ "Residuals",
                                              EffectName == "(Intercept)" ~ "Intercept",
                                              TRUE ~ EffectName))%>%
                drop_na()%>%
                mutate(Response = ifelse(Response == "Recruit", "B. Number of Recruits",
                                         ifelse(Response == "Fledge", "A. Number of Fledgelings", Response)))%>%
  mutate(EffectName = ifelse(grepl("Rate",EffectName), "Provision Rate", EffectName))
  ##### Above is temp need to rerun z_transformed data


## Trying putting it together
ForestAll <- function(Response){
data <- ModelResults %>% filter(EffectType == "Fixed Effects") %>%
  mutate(TypeComb = paste(Type, "-",ProvType, sep=""))
data <- data[which(data$Response==Response),]

Plot <- ggplot(data=data, aes(x=factor(EffectName, level = rev(unique(EffectName))), y=Mode, ymin=lower,ymax=upper, col=TypeComb))+theme_bw()+
  geom_pointrange(size=0.5, position = position_dodge(width = 1), aes(shape=Significance)) +
  scale_shape_manual(values=c(19,1))+
  scale_color_manual(values= c("#5089C6","#035397", "#001E6C","#A73489","#FF3D68","#FAAD80"))+
  geom_hline(yintercept=0, lty=2)+
  coord_flip() +
  labs(y="Posterior Mode", x= "Fixed Effects",title=Response,color="Model")+
  theme(aspect.ratio = 3)

return(Plot)

}

RecPlot <- ForestAll("B. Number of Recruits")
FledPlot <- ForestAll("A. Number of Fledgelings")

FinalPlot <- ggarrange(FledPlot,RecPlot, ncol=2, nrow=1, common.legend = T, legend = "right")
FinalPlot

ggsave(FinalPlot, file="../../Validation/Plots/ForestPlot.png", width = 9, height = 10)

#### Individual Results
IndivResults <-data.frame(matrix(ncol=8))
names(IndivResults) <- c("Type", "EffectType","EffectName","Response","ProvType",
                         "Mode", "upper","lower")

##Create dataframe For indiv results
Vect <- 1:36
TypeVect <- c(rep("Manual",18), rep("Meerkat",18))
ResVect <- rep(c("Day12 Mass", "Survival till Fledge", "Longevity", 
                 "Lifetime Recruits", "Recruited or not", "First Breed Age"),6)
ProvVect <- rep(c(rep("Avg",6),rep("Day7",6),rep("Day11",6)),2)
for(i in 1:length(Vect)){
  # browser()
  load(paste("../FinalResults/IndivModel_",Vect[i],".rda", sep=""))
  
  ##Fixed Effects
  Mode <- posterior.mode(Model$Sol)
  FixedInterval <- HPDinterval(Model$Sol)
  FixedDF <- data.frame(cbind(FixedInterval, Mode))
  FixedDF$EffectType <- "Fixed Effects"
  FixedDF$EffectName <- rownames(FixedDF)
  
  ##Random Effects
  Mode <- posterior.mode(Model$VCV)
  RandInterval <- HPDinterval(Model$VCV)
  RandDF <- data.frame(cbind(RandInterval, Mode))
  RandDF$EffectType <- "Random Effects"
  RandDF$EffectName <- rownames(RandDF)
  
  ##Merge:
  OutDF <- rbind(FixedDF, RandDF)
  OutDF$Type <- TypeVect[i]
  OutDF$Response <- ResVect[i]
  OutDF$ProvType <- ProvVect[i]
  
  IndivResults <- rbind(IndivResults,OutDF)
}

IndivResultsAll <- IndivResults
IndivResults <- subset(IndivResults, IndivResults$Type=="Manual")

IndivResults <- IndivResults %>% mutate(EffectName= 
                                          ifelse(startsWith(EffectName, "z_"),"Provision Rate",EffectName)) %>%
  mutate(Significance = ifelse(lower<0 & upper>0, "Not Significant", "Significant")) %>%
  mutate(EffectName = case_when(EffectName == "poly(HatchBroodSize, 2)2" ~ "Hatch Brood Size^2",
                                EffectName=="HatchBroodSize" ~ "Hatch Brood Size",
                                EffectName == "poly(HatchDateCode, 2)2" ~ "Hatch Date^2",
                                EffectName == "poly(HatchDateCode, 2)1" ~ "Hatch Date",
                                EffectName == "MaleAge" ~ "Male Age",
                                EffectName == "FemaleAge" ~ "Female Age",
                                EffectName == "units" ~ "Residuals",
                                EffectName == "(Intercept)" ~ "Intercept",
                                TRUE ~ EffectName))%>%
  drop_na()


## Plot Forest
PlotForest <- function(Response){
  data <- IndivResults %>% filter(EffectType == "Fixed Effects")
  data <- data[which(data$Response==Response),]
  
  Plot <- ggplot(data=data, aes(x=factor(EffectName, 
                                         level = rev(unique(EffectName))), 
                                y=Mode, ymin=lower,ymax=upper,
                                col=factor(ProvType, level=c("Avg", "Day7","Day11"))))+theme_bw()+
    geom_pointrange(size=0.5, position = position_dodge(width = 1), aes(shape=Significance)) +
    scale_shape_manual(values=c(19,1))+
    geom_hline(yintercept=0, lty=2)+
    coord_flip() +
    labs(y="Posterior Mode", x= "Fixed Effects",title=Response,color="Model" )+
    theme(aspect.ratio = 1)
  
  return(Plot)
  
}

Mass12Plot<- PlotForest("Day12 Mass")
LongevityPlot <- PlotForest("Longevity")
FledgePlot <- PlotForest("Survival till Fledge")
RecruitedPlot <- PlotForest("Recruited or not")


FinalPlot <- ggarrange(Mass12Plot,LongevityPlot,FledgePlot,RecruitedPlot, ncol=2, nrow=2, common.legend = T, legend = "bottom")
FinalPlot
ggsave(FinalPlot, file="../../Validation/Plots/ForestPlotIndiv.png", width = 11, height = 9)



#output mode results to allow copy and paste for Appendix 2
BroodModelOut <- ModelResults %>%
  mutate(Effect = paste(signif(Mode,2), " (", signif(lower,2), " - ", signif(upper,2),")", sep=""))%>%
  select(- c("Mode","upper","lower"))
write.csv(BroodModelOut, "../Data/BroodModelResults.csv")

IndivModelOut <- IndivResultsAll %>%
  mutate(Effect = paste(signif(Mode,2), " (", signif(lower,2), " - ", signif(upper,2),")", sep=""))%>%
  select(- c("Mode","upper","lower"))
write.csv(IndivModelOut, "../Data/IndivModelResults.csv")


##Alternative Figs
MasterBrood <- read.csv("../Data/FinalBroodData.csv") %>%
  select(c(z_AvgMeerkatRate,z_AvgFeedRate,  FledgeBroodSize,Recruits))%>%
  gather(Type, ProvisionRate, z_AvgMeerkatRate:z_AvgFeedRate)%>%
  drop_na(ProvisionRate)
  
FledgeData <- drop_na(MasterBrood, FledgeBroodSize)
Fig4a <- ggplot(FledgeData, aes(x=as.factor(FledgeBroodSize),y=ProvisionRate, fill=Type))+theme_bw()+
geom_boxplot()+coord_flip() +labs(title="A", x="Number of Fledglings", y="Provision Rate (z-tranformed)")+
theme(aspect.ratio = 1) +scale_fill_manual(values=c("#488f31","#ff9e59"), labels=c("Average Feed Rate", "Average Meerkat Rate"))
Fig4a

RecruitData <- drop_na(MasterBrood,Recruits)
Fig4b <- ggplot(RecruitData, aes(x=as.factor(Recruits),y=ProvisionRate, fill=Type))+theme_bw()+
  geom_boxplot()+coord_flip() +labs(title="B", x="Number of Recruits", y="Provision Rate (z-tranformed)")+
  theme(aspect.ratio = 1)+scale_fill_manual(values=c("#488f31","#ff9e59"), labels=c("Average Feed Rate", "Average Meerkat Rate"))
Fig4b


FinalFig4 <- ggarrange(Fig4a,Fig4b, ncol=2, nrow=1, common.legend = T, legend = "bottom")
FinalFig4
ggsave(FinalFig4, file="../../Validation/Plots/ProvisiontoNum.png", width = 11, height = 5)

