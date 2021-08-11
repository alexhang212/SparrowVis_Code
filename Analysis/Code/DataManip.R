#Clean data for analysis
rm(list=ls())

#load packages
library(readxl)
library(tidyverse)
library(stringr)

#Prepare provision rates csv
Provision <- read.csv("../Data/MasterTraining.csv")
UnqDVD <- unique(Provision$DVDRef)

ProvDF <- data.frame(matrix(ncol=5, nrow = length(UnqDVD)))
names(ProvDF) <- c("DVDRef", "DVDNumber","BroodName","Year", "ProvFreq")

for(i in 1:length(UnqDVD)){
  sub <- subset(Provision, Provision$DVDRef==UnqDVD[i])
  ProvDF[i,"DVDRef"]<-sub$DVDRef[1]
  ProvDF[i,"DVDNumber"] <- sub$DVDNumber[1]
  ProvDF[i,"BroodName"] <- sub$BroodName[1]
  ProvDF[i,"Year"] <- sub$Year[1]
  ProvDF[i,"ProvFreq"] <- nrow(subset(sub, sub$State %in% c("O","I")))
  
}

write.csv(ProvDF, "../Data/ProvisionFrequency.csv")

#match brood names and brood ref
BroodNameDF <- read_excel("../Data/tblBroods.xlsx") %>%
  select(c("BroodRef","BroodName"))


#combine with DVD info
DVDInfo <- read_excel("../Data/DVD Information_2021-04-07.xlsx")%>%
  select(c("DVDRef", "DVDNumber", "TapeLength","OffspringNo", "Age", "DVDdate", "BroodRef")) %>%
  drop_na("Age")%>%
  separate(DVDdate, c("Year","Month","Day"), sep="-") %>% 
  mutate(Month=as.numeric(Month))%>% #convert date to days after april 1
  mutate(Day=as.numeric(Day))%>%
  mutate(Year = as.numeric(Year))%>%
  mutate(DateCode=ifelse(Month==04,Day,ifelse(Month==5,Day+30, 
                                              ifelse(Month==6,Day+61,
                                              ifelse(Month==7, Day+91,
                                              ifelse(Month==8, Day+122,NA))))))%>%
  select(-c("Month","Day")) %>% 
  left_join(BroodNameDF) %>%
  select(-c("BroodRef"))
  
write.csv(DVDInfo, "../Data/DVDInfo.csv")
# provisioning frequency
DVDProv <- left_join(DVDInfo,ProvDF) %>%
  mutate(FeedRate = (ProvFreq/TapeLength)*60) %>%#get feeding rate per hour
  mutate(FeedRateChick = ifelse(OffspringNo>0 ,FeedRate/OffspringNo, NA)) #get feeding rate per chick per hour

#get meerkatfrequency
Meerkat <- read.csv("../Data/MeerkatFreq.csv")%>%
  mutate(DVDNumber = substr(Video,1,6)) %>%
  mutate(MeerkatRate = (MeerkatFreq/MeerkatTime)*60) %>%
  select(c("DVDNumber", "MeerkatRate","MeerkatTime"))%>%
  mutate(MeerkatRate = ifelse(MeerkatRate > 145.5138, NA, MeerkatRate))# set threshold at 145.5138
  ##refer to jupyter

MasterProv <- left_join(DVDProv,Meerkat)
write.csv(MasterProv, "../Data/MasterProvisionRates.csv")

#Calculate per chick rate
MasterProv <- mutate(MasterProv, MeerkatRateChick = ifelse(OffspringNo>0 ,MeerkatRate/OffspringNo, NA))%>%
filter(!(is.na(MeerkatRate)&is.na(FeedRate))) #if both feed rate and meerkat rate is NA



#Get average feed rate per brood (following Ihle et al. 2019)
UnqBrood <- unique(MasterProv$BroodName)
AvgFeedRate <- data.frame(matrix(ncol=17, nrow = length(UnqBrood)))
names(AvgFeedRate) <- c("DVDRef", "DVDNumber","BroodName","Year", "AvgFeedRate",
                      "AvgFeedRateChick","HatchDateCode","AvgMeerkatRate","AvgMeerkatRateChick",
                      "FeedRate7","FeedRate11","FeedRateChick7", "FeedRateChick11",
                      "MeerkatRate7", "MeerkatRate11", "MeerkatRateChick7", "MeerkatRateChick11")

