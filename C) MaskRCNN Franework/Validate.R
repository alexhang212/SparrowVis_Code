## Temp Script for checking best models for runs
rm(list=ls())

library(reticulate)
#use_condaenv("RKeras", required = TRUE)
library(magick)
library(abind)
library(keras)

#check gridsearch results
SimpleCNN <- read.csv("../Data/SimpleCNN.csv")
which(SimpleCNN$ValAcc==max(SimpleCNN$ValAcc))
which(SimpleCNN$ValLoss==min(SimpleCNN$ValLoss))

SimpleCNN[48,]
SimpleCNN[158,]



#Load data
load("../Arrays/SexTrainArray.rda")
load("../Arrays/SexTrainVect.rda")
load("../Arrays/SexValArray.rda")
load("../Arrays/SexValVect.rda")


TrainArray <- aperm(TrainArray, c(1,3,4,2))
ValArray <- aperm(ValArray, c(1,3,4,2))

print(dim(ValArray))
print(length(ValVect))

#convert to numpy array
# np = import("numpy")
# np$save("../Arrays/SexTrainArray.npy", r_to_py(TrainArray))
# np$save("../Arrays/SexTrainVect.npy", r_to_py(TrainVect))
# np$save("../Arrays/SexValArray.npy", r_to_py(ValArray))
# np$save("../Arrays/SexValVect.npy", r_to_py(ValVect))


BestModel<- load_model_hdf5("../Models/BestModel.h5")
BestModel %>% evaluate(ValArray,ValVect)


##preprocess val array:
# ValArray <- ValArray*255
# ValArray <- imagenet_preprocess_input(ValArray)


##VGG
VGG <- read.csv("../Data/VGGGridSearch5.csv")
which(VGG$ValLoss==min(VGG$ValLoss, na.rm = T))
VGG[71,]

VGG <- read.csv("../Data/VGGGridSearch4.csv")
