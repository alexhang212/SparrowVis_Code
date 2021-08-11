#Script to be ran in the cluster, train CNN
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
ArrayNamesAll <- Files[which(endsWith(Files, "Array.rda"))]
ImageIDNamesAll <- Files[which(endsWith(Files,"ImageID.rda"))]

#Only 30 vids for training:
ArrayNames <- ArrayNamesAll[1:20]
ImageIDNames <- ImageIDNamesAll[1:20]


#Creating a vector to store the names of fitted videos:
FittedVids <-str_remove(ArrayNames, pattern="_Array.rda")
save(FittedVids, file="../Models/FittedVids.rda")
#check if the orders are the same
print(ArrayNames)
print(ImageIDNames)

MainArray <- array(data=NA, dim=c(1,320,180,3))

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

###Train CNN###
#CNN <- load_model_hdf5("EmptyCNN")
imagescale <- 4

CNN <- keras_model_sequential()

CNN %>% layer_conv_2d(filters=20, kernel_size=c(4,4), activation = 'relu',
                      input_shape=c(1280/imagescale,720/imagescale,3), data_format="channels_last") %>%
  layer_max_pooling_2d(pool_size = c(3,3)) %>%
  layer_flatten() %>%
  layer_dense(units=10, activation = 'relu')%>%
  layer_dense(units=5, activation='relu')%>%
  layer_dropout(rate=0.2) %>%
  layer_dense(units=1, activation='sigmoid')%>%
  compile(
    optimizer='adam',
    loss='binary_crossentropy',
    metrics=c('accuracy')
  )


#fitting the model: with augmentation:
for(i in 1:100){
print(paste("epoch:",i))
Augmented <- MainArray + rnorm(length(MainArray), sd=0.1)

#augment by flipping left to right 50% of times:
if(sample(c(1,2), 1)==1){
Augmented <- Augmented[,dim(Augmented)[2]:1 , ,] # flips second dimension
}else{}

CNN %>% fit(Augmented,ImageIDVect, epochs = 1)
}

#fitting Model: without augmentation
#CNN %>% fit(MainArray,ImageIDVect, epochs = 100)

##

print("finished training, saving model")
CNN %>% save_model_hdf5("../Models/TrainedCNN")
print("Finished Saving!")


#Try fit the models#
CNN %>% evaluate(Val.Array,Val.ImageID)
#predictions <- predict(CNN, Val.Array)
#save(predictions, file="Prediction.rda")