for(i in 1:length(UnqBrood)){
  sub <- subset(MasterProv, MasterProv$BroodName == UnqBrood[i])
  sub <- subset(sub,sub$Age>5 & sub$Age<12)
  
  AvgFeedRate[i, "DVDRef"] <- sub$DVDRef[1]
  AvgFeedRate[i, "DVDNumber"] <- sub$DVDNumber[1]
  AvgFeedRate[i, "BroodName"] <- sub$BroodName[1]
  AvgFeedRate[i, "Year"] <- sub$Year[1]
  AvgFeedRate[i, "AvgFeedRate"] <- mean(sub$FeedRate)
  AvgFeedRate[i, "AvgFeedRateChick"] <- mean(sub$FeedRateChick)
  AvgFeedRate[i, "AvgMeerkatRate"] <- mean(sub$MeerkatRate)
  AvgFeedRate[i, "AvgMeerkatRateChick"] <- mean(sub$MeerkatRateChick)
  AvgFeedRate[i, "HatchDateCode"] <- sub$DateCode[1] - sub$Age[1]
  
  sub <- subset(sub,sub$Age>5&sub$Age<12) # subset to only below 5 after calculating average
  
  if(nrow(sub)>1){
    #get index for max and min if theres only 2 values (should be majority cases)
    Index7 <- which(sub$Age>4&sub$Age<9)
    Index11 <- which(sub$Age>8&sub$Age<14)
    
    #using mean() because in some cases there are multiple videos in the same
    #brood age range, so just take a mean between them
    AvgFeedRate[i, "FeedRate7"] <- mean(sub$FeedRate[Index7])
    AvgFeedRate[i, "FeedRate11"] <- mean(sub$FeedRate[Index11])
    AvgFeedRate[i, "FeedRateChick7"]<- mean(sub$FeedRateChick[Index7])
    AvgFeedRate[i, "FeedRateChick11"]<- mean(sub$FeedRateChick[Index11])
    #meerkat
    AvgFeedRate[i, "MeerkatRate7"] <- mean(sub$MeerkatRate[Index7])
    AvgFeedRate[i, "MeerkatRate11"] <- mean(sub$MeerkatRate[Index11])
    AvgFeedRate[i, "MeerkatRateChick7"]<- mean(sub$MeerkatRateChick[Index7])
    AvgFeedRate[i, "MeerkatRateChick11"]<- mean(sub$MeerkatRateChick[Index11])

  }else{
    #nrow is 1
      if(nrow(sub)==0){
       next 
      }else{
      if(sub$Age[1]>8){
        ##Age larger than 8, its Day11 Data
        AvgFeedRate[i, "FeedRate7"] <- NA
        AvgFeedRate[i, "FeedRate11"] <- sub$FeedRate[1]
        AvgFeedRate[i, "FeedRateChick7"]<- NA
        AvgFeedRate[i, "FeedRateChick11"]<- sub$FeedRateChick[1]
        
        AvgFeedRate[i, "MeerkatRate7"] <- NA
        AvgFeedRate[i, "MeerkatRate11"] <- sub$MeerkatRate[1]
        AvgFeedRate[i, "MeerkatRateChick7"]<- NA
        AvgFeedRate[i, "MeerkatRateChick11"]<- sub$MeerkatRateChick[1]
        
      }else{
        #Its Day7 data
        AvgFeedRate[i, "FeedRate7"] <-sub$FeedRate[1]
        AvgFeedRate[i, "FeedRate11"] <- NA
        AvgFeedRate[i, "FeedRateChick7"]<- sub$FeedRateChick[1]
        AvgFeedRate[i, "FeedRateChick11"]<- NA
        
        AvgFeedRate[i, "MeerkatRate7"] <- sub$MeerkatRate[1]
        AvgFeedRate[i, "MeerkatRate11"] <- NA
        AvgFeedRate[i, "MeerkatRateChick7"]<- sub$MeerkatRate[1] 
        AvgFeedRate[i, "MeerkatRateChick11"]<- NA
      }
      }
  }
  
}

