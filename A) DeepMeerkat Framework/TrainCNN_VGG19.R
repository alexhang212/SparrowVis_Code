#Script to be ran in the cluster, train VGG19CNN
rm(list=ls())
graphics.off()
setwd("/rds/general/user/hhc4317/home/SparrowVis/Code/")
set.seed(1)

#!! Set working directory to be the folder with all files!!#
require(abind)
require(keras)
require(tidyverse)
install_keras()

test <- keras_model_sequential()

#load arrays:
Files <- list.files("../Arrays/")
ArrayNames <- Files[which(endsWith(Files, "Array.rda"))]
ImageIDNames <- Files[which(endsWith(Files,"ImageID.rda"))]

#Get Videos for training
Unmatch <- read.csv("../Data/VideoUnMatchEvents.csv")
Unmatch$Array <- paste(Unmatch$Video,"_Array.rda", sep="")
Unmatch$ID <- paste(Unmatch$Video,"_ImageID.rda", sep="")
UnmatchSub <- subset(Unmatch, Unmatch$UnmatchedNum<5) #only get videos that threw away 5 or less events, more confidence

UnmatchSub <- UnmatchSub[1:40,] #only 40 vids

ArrayNames <- ArrayNames[ArrayNames %in% UnmatchSub$Array]
ImageIDNames <- ImageIDNames[ImageIDNames %in% UnmatchSub$ID]


#Creating a vector to store the names of fitted videos:
FittedVids <-str_remove(ArrayNames, pattern="_Array.rda")
save(FittedVids, file="../Models/FittedVids.rda")
#check if the orders are the same
print(ArrayNames)
print(ImageIDNames)

MainArray <- array(data=NA, dim=c(1,128,72,3)) #imagescale=10

#read arrays
for(i in 1:length(ArrayNames)){
  load(paste("../Arrays/",ArrayNames[i],sep=""))
  MainArray <- abind(MainArray,ImageVal,along=1)

}

MainArray <- MainArray[-1,,,] #Remove first array, it is all NAs from preallocation

#read ImageIDs
ImageIDVect <- c()
for(i in 1:length(ImageIDNames)){
  load(paste("../Arrays/",ImageIDNames[i],sep=""))
  ImageIDVect <- c(ImageIDVect, ImageID)
}

##subset 1% of data for validation
ValidateIndex <- sample(1:dim(MainArray)[1],as.integer(dim(MainArray)[1]*0.01), replace=FALSE)#get index

#Validation Dataset:
Val.Array <- MainArray[ValidateIndex,,,]
Val.ImageID <- ImageIDVect[ValidateIndex]

#actual dataset:
MainArray <- MainArray[-ValidateIndex,,,]
ImageIDVect <- ImageIDVect[-ValidateIndex]



#Testing stuff to make sure stuff works:
if(dim(MainArray)[1]==length(ImageIDVect)){
  print("ALL GOOD!!! WOOP WOOP")
}else{
  stop("Array length and IDvector doesnt match")
}

#check if all NAs are removed
yo <- apply(MainArray,1,function(x) sum(is.na(x)))
if(sum(yo)>0){print("There are NAs in arrays")}else{print("all good, no NAs")}
print(which(yo==1))

#rescale array for imagenet
MainArray <- imagenet_preprocess_input(MainArray)
Val.Array <- imagenet_preprocess_input(Val.Array)


# #Saving all arrays to save time on clust
save(MainArray, file="../Arrays/MainArray_S.rda")
save(ImageIDVect, file="../Arrays/ImageIDVect_S.rda")
save(Val.Array, file="../Arrays/Val.Array_S.rda")
save(Val.ImageID, file="../Arrays/Val.ImageID_S.rda")

#Loading all of it
load(file="../Arrays/MainArray_S.rda")
load(file="../Arrays/ImageIDVect_S.rda")
load(file="../Arrays/Val.Array_S.rda")
load(file="../Arrays/Val.ImageID_S.rda")




###Train CNN###
imagescale <- 10

#first time: download model and save it:
# VGG19 <- application_vgg19(include_top = FALSE, weights="imagenet", input_shape = c(128,72,3))
# VGG19 %>% save_model_hdf5("../Models/EmptyVGG19")

VGG19 <- load_model_hdf5("../Models/EmptyVGG19")

freeze_weights(VGG19)#freeze whole CNN
# 
#compile:
VGGModel <- keras_model_sequential()%>%
   VGG19 %>%
   layer_dropout(rate=0.3)%>%
   layer_flatten()%>%
   layer_dense(units=256, activation='relu')%>%
   layer_dropout(rate=0.2)%>%
   layer_dense(units=128, activation='relu')%>%
   layer_dense(units=1, activation='sigmoid') %>%
   compile(
     optimizer="adam",
     loss='binary_crossentropy',
     metrics=c('accuracy')
   )

### Another way to do it:
# prediction <- VGG19$output %>%
#   layer_dropout(rate=0.5)%>%
#   layer_flatten()%>%
#   layer_dense(units=30, activation='relu')%>%
#   layer_dense(units=1, activation='sigmoid')
#
# VGGModel <- keras_model(inputs=VGG19$input, outputs = prediction)
#
# VGGModel %>% compile(
#   optimizer=optimizer_adam(lr=0.00005),
#   loss='binary_crossentropy',
#   metrics=c('accuracy')
# )

##

#fitting the model: with augmentation:
for(i in 1:80){
print(paste("epoch:",i))
Augmented <- MainArray + rnorm(length(MainArray), sd=0.1)

#augment by flipping left to right 50% of times:
if(sample(c(1,2), 1)==1){
Augmented <- Augmented[,dim(Augmented)[2]:1 , ,] # flips second dimension
}else{}

VGGModel %>% fit(Augmented,ImageIDVect, epochs = 1)
}

#fitting Model: without augmentation
VGGModel %>% fit(MainArray,ImageIDVect, epochs = 5)

##

print("finished training, saving model")
VGGModel %>% save_model_hdf5("../Models/TrainedVGG19")
print("Finished Saving!")


#Try fit the models#
VGGModel %>% evaluate(Val.Array,Val.ImageID)
#predictions <- predict(CNN, Val.Array)
#save(predictions, file="Prediction.rda")
