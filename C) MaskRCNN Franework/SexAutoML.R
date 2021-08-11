## AutoKeras for Sex ID from masks
rm(list=ls())

library(reticulate)
use_condaenv("RKeras", required = TRUE)
library(abind)
library(keras)
library(parallel)

# 

#Load data
load("../Arrays/SexTrainArray.rda")
load("../Arrays/SexTrainVect.rda")
load("../Arrays/SexValArray.rda")
load("../Arrays/SexValVect.rda")


TrainArray <- aperm(TrainArray, c(1,3,4,2))
ValArray <- aperm(ValArray, c(1,3,4,2))

print(dim(ValArray))
print(length(ValVect))


# BestModel<- load_model_hdf5("BestModel.h5")
# BestModel %>% evaluate(ValArray,ValVect)



#### Training ####
# VGG19 <- application_vgg19(include_top = FALSE, weights="imagenet", input_shape = c(256,144,3))
# VGG19 %>% save_model_hdf5("../Models/EmptyVGG19")

##preprocess arrays for VGG:
ValArray <- ValArray*255
ValArray <- imagenet_preprocess_input(ValArray)
TrainArray <- TrainArray*255
TrainArray <- imagenet_preprocess_input(TrainArray)


VGG19 <- load_model_hdf5("../Models/EmptyVGG19")

###function for grid search

TrainVGG <- function(ModelName = 1, Freeze="top", Drop1,Drop2,Dense,lr, Manual=FALSE){
  VGG19 <- load_model_hdf5("../Models/EmptyVGG19") #load model
  
  if(Manual==TRUE){
    freeze_weights(VGG19)#freeze whole CNN
    unfreeze_weights(VGG19,from="block5_conv1") #unfreeze top layers
    
    VGGModel <- keras_model_sequential()%>%
      VGG19 %>%
      layer_dropout(rate=0.5)%>%
      layer_flatten()%>%
      layer_dense(units=64, activation='relu')%>%
      layer_dropout(rate=0.2)%>%
      layer_dense(units=1, activation='sigmoid') %>%
      compile(
        optimizer=optimizer_adam(lr=1e-05),
        loss='binary_crossentropy',
        metrics=c('accuracy')
      )
  }
  
  #freeze: top, all, none
  if(Freeze =="top"){
  freeze_weights(VGG19)#freeze whole CNN
  unfreeze_weights(VGG19,from="block5_conv1") #unfreeze top layers
  }else{
    if(Freeze=="all"){
      freeze_weights(VGG19)#freeze whole CNN
    }else{
      #freeze = none, do nothing
    }
  }
  VGGModel <- keras_model_sequential()%>%
    VGG19 %>%
    layer_dropout(rate=Drop1)%>%
    layer_flatten()%>%
    layer_dense(units=Dense, activation='relu')%>%
    layer_dropout(rate=Drop2)%>%
    layer_dense(units=1, activation='sigmoid') %>%
    compile(
      optimizer=optimizer_adam(lr=lr),
      loss='binary_crossentropy',
      metrics=c('accuracy')
    )
  print(VGGModel)
  #train model:
  Best.Loss <- Inf #pre allocate
  counter20 <- -1
  for(i in 1:160){
    print(paste("epoch:",i))
    
    ## augmentation chunk
    if((i-1)%%20==0  | i==1){
      AugmentList <- mclapply(1:20, function(x){return(TrainArray + rnorm(length(TrainArray), sd=20))},
                              mc.cores = 20)
      counter20 <- counter20+1
    }
    Fit.History <- VGGModel %>% fit(AugmentList[[i-counter20*20]],TrainVect,epochs= 1,
                                    validation_data=list(ValArray,ValVect),
                                    shuffle=TRUE, verbose=2)
    ######
     
    
     # Fit.History <- VGGModel %>% fit(TrainArray,TrainVect,epochs= 1,
     #                                validation_data=list(ValArray,ValVect),
     #                                shuffle=TRUE, verbose=2)
    
    Val.Loss <- Fit.History[[2]]$val_loss
    
    #if loss didnt drop, stop training
    if(Val.Loss<Best.Loss){
      print("New lowest val loss")
      Best.Loss<- Val.Loss
      counter <- 0
      BestModel <- Fit.History
      BestEpoch <- i
      
      VGGModel %>% save_model_hdf5(paste("../Models/Sex_M",ModelName,"_E",i, sep=""))# saves model
      
    }else{
      counter <- counter +1
      #Val.Loss.Prev <- Val.Loss
      if(counter >10){
        print("Val.Loss increased did not drop lower than best for 30 epochs")
        print(paste("Best Model is Epoch", BestEpoch))
        #make a copy of best model:
        system(paste("cp ../Models/Sex_M",ModelName,"_E",BestEpoch," ../Models/BestModelSex-",ModelName, sep=""))
        #remove all the other models for each epoch5
        system(paste("rm ../Models/Sex_M",ModelName,"*", sep=""))
        break #stops looping
      }
    }
  }
  
  return(BestModel)
}