#Get brood recruitment csv
BirdDF <- read_excel("../Data/tblBirdID.xlsx")
Pedigree <- read_excel("../Data/20210317_JC_Ped16-19.xlsx")%>%
  filter(Cohort >= 2000 &
           Immigrant ==0) %>%
  na_if("NA")%>%
  mutate(Cohort=as.character(Cohort)) %>%
  dplyr::rename(animal=Offspring)%>%
  select(animal,Dam,Sire)

UnqBrood <- unique(BirdDF$BroodRef)
Parents <- c(Pedigree$Dam,Pedigree$Sire) # vector of all bird ID that became parents
RecruitDF <- data.frame(matrix(ncol=2, nrow=length(UnqBrood)))
names(RecruitDF) <- c("BroodRef", "Recruits")

for(i in 1:length(UnqBrood)){
  sub <- subset(BirdDF, BirdDF$BroodRef==UnqBrood[i])
  RecruitDF[i,"BroodRef"] <- sub$BroodRef[1]
  RecruitDF[i,"Recruits"] <- sum(sub$BirdID %in% Parents)
  
  if(isTRUE(sub$Cohort[1]>2017)){
    RecruitDF[i,"Recruits"] <- NA
  }
}
write.csv(RecruitDF, file="../Data/BroodRecruits.csv")

#habitat type
NestboxInfo <- read_xlsx("../Data/Nestboxes_2021-04-07.xlsx") %>%
  select(c(NestboxRef, NestboxName, HabitatType)) %>%
  mutate(HabitatType = ifelse(NestboxName %in% c("LM37", "LM41", "R2N2"), #manually replacing values that are NA
                              0, HabitatType))

##Nestbox Location
Broods <- read_excel("../Data/tblBroods.xlsx") %>%
  select(c(BroodName, NestboxRef))
Location <- read.csv("../Data/Nest_Loc_Pedigree.csv")%>%
  select(c(BroodName, Nest_Location))%>%
  right_join(Broods)%>%
  left_join(NestboxInfo) %>%
  mutate(Nest_Location = ifelse(is.na(Nest_Location),
                                ifelse(grepl("^C[0-9]|^F[0-9]|^LB[0-9]|^LF[0-9]|^LM[0-9]|^ML[0-9]|^MM[0-9]|^MR[0-9]|^R[0-9]|^S[0-9]|^W[0-9]", NestboxName,ignore.case=T),
                                       #regular expression for the letters followed by numbers
                                       str_extract(NestboxName, "[:alpha:]*"),NA) #extract the letters that matched
                                ,Nest_Location)) %>%
  mutate(Nest_Location = toupper(Nest_Location)) %>%
  mutate(Location=Nest_Location) %>% # change column name
  select(c(BroodName,Location))


##Fostered status
Foster <- read_excel("../Data/tblFosterBroods.xlsx")
FosterBroods <- unique(Foster$FosterBrood) # vector of broodref that are fostered

#### BroodWise Analysis ####
BroodInterval <- read_excel("../Data/Brood intervals_2021-04-07.xlsx")
Broods <- read_excel("../Data/tblBroods.xlsx") %>%
          select(c("BroodRef","NestboxRef"))


BroodData <- select(BroodInterval, c("BroodRef", "BroodName", "MaleID","FemaleID",
                           "MaleAge","FemaleAge", "HatchBroodSize","RingBroodSize",
                           "FledgeBroodSize", "BroodYear" )) %>%
                left_join(Broods)%>%#add nestbox ref
                left_join(AvgFeedRate) %>% #add feed rate
                mutate(MFComb = paste(MaleID,".",FemaleID, sep = "")) %>% #get pair ID
                left_join(RecruitDF) %>% #add recruits
                left_join(NestboxInfo) %>% #Add nestbox habitat + name
                mutate(Fostered = ifelse(BroodRef %in% FosterBroods, 1, 0))%>%
                left_join(Location)%>%
                distinct()
                

