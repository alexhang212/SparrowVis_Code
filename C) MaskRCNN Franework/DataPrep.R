#Prepare data for Sex CNN training
rm(list=ls())

library(reticulate)
use_condaenv("RKeras", required = TRUE)
library(magick)
library(abind)


# ##Load images
MaleTrain <- list.files("../Masks/RealTraining/Training/Male/")
FemaleTrain <-list.files("../Masks/RealTraining/Training/Female/")
#
MaleVal <- list.files("../Masks/RealTraining/Validation/Male/")
FemaleVal <-list.files("../Masks/RealTraining/Validation/Female/")
#
# # ### read images ###
# #
# # #image dimensions:
ht = 144
wt = 256
# #
# # ##function to loop through directory and read in images
ReadImage <- function(Directory, Vect){
 OutArray <- array(data=NA, dim=c(length(Vect),3,256,144))
 #Directory: directory of the images
# Vect: vector of image names
 for(i in 1:length(Vect)){
 image <- image_read(paste("../Masks/RealTraining/",Directory,Vect[i], sep=""))
 OutArray[i, , , ] <- (as.integer(image[[1]])/255)
 }
 return(OutArray)
 }
# #
# #
# # ## Read images and save:
TrainMaleArray <- ReadImage("Training/Male/", MaleTrain)
TrainFemaleArray <- ReadImage("Training/Female/", FemaleTrain)
TrainArray <- abind(TrainMaleArray,TrainFemaleArray, along = 1)
print(dim(TrainArray))
save(TrainArray,file= "../Arrays/SexTrainArray.rda")
TrainVect <- c(rep(1,dim(TrainMaleArray)[1]), rep(0,dim(TrainFemaleArray)[1]))
print(length(TrainVect))
save(TrainVect, file="../Arrays/SexTrainVect.rda")
#
# #validation
ValMaleArray <- ReadImage("Validation/Male/", MaleVal)
ValFemaleArray <- ReadImage("Validation/Female/",FemaleVal)
ValArray <- abind(ValMaleArray,ValFemaleArray, along = 1)
print(dim(ValArray))
save(ValArray, file="../Arrays/SexValArray.rda")
ValVect <- c(rep(1,dim(ValMaleArray)[1]), rep(0,dim(ValFemaleArray)[1]))
print(length(ValVect))
save(ValVect, file="../Arrays/SexValVect.rda")


#convert to numpy array
np = import("numpy")
np$save("../Arrays/SexTrainArray.npy", r_to_py(TrainArray))
np$save("../Arrays/SexTrainVect.npy", r_to_py(TrainVect))
np$save("../Arrays/SexValArray.npy", r_to_py(ValArray))
np$save("../Arrays/SexValVect.npy", r_to_py(ValVect))