#train simple CNN
TrainSimple <- function(ModelName = 1, CNN,Dense_1,Drop_1,Dense_2,Drop_2){
  SexModel <- keras_model_sequential()%>%
    layer_conv_2d(filters=CNN, kernel_size=c(3,3), activation = 'relu',
                          input_shape=c(256,144,3), data_format="channels_last") %>%
    layer_max_pooling_2d(pool_size = c(3,3)) %>%
    layer_flatten() %>%
    layer_dense(units=Dense_1, activation = 'relu')%>%
    layer_dropout(rate=Drop_1) %>%
    layer_dense(units=Dense_2, activation='relu')%>%
    layer_dropout(rate=Drop_2)%>%
    layer_dense(units=1, activation='sigmoid') %>%
    compile(
      optimizer=optimizer_adam(lr=1e-05),
      loss='binary_crossentropy',
      metrics=c('accuracy')
    )
  #train model:
  Best.Loss <- Inf #pre allocate
  
  for(i in 1:150){
    print(paste("epoch:",i))
    #Augmentation
    # Augment <- TrainArray + rnorm(length(TrainArray), sd=0.1)
    Fit.History <- SexModel %>% fit(TrainArray,TrainVect,epochs= 1,
                                    validation_data=list(ValArray,ValVect),
                                    shuffle=TRUE, bacth_size = 16)
    Val.Loss <- Fit.History[[2]]$val_loss
    
    #if loss didnt drop, stop training
    if(Val.Loss<Best.Loss){
      print("New lowest val loss")
      Best.Loss<- Val.Loss
      counter <- 0
      BestModel <- Fit.History
      BestEpoch <- i
        
      SexModel %>% save_model_hdf5(paste("../Models/Sex_M",ModelName,"_E",i, sep=""))# saves model
      
    }else{
      counter <- counter +1
      #Val.Loss.Prev <- Val.Loss
      if(counter >10){
        print("Val.Loss increased did not drop lower than best for 10 epochs")
        print(paste("Best Model is Epoch", BestEpoch))
        #make a copy of best model:
        system(paste("cp ../Models/Sex_M",ModelName,"_E",BestEpoch," ../Models/BestModelSex-",ModelName, sep=""))
        #remove all the other models for each epoch5
        system(paste("rm ../Models/Sex_M",ModelName,"*", sep=""))
        break #stops looping
      }
    }
  }
  
  return(BestModel)
  
  
}


##Training simple CNN
# Params = list(CNN = c(32,64,128),
#                        Drop_1 = c(0,0.1,0.2), Drop_2 = c(0.1,0.2,0.3),
#                        Dense_1 = c(32,64,128),Dense_2=c(32,64,128))
# 
# ParamComb <- expand.grid(Params)
# ParamComb$Acc <- NA
# ParamComb$Loss <- NA
# ParamComb$ValLoss <- NA
# ParamComb$ValAcc <- NA
# ParamComb <- read.csv("../Data/SimpleCNN.csv")
# 
# for (j in 237:nrow(ParamComb)){
# print(ParamComb[j,])
# History <- TrainSimple(ModelName = j,CNN = ParamComb$CNN[j], Drop_1= ParamComb$Drop_1[j],Drop_2 = ParamComb$Drop_2[j],
#                   Dense_1=ParamComb$Dense_1[j],Dense_2 = ParamComb$Dense_2[j])
# ParamComb[j,"Acc"] <- History[[2]][[2]]
# ParamComb[j,"Loss"] <-  History[[2]][[1]]
# ParamComb[j,"ValLoss"] <- History[[2]][[3]]
# ParamComb[j,"ValAcc"] <- History[[2]][[4]]
# write.csv(ParamComb, file="../Data/SimpleCNN.csv")
# }




#training VGG:
 Params = list(Freeze=c("none","top"),
                        Drop1 = c(0.2,0.3,0.5), Drop2 = c(0.1,0.2,0.3),
                         Dense = c(64,128,256,512), lr=c(1e-05))

 ParamComb <- expand.grid(Params)
 ParamComb$Acc <- NA
 ParamComb$Loss <- NA
 ParamComb$ValLoss <- NA
 ParamComb$ValAcc <- NA

# ParamComb <- read.csv("../Data/VGGGridSearch6.csv")
 for (j in 67:nrow(ParamComb)){
 print(ParamComb[j,])
 History <- TrainVGG(ModelName = j, Freeze=ParamComb$Freeze[j],
                   Drop1= ParamComb$Drop1[j],Drop2 = ParamComb$Drop2[j],
                   Dense=ParamComb$Dense[j],lr=ParamComb$lr[j], Manual=FALSE)
 ParamComb[j,"Acc"] <- History[[2]][[2]]
 ParamComb[j,"Loss"] <-  History[[2]][[1]]
 ParamComb[j,"ValLoss"] <- History[[2]][[3]]
 ParamComb[j,"ValAcc"] <- History[[2]][[4]]
 write.csv(ParamComb, file="../Data/VGGGridSearch6.csv")
 }