BroodData <- BroodData %>%
  mutate(z_AvgFeedRate = scale(AvgFeedRate))%>%
  mutate(z_FeedRate7 = scale(FeedRate7)) %>%
  mutate(z_FeedRate11 = scale(FeedRate11)) %>%
  mutate(z_AvgMeerkatRate = scale(AvgMeerkatRate)) %>%
  mutate(z_MeerkatRate7 = scale(MeerkatRate7)) %>%
  mutate(z_MeerkatRate11 = scale(MeerkatRate11))


write.csv(BroodData, file="../Data/FinalBroodData.csv")

##### Individual analysis #####

##12 day mass##
ChickMass <- read_excel("../Data/ChickMass.xlsx") %>%
  select(c("BirdID", "Age", "Mass"))

Day12 <- subset(ChickMass,ChickMass$Age==12) %>%
  mutate(Day12Mass = Mass) %>%
  select(c("BirdID", "Day12Mass"))


##foster status
Fostered <- unique(Foster$BirdID) #bird ids that are fostered

#get where each bird is reared (considering fostering)
FosterDF <- select(Foster, c("BirdID", "FosterBrood")) %>%
  right_join(BirdDF) %>%
  mutate(RearBrood = ifelse(is.na(FosterBrood), BroodRef, FosterBrood)) %>%
  select(c("BirdID", "RearBrood"))

##Bird Sex
BirdSex <- read_excel("../Data/Sex estimates_2021-06-28.xlsx")
##there are multiple estimates of the same bird
UnqBirdSexID <- unique(BirdSex$BirdID)
SexDF <- data.frame(matrix(ncol=2,nrow=length(UnqBirdSexID)))
names(SexDF) <- c("BirdID", "Sex")

for(i in 1:length(UnqBirdSexID)){
  sub <- subset(BirdSex, BirdSex$BirdID == UnqBirdSexID[i])
  if (sum(sub$Sex %in% sub$Sex[1])==nrow(sub)){ #all sex match up with first one
  SexDF[i, "BirdID"] <-UnqBirdSexID[i]
  SexDF[i, "Sex"] <-sub$Sex[1]
  }else{
    #some sex dont match up
    SexDF[i, "BirdID"] <-UnqBirdSexID[i]
    SexDF[i, "Sex"]<- NA
  }
  
}

###There are no uncertain sexes!!!

##Survival
BirdCohort <- select(BirdDF, c("BirdID", "Cohort"))

LastLive <- read_excel("../Data/LastLive.xlsx") %>%
  select("BirdID", "LastLiveRecord") %>%
  separate(LastLiveRecord, c("Year","Month","Day"), sep="-") %>%
  mutate(LastYear = as.numeric(Year)) %>%
  select("BirdID", "LastYear") %>% 
  left_join(BirdCohort) %>%
  mutate(SurvNext = ifelse(Cohort<2020, ifelse(LastYear>Cohort, 1,0), NA))

