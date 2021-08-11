#Trains Reccurent Neural Net on Cluster
rm(list=ls())
graphics.off()
setwd("/rds/general/user/hhc4317/home/SparrowVis/RNNCode/")
set.seed(1)

#load packages
require(abind)
require(keras)
require(tidyverse)
install_keras()

#####1. Reading in the data#####
# test <- keras_model_sequential()
# 
# #load arrays:
# Files <- list.files("../RNNArrays/")
# ArrayNames<- Files[which(endsWith(Files, "Array_Sex.rda"))]
# IDNames <- Files[which(endsWith(Files,"ID_Sex.rda"))]
# 
# #Only 40 vids for training:
# Unmatch <- read.csv("../Data/VideoUnMatchEvents.csv")
# Unmatch$Array <- paste(Unmatch$Video,"_RNNArray_Sex.rda", sep="")
# Unmatch$ID <- paste(Unmatch$Video,"_RNNID_Sex.rda", sep="")
# UnmatchSub <- subset(Unmatch, Unmatch$UnmatchedNum<5) #only get videos that threw away 5 or less events, more confidence
# 
# UnmatchSub <- UnmatchSub[1:60,] #only 40 vids
# 
# ArrayNames <- ArrayNames[ArrayNames %in% UnmatchSub$Array]
# IDNames <- IDNames[IDNames %in% UnmatchSub$ID]
# 
# #Creating a vector to store the names of fitted videos:
# FittedVids <-str_remove(ArrayNames, pattern="_RNNArray_Sex.rda")
# save(FittedVids, file="../Models/FittedVids.rda")
# #check if the orders are the same
# print(ArrayNames)
# print(IDNames)
# 
# MainArray <- array(data=NA, dim=c(1,4,3,128,72)) #NEED TO CHANGE THIS IF CHANGE # OF TIME STEPS OR CHANGE RESOLUTION
# 
# #read arrays
# for(i in 1:length(ArrayNames)){
#   load(paste("../RNNArrays/",ArrayNames[i],sep=""))
#   MainArray <- abind(MainArray,RNNVal,along=1)
# 
# }
# 
# MainArray <- MainArray[-1,,,,] #Remove first array, it is all NAs from preallocation
# 
# #read ID vectors
# IDVect <- c()
# for(i in 1:length(IDNames)){
#   load(paste("../RNNArrays/",IDNames[i],sep=""))
#   IDVect <- c(IDVect, RNNID)
# }
# 
# ##subset 1% of data for validation
# ValidateIndex <- sample(1:dim(MainArray)[1],as.integer(dim(MainArray)[1]*0.01), replace=FALSE)#get index
# 
# #Validation Dataset:
# Val.Array <- MainArray[ValidateIndex,,,,]
# Val.IDVect <- IDVect[ValidateIndex]
# 
# #actual dataset:
# MainArray <- MainArray[-ValidateIndex,,,,]
# IDVect <- IDVect[-ValidateIndex]
# 
# 
# #Testing stuff to make sure stuff works:
# if(dim(MainArray)[1]==length(IDVect)){
#   print("ALL GOOD!!! WOOP WOOP")
# }else{
#   stop("Array length and IDvector doesnt match")
# }
# 
# #check if all NAs are removed
# yo <- apply(MainArray,1,function(x) sum(is.na(x)))
# if(sum(yo)>0){print("There are NAs in arrays")}else{print("all good, no NAs")}
# 
# ##for 3d convolution layer: switch dimensions
# MainArray <- aperm(MainArray, c(1,2,4,5,3))
# Val.Array <- aperm(Val.Array, c(1,2,4,5,3))
# 
# 
# #Saving all arrays to save time on clust
# save(MainArray, file="../RNNArrays/MainArray3D.rda")
# save(IDVect, file="../RNNArrays/IDVect3D.rda")
# save(Val.Array, file="../RNNArrays/Val.Array3D.rda")
# save(Val.IDVect, file="../RNNArrays/Val.IDVect3D.rda")

#Loading all of it
load(file="../RNNArrays/MainArray3D.rda")
load(file="../RNNArrays/IDVect3D.rda")
load(file="../RNNArrays/Val.Array3D.rda")
load(file="../RNNArrays/Val.IDVect3D.rda")

###Train RNN###
imagescale <- 10

RNN <- keras_model_sequential()

RNN %>% layer_conv_3d(filters=50, kernel_size = c(3,3,3), 
                           input_shape = c(4,1280/imagescale,720/imagescale,3), 
                           data_format = "channels_last",
                           activation="relu") %>%
  layer_max_pooling_3d(pool_size = c(2,2,2)) %>%
  layer_flatten()%>%
  layer_dropout(rate=0.25)%>%
  layer_dense(units=64, activation = 'relu')%>%
  layer_dropout(rate=0.2)%>%
  layer_dense(units=32, activation='relu')%>%
  layer_dropout(rate=0.2) %>%
  layer_dense(units=1, activation='sigmoid')%>%
  compile(
    optimizer='adam',
    loss='binary_crossentropy',
    metrics=c('accuracy')
  )

#Training:
for(i in 1:150){
  print(paste("epoch:",i))
  Augmented <- MainArray + rnorm(length(MainArray), sd=0.1)
  
  #augment by flipping left to right 50% of times:
  if(sample(c(1,2), 1)==1){
    Augmented <- Augmented[ , , ,dim(Augmented)[4]:1 , ] 
  }else{}
  
  RNN %>% fit(Augmented,IDVect, epochs = 1)
}

# RNN %>% fit(MainArray, IDVect, epochs=20)

RNN %>% save_model_hdf5("../Models/TrainedSexRNN3D")
RNN %>% evaluate(Val.Array, Val.IDVect)
print(dim(MainArray))#print dimension of array, show amount of training data


#predict/ validate: 
#predictions <- predict(RNN, MainArray)
# RNN %>% evaluate(Val.Array, Val.IDVect)
