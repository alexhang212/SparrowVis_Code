#Script to be ran on Roy, Train Behaviour Model
rm(list=ls())
graphics.off()
set.seed(1)

#!! Set working directory to be the folder with all files!!#
reticulate::use_condaenv("KerasTest",required=TRUE)
require(keras)
require(tidyverse)

test <- keras_model_sequential()

##Read Data
print("Reading In Data!")
load(file="../ClipArrays/MainArray.rda")
load(file="../ClipArrays/MainSexVect.rda")
load(file="../ClipArrays/ValArray.rda")
load(file="../ClipArrays/ValSexVect.rda")

MainArray <- imagenet_preprocess_input(MainArray)
Val.Array <- imagenet_preprocess_input(Val.Array)
print("Finish Reading in Data!")

###Train Model###
imagescale <- 10
length <- 7 #length of clips

#first time: download model and save it:
VGG19 <- application_vgg19(include_top = FALSE, weights="imagenet", input_shape = c(128,72,3))
VGG19 %>% save_model_hdf5("../Models/EmptyVGG19")

VGG19 <- load_model_hdf5("../Models/EmptyVGG19")
# 
freeze_weights(VGG19)#freeze whole CNN
unfreeze_weights(VGG19,from="block5_conv1") #unfreeze top layers
# 
# #compile:
SexModel <- keras_model_sequential()%>%
  time_distributed(VGG19, input_shape = c((length*5)+1,128,72,3)) %>%
  time_distributed(layer_flatten(), input_shape = c((length*5)+1,4,2,512))%>%
  layer_dropout(rate=0.2)%>%
  layer_lstm(units=64,input_shape = c((length*5)+1,4096))%>%
  layer_dropout(rate=0.2)%>%
  layer_dense(units=128, activation='relu')%>%
  layer_dropout(rate=0.2)%>%
  layer_dense(units=0, activation='relu')%>%
  layer_dense(units=1, activation='sigmoid') %>%
  compile(
    optimizer=optimizer_adam(lr=1e-05),
    loss='binary_crossentropy',
    metrics=c('accuracy')
  )


#Read and continue Training Model:

# BehavModel <- load_model_hdf5("../Models/TrainedBehavTest")
# # unfreeze_weights(get_layer(VGGModel,index=1), from="block5_conv1")
# BehavModel %>% compile(
#    optimizer=optimizer_adam(lr =1e-4),
#    loss='sparse_categorical_crossentropy',
#    metrics=c('accuracy')
# )
# 
# BehavModel

##Setting paramters:

#Fitting:
# BehavModel %>% fit(MainArray,MainVect, epochs = 30, verbose=2, callbacks=callback,
#                    validation_data = list(Val.Array,Val.Vect))
# 
# BehavModel %>% save_model_hdf5("../Models/TrainedBehav")

# fitting the model: with augmentation:
Val.Loss.Prev <- Inf #pre allocate

 for(i in 1:15){
 print(paste("epoch:",i))
  
 Augmented <- MainArray + rnorm(length(MainArray), sd=20)
   
 Fit.History <- SexModel %>% fit(Augmented,SexVect, epochs = 1, verbose=2,
                                 validation_data = list(Val.Array,Val.SexVect))
 Val.Loss <- Fit.History[[2]]$val_loss

 #if loss didnt drop, stop training
 if((Val.Loss.Prev-Val.Loss)> 0){
    print("Val.Loss is dropping, continue training")
    Val.Loss.Prev <- Val.Loss
    counter <- 0
 }else{
    counter <- counter +1
    if(counter >4){
       print("Val.Loss increased 5 epochs in a row, stop training")
    break #stops looping
    }
 }
 }


print("finished training, saving model")
SexModel %>% save_model_hdf5("../Models/TrainedSexRNN")
print("Finished Saving!")
#
#
# #Try fit the models#
# VGGModel %>% evaluate(Val.Array,Val.ImageID)
# #predictions <- predict(CNN, Val.Array)
# #save(predictions, file="Prediction.rda")