Death <- select(BirdDF, c("BirdID","Cohort", "LastStage", "DeathDate")) %>%
  separate(DeathDate, c("Year","Month","Day"), sep="-") %>% 
  mutate(Month=as.numeric(Month))%>% #convert date to days after april 1
  mutate(Day=as.numeric(Day))%>%
  mutate(Year = as.numeric(Year)) %>%
  mutate(SurvFledge = ifelse(LastStage<3, 0,1)) %>%#survival till fledgeling
  left_join(LastLive) %>%
  mutate(DeathYear= ifelse(is.na(Year), ifelse(LastYear<2018, LastYear,NA), Year)) %>% #if death year is NA, take last seen year if not seen before 2018
  mutate(Longevity = DeathYear -Cohort)%>%
  select(c("BirdID", "Cohort","SurvFledge", "SurvNext", "Longevity"))
  

  ##Breeding traits
  ##lifetime recruits
  UnqID <- unique(BirdDF$BirdID)
  Recruited <- c(Pedigree$Dam,Pedigree$Sire)
  IndRecruitDF <- data.frame(matrix(nrow=length(UnqID), ncol = 4))
  names(IndRecruitDF) <- c("BirdID", "Recruited","Recruits","FirstBreedYear")
  NewPed <- left_join(Pedigree, BirdCohort, by=c("animal"="BirdID"))
  
  for(i in 1:length(UnqID)){
    sub <- subset(NewPed, NewPed$Dam==UnqID[i] |NewPed$Sire==UnqID[i] )
    if(nrow(sub>0)){RecruitYes <- 1}else{RecruitYes <- 0} #recruited or not
    #calcualted num of offspring that is recruited
    recruitNum <- sum(sub$animal %in% Recruited)
    IndRecruitDF[i,"BirdID"] <- UnqID[i]
    IndRecruitDF[i,"Recruited"] <-RecruitYes
    IndRecruitDF[i, "Recruits"] <- recruitNum
    ifelse(nrow(sub)==0, BreedYear <- NA, BreedYear <- min(sub$Cohort, na.rm = T))
    IndRecruitDF[i, "FirstBreedYear"] <- BreedYear
    
    ##for new 2018/2019 birds:
    if(isTRUE(BirdDF[which(BirdDF$BirdID==UnqID[i]),"Cohort"]>2017)){
      IndRecruitDF[i, "Recruits"] <- NA
      IndRecruitDF[i, "FirstBreedYear"] <- NA
    }
    
  }

  IndRecruitDF <-select(IndRecruitDF, c("BirdID", "Recruited","Recruits", "FirstBreedYear"))
  
  #Other brood data + provisioning rates
  BroodDF <- select(BroodData, c("BroodRef", "BroodName", "Year","MaleID", "FemaleID",
                                 "MaleAge", "FemaleAge", "HatchBroodSize", "FledgeBroodSize",
                                 "NestboxRef","HabitatType","AvgFeedRateChick","FeedRateChick7",
                                 "FeedRateChick11","AvgMeerkatRateChick","MeerkatRateChick7",
                                 "MeerkatRateChick11","NestboxName","HatchDateCode"))
  
  ## Noise
  NoiseDF <- select(BroodDF, c("BroodRef","NestboxName","Year"))%>%
    mutate(Noise = ifelse(startsWith(NestboxName, "W")&Year<2012, 1, 0))%>%
    select(c("BroodRef","Noise"))
  
  
  
##Individual Analysis
MasterBird <- select(BirdDF, c("BirdID", "Cohort", "BroodRef")) %>%
  left_join(SexDF)%>%
  left_join(FosterDF)%>%
  left_join(Day12) %>% #add day 12 mass
  mutate(Fostered = ifelse(BirdID %in% Fostered, 1,0)) %>%
  left_join(Death) %>% #add survival till next year and survival till fledge and logevity
  left_join(IndRecruitDF) %>% # get first breed year
  mutate(FirstBreedAge = FirstBreedYear - Cohort) %>%#first breed age
  left_join(BroodDF) %>%#add all prov rates and info from before
  mutate(MFComb = paste(MaleID,".",FemaleID, sep="")) %>%#MF combination
  left_join(NoiseDF) %>%
  filter(!(is.na(AvgMeerkatRateChick)&is.na(AvgFeedRateChick))) %>%#remove row if both meerkat and feedrate is NA
  left_join(Location) %>%
  distinct()


MasterBird <- MasterBird %>%
  mutate(BirdID = as.factor(BirdID))%>%
  mutate(Cohort = as.factor(Cohort)) %>%
  mutate(RearBrood = as.factor(RearBrood)) %>%
  mutate(Year = as.factor(Year))%>%
  mutate(MaleID = as.factor(MaleID))%>%
  mutate(FemaleID = as.factor(FemaleID))%>%
  mutate(NestboxRef = as.factor(NestboxRef))%>%
  mutate(MFComb = as.factor(MFComb))%>%
  mutate(Location=as.factor(Location))


#z transform provision rates
MasterBird <- MasterBird %>%
  mutate(z_AvgFeedRateChick = scale(AvgFeedRateChick))%>%
  mutate(z_FeedRateChick7 = scale(FeedRateChick7)) %>%
  mutate(z_FeedRateChick11 = scale(FeedRateChick11)) %>%
  mutate(z_AvgMeerkatRateChick = scale(AvgMeerkatRateChick)) %>%
  mutate(z_MeerkatRateChick7 = scale(MeerkatRateChick7)) %>%
  mutate(z_MeerkatRateChick11 = scale(MeerkatRateChick11))
 
write.csv(MasterBird, file="../Data/FinalBirdData.csv")
