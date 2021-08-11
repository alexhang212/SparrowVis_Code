#Script to be ran on Roy, Train Behavior Model
rm(list=ls())
graphics.off()
set.seed(1)

#!! Set working directory to be the folder with all files!!#
reticulate::use_condaenv("KerasTest",required=TRUE)
require(keras)
require(tidyverse)

test <- keras_model_sequential()

##Read Data
load(file="../ClipArrays/MainArray.rda")
load(file="../ClipArrays/MainVect.rda")
load(file="../ClipArrays/ValArray.rda")
load(file="../ClipArrays/ValVect.rda")

MainArray <- imagenet_preprocess_input(MainArray)
ValArray <- imagenet_preprocess_input(Val.Array)

###Train Model###
imagescale <- 10
length <- 7 #length of clips

#first time: download model and save it:
# VGG19 <- application_vgg19(include_top = FALSE, weights="imagenet", input_shape = c(128,72,3))
# VGG19 %>% save_model_hdf5("../Models/EmptyVGG19")

VGG16 <- load_model_hdf5("../Models/EmptyVGG16")
# 
freeze_weights(VGG16)#freeze whole CNN
unfreeze_weights(VGG16,from="block5_conv1") #unfreeze top layers
# 
# #compile:
BehavModel <- keras_model_sequential()%>%
  time_distributed(VGG16, input_shape = c((length*5)+1,128,72,3)) %>%
  time_distributed(layer_flatten(), input_shape = c((length*5)+1,4,2,512))%>%
  layer_dropout(rate=0.3)%>%
  layer_simple_rnn(units=64,batch_input_shape = c((length*5)+1,4096))%>%
  layer_dense(units=256, activation='relu')%>%
  layer_dense(units=128, activation='relu')%>%
  layer_dense(units = 256, activation='relu')%>%
  layer_dense(units=3, activation='softmax') %>%
  compile(
    optimizer=optimizer_adam(lr=1e-05),
    loss='sparse_categorical_crossentropy',
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

 for(i in 1:30){
 print(paste("epoch:",i))

 FitHistory <- BehavModel %>% fit(MainArray,MainVect, epochs = 1, verbose=2,
                                 validation_data = list(Val.Array,Val.Vect))
 Val.Loss <- FitHistory[[2]]$val_loss

 #if loss didnt drop, stop training
 if((Val.Loss.Prev-Val.Loss)>0){
    print("Val.Loss is dropping, continue training")
    Val.Loss.Prev <- Val.Loss
    counter <- 0
 }else{
    counter <- counter +1
    if(counter >5){
       print("Val.Loss increased by more than 0.01 3 epochs in a row, stop training")
    break #stops looping
    }
 }
 }


print("finished training, saving model")
VGGModel %>% save_model_hdf5("../Models/TrainedBehav")
print("Finished Saving!")
#
#
# #Try fit the models#
# VGGModel %>% evaluate(Val.Array,Val.ImageID)
# #predictions <- predict(CNN, Val.Array)
# #save(predictions, file="Prediction.rda")
