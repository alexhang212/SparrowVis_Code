#running MCMCglmm models 
rm(list=ls())

library(MCMCglmm)
library(tidyverse)


#HPC:
iter <-as.numeric(Sys.getenv("PBS_ARRAY_INDEX")) # get iteration

#Reading in Data
data <- read.csv("../Data/FinalBroodData.csv")
data <- data %>% 
  mutate(BroodYear = as.factor(BroodYear))%>%
  mutate(MaleID = as.factor(MaleID))%>%
  mutate(FemaleID = as.factor(FemaleID))%>%
  mutate(NestboxRef = as.factor(NestboxRef))%>%
  mutate(MFComb = as.factor(MFComb))%>%
  mutate(Location=as.factor(Location))


data <- data%>%
  drop_na(c("MaleID","FemaleID", "Location"))
names(data)

##Specifying paramters:
Params = list(
  Response = c("Recruits", "FledgeBroodSize"),
  Prov = c("z_AvgFeedRate", "z_FeedRate7", "z_FeedRate11",
           "z_AvgMeerkatRate","z_MeerkatRate7", "z_MeerkatRate11")
)

ParamDF <- expand.grid(Params) %>%
  mutate(Response=as.character(Response))%>%
  mutate(Prov = as.character(Prov))

#remove NA rows
print(iter)
print(ParamDF[iter,"Response"])
datasub <- data %>% drop_na(ParamDF[iter,"Prov"]) %>%
  drop_na(ParamDF[iter,"Response"])

## define formula
Rand <- as.formula("~ MaleID + FemaleID + BroodYear+Location")
Fixed <- as.formula(paste(ParamDF[iter, "Response"], "~", ParamDF[iter,"Prov"],
"+MaleAge+FemaleAge+HatchBroodSize + poly(HatchBroodSize,2)+poly(HatchDateCode,2)+ Fostered+ HatchDateCode"))

##define priors
a <- 1000
priors <- list(R = list(V = diag(1), nu = 0.002),
     G = list(G1 = list(V = diag(1), nu = 1, alpha.mu = 0, alpha.V = diag(1)*a),
              G1 = list(V = diag(1), nu = 1, alpha.mu = 0, alpha.V = diag(1)*a),
              G1 = list(V = diag(1), nu = 1, alpha.mu = 0, alpha.V = diag(1)*a),
              G1 = list(V = diag(1), nu = 1, alpha.mu = 0, alpha.V = diag(1)*a)))

#Model <- MCMCglmm(Fixed, random=Rand,family = "poisson", data=datasub,
#                 burnin=5,nitt=10, thin=1,verbose = F, prior=priors)

Model <- MCMCglmm(Fixed, random=Rand,family = "poisson", data=datasub,
                  burnin=50000,nitt=10000000, thin=1000,verbose = F, prior=priors)
summary(Model)
save(Model, file=paste("../Results/MCMCBroodOut_", iter,".rda", sep=""))
