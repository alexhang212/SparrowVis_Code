#running MCMCglmm models 
rm(list=ls())
library(MCMCglmm)
library(tidyverse)


#HPC:
iter <-as.numeric(Sys.getenv("PBS_ARRAY_INDEX")) # get iteration


#Reading in Data
data <- read.csv("../Data/FinalBirdData.csv")
data <- data %>% 
  mutate(BirdID = as.factor(BirdID))%>%
  mutate(Cohort = as.factor(Cohort)) %>%
  mutate(RearBrood = as.factor(RearBrood)) %>%
  mutate(Year = as.factor(Year))%>%
  mutate(MaleID = as.factor(MaleID))%>%
  mutate(FemaleID = as.factor(FemaleID))%>%
  mutate(NestboxRef = as.factor(NestboxRef))%>%
  mutate(MFComb = as.factor(MFComb)) %>%
  mutate(Location=as.factor(Location))


data <- data %>%  drop_na(Sex) %>%
  drop_na(c("MaleID","FemaleID","Location"))

names(data)


###Defining Parameters
Params = list(
  Response = c("Day12Mass","SurvFledge", "Longevity", "Recruits", 
               "Recruited", "FirstBreedAge"),
  Prov = c("z_AvgFeedRateChick", "z_FeedRateChick7", "z_FeedRateChick11",
           "z_AvgMeerkatRateChick","z_MeerkatRateChick7", "z_MeerkatRateChick11")
)


# a <- 1000
# priors <- list(R = list(V = diag(1), nu = 0.002),
#                G = list(G1 = list(V = diag(1), nu = 1, alpha.mu = 0, alpha.V = diag(1)*a),
#                         G1 = list(V = diag(1), nu = 1, alpha.mu = 0, alpha.V = diag(1)*a),
#                         G1 = list(V = diag(1), nu = 1, alpha.mu = 0, alpha.V = diag(1)*a),
#                         G1 = list(V = diag(1), nu = 1, alpha.mu = 0, alpha.V = diag(1)*a),
#                         G1 = list(V = diag(1), nu = 1, alpha.mu = 0, alpha.V = diag(1)*a)))
# 

priors <- list(R = list(R1 = list(V = diag(1), nu = 0.05)),
            G = list(G1 = list(V = diag(1), nu = 0.002),
                     G2 = list(V = diag(1), nu = 0.002),
                     G3 = list(V = diag(1), nu = 0.002),
                     G4 = list(V = diag(1), nu = 0.002),
                     G5 = list(V = diag(1), nu = 0.002)))


ParamDF <- expand.grid(Params) %>%
  mutate(Family = case_when(Response == "Day12Mass" ~ "gaussian",
                            Response == "SurvFledge" ~ "categorical",
                            Response == "Longevity" ~ "poisson",
                            Response == "Recruits" ~ "poisson",
                            Response == "Recruited" ~ "categorical",
                            Response == "FirstBreedAge" ~ "poisson"))%>%
  mutate(Response=as.character(Response))%>%
  mutate(Prov = as.character(Prov))

##Run Model## 
datasub <- data %>% drop_na(ParamDF[iter,"Prov"]) %>%
  drop_na(ParamDF[iter,"Response"])

print(nrow(datasub)) # print sample size

#for testing NAs in fixed effects
# for(i in 1:ncol(datasub)){
#   print(colnames(datasub)[i])
#   print(anyNA(datasub[,i]))
#   
# }

Rand <- as.formula("~ MaleID + FemaleID + RearBrood+Year+Location")
Fixed <- as.formula(paste(ParamDF[iter, "Response"], "~", 
                          ParamDF[iter,"Prov"], 
                          "+Sex+MaleAge+FemaleAge+HatchBroodSize +poly(HatchBroodSize,2) + poly(HatchDateCode,2)+Fostered+ HatchDateCode", sep=""))


#Model <- MCMCglmm(Fixed, random = Rand , family = ParamDF[iter, "Family"], data=datasub,
#                   burnin=5,nitt=10, thin=1,verbose = F)

Model <- MCMCglmm(Fixed, random = Rand , family = ParamDF[iter, "Family"], data=datasub,
                      prior=priors, burnin=100000,nitt=10000000, thin=1000,verbose = F)
summary(Model)
save(Model, file=paste("../Results/IndivModel_", iter,".rda", sep=""))

