### Producing all figures for thesis writeup
library(ggplot2)
library(tidyverse)
rm(list=ls())


#### Figure 1: Feed Rates by Brood Age ####
ProvDF <- read.csv("../Data/ProvisionFrequency.csv") %>%
  select(c(DVDRef, ProvFreq))
DVDInfo <- read.csv("../Data/DVDInfo.csv") %>%
  select(c(DVDRef,Age))

Rates <- left_join(ProvDF, DVDInfo)%>%
  drop_na(c("ProvFreq","Age"))%>%
  mutate(Type=case_when(
    Age < 6 | Age>11 ~ "Removed",
    Age > 5 & Age<9 ~ "Day 7",
    Age >8 & Age< 12 ~ "Day 11"
  ))%>%
  mutate(Type=factor(Type, levels=c("Day 7", "Day 11", "Removed")))

Fig1 <- ggplot(Rates, aes(x=jitter(Age), y=ProvFreq, col=Type))+theme_bw()+
  geom_point()+ scale_color_manual(name="Category", values=c("#064BFF","#DC267F","Black"))+
  scale_x_continuous(name="Brood Age (Days)", limits=c(0,13),breaks=1:13)+
  scale_y_continuous(name="Feed Rate (Feeds per hour)")+
  guides(colour=guide_legend(override.aes = list(size=3)))

Fig1

ggsave("../Plots/Figure1.png", plot=Fig1)


##Figure 2: done in powerpoint

##Figure 3:Meerkat to FeedRate Correlation ###
ProvRate <- read.csv("../Data/MasterProvisionRates.csv")

Fig3 <- ggplot(ProvRate, aes(x=FeedRate,y=MeerkatRate))+theme_bw()+
  geom_point(size=2)+
  scale_x_continuous(name="Feed Rate (Feeds per hour)")+
  scale_y_continuous(name="Meerkat Rate (Visits per hour)")+
  geom_smooth(method="lm",se=F, col="Red")

Fig3

cor.test(ProvRate$FeedRate,ProvRate$MeerkatRate)

ggsave("../Plots/Figure3.png", plot=Fig3, height=7, width = 10)


### Qualitative Data ####
BirdData <- read.csv("../Data/FinalBirdData.csv")
BroodData <- read.csv("../Data/FinalBroodData.csv")
length(unique(BirdData$BirdID))
table(BirdData$SurvFledge)
table(BirdData$Recruited)

length(unique(BroodData$BroodRef))
