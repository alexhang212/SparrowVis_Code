# functions to create tuners/ trial and error for models
require(keras)
require(tidyverse)
require(parallel)

# test parameters:
# imagescale=10
# length=7
# ModelName =1
# lstm_1 =1
# dense_1 =1
# dense_2=2
# dense_3=2
# Aug =1
# Drop1 = 0.1
# Drop2=0.2
# rnn_1 <- 20
# LearnR = 0.001


TrainSex <- function(imagescale=10, length=7, 
                     MainArray,SexVect,Val.Array,Val.SexVect,Augment="Yes",
                     Drop1,Drop2,
                     ModelName,lstm_1,dense_1,dense_2,Aug, LearnR = 1e-05, Retrain="No",
                     ModelNum=1){
if(Retrain=="No"){
  
VGG19 <- load_model_hdf5("../Models/EmptyVGG19")
# 
# freeze_weights(VGG19)#freeze whole CNN
# unfreeze_weights(VGG19,from="block5_conv1") #unfreeze top layers
# 
# #compile:
SexModel <- keras_model_sequential()%>%
  time_distributed(VGG19, input_shape = c((length*5)+1,128,72,3)) %>%
  time_distributed(layer_flatten(), input_shape = c((length*5)+1,4,2,512))%>%
  layer_dropout(rate=Drop1)%>%
  layer_lstm(units=lstm_1,input_shape = c((length*5)+1,4096))%>%
  layer_dropout(rate=Drop2)%>%
  layer_dense(units=dense_1, activation='relu')%>%
  layer_dropout(rate=Drop2)%>%
  layer_dense(units=dense_2, activation='relu')%>%
  layer_dropout(rate=Drop2)%>%
  layer_dense(units=1, activation='sigmoid') %>%
  compile(
    optimizer=optimizer_adam(lr=LearnR),
    loss='binary_crossentropy',
    metrics=c('accuracy')
  )}else{
    #retrain = Yes
    SexModel <- load_model_hdf5(paste("../Models/BestModelSex-",ModelName, sep=""))
    SexModel %>%  compile(
      optimizer=optimizer_adam(lr=LearnR),
      loss='binary_crossentropy',
      metrics=c('accuracy'))
  
  }
  
  ###Model Training
  Val.Loss.Prev <- Inf #pre allocate
  
  for(i in 1:30){
    print(paste("epoch:",i))
    
    #augmentation
    # if(Augment=="Yes"){
    # Augmented <- MainArray + rnorm(length(MainArray), sd=Aug)
    # }else{
    #   Augmented <- MainArray
    # }
    
    Fit.History <- SexModel %>% fit(MainArray,SexVect, epochs = 1, verbose=2,
                                    validation_data = list(Val.Array,Val.SexVect))
    Val.Loss <- Fit.History[[2]]$val_loss
    
    #if loss didnt drop, stop training
    if((Val.Loss.Prev-Val.Loss)> 0){
      print("Val.Loss is dropping, continue training")
      Val.Loss.Prev <- Val.Loss
      counter <- 0
      BestModel <- Fit.History
      BestEpoch <- i
      
      SexModel %>% save_model_hdf5(paste("../Models/TrainedSexRNN_M",ModelName,"_E",i, sep=""))# saves model
      
    }else{
      counter <- counter +1
      #Val.Loss.Prev <- Val.Loss
      if(counter >4){
        print("Val.Loss increased 5 epochs in a row, stop training")
        print(paste("Best Model is Epoch", BestEpoch))
        #make a copy of best model:
        system(paste("cp ../Models/TrainedSexRNN_M",ModelName,"_E",BestEpoch," ../Models/BestModelSex-",ModelName, sep=""))
        #remove all the other models for each epoch
        system(paste("rm ../Models/TrainedSexRNN_M",ModelName,"*", sep=""))
        break #stops looping
      }
    }
  }
  
  #Goes through all 30 loops, still training, just save
  print("30 Epochs finished without stopping, saving final model")
  #make a copy of best model:
  system(paste("cp ../Models/TrainedSexRNN_M",ModelName,"_E",BestEpoch," ../Models/BestModelSex-",ModelName, sep=""))
  #remove all the other models for each epoch
  system(paste("rm ../Models/TrainedSexRNN_M",ModelName,"*", sep=""))
  
  return(BestModel)
}



TrainBehavVGG19 <- function(imagescale=10, length=7, 
                     MainArray,MainVect,Val.Array,Val.Vect,Augment="Yes",
                     ModelName,Drop,lstm_1,dense_1,dense_2,Aug, LearnR = 1e-05, Retrain="No",
                     ModelNum=1){
  if(Retrain=="No"){
    
    VGG19 <- load_model_hdf5("../Models/EmptyVGG19")
    # 
    #freeze_weights(VGG19)#freeze whole CNN
    #unfreeze_weights(VGG19,from="block5_conv1") #unfreeze top layers
    # 
    # #compile:
    BehavModel <- keras_model_sequential()%>%
      time_distributed(VGG19, input_shape = c((length*5)+1,128,72,3)) %>%
      time_distributed(layer_flatten(), input_shape = c((length*5)+1,4,2,512))%>%
      layer_dropout(rate=Drop)%>%
      layer_lstm(units=lstm_1,input_shape = c((length*5)+1,4096))%>%
      layer_dropout(rate=0.3)%>%
      layer_dense(units=dense_1, activation='relu')%>%
      layer_dropout(rate=0.3)%>%
      layer_dense(units=dense_2, activation='relu')%>%
      layer_dropout(rate=0.3)%>%
      layer_dense(units=3, activation='softmax') %>%
      compile(
        optimizer=optimizer_adam(lr=LearnR),
        loss='sparse_categorical_crossentropy',
        metrics=c('accuracy')
      )}else{
        #retrain = Yes
        BehavModel <- load_model_hdf5(paste("../Models/BestModelBehav-",ModelName, sep=""))
        BehavModel %>%  compile(
          optimizer=optimizer_adam(lr=LearnR),
          loss='sparse_categorical_crossentropy',
          metrics=c('accuracy'))
        
      }

  ###Model Training
  Val.Loss.Prev <- Inf #pre allocate
  counter <- 5
  
  for(i in 1:30){
    print(paste("epoch:",i))
    
    #augmentation
    if(Augment=="Yes"){
      #augmentation:
      if(counter ==5){
        #parallel augmentation for 5 arrays
        AugmentedList <- mclapply(1:5, FUN= function(x){
          return(MainArray + rnorm(length(MainArray), sd=Aug))}, mc.cores=32)
        counter <- 0
      }
      
      counter <- counter+1 #update counter
      Fit.History <- BehavModel %>% fit(AugmentedList[[counter]],MainVect, epochs = 1, verbose=2,
                                        validation_data = list(Val.Array,Val.Vect))
    }else{
      #no augmentation:
      Fit.History <- BehavModel %>% fit(MainArray,MainVect, epochs = 1, verbose=2,
                                        validation_data = list(Val.Array,Val.Vect))
    }
    

    Val.Loss <- Fit.History[[2]]$val_loss
    
    #if loss didnt drop, stop training
    if((Val.Loss.Prev-Val.Loss)> 0){
      print("Val.Loss is dropping, continue training")
      Val.Loss.Prev <- Val.Loss
      counter <- 0
      BestModel <- Fit.History
      BestEpoch <- i
      
      BehavModel %>% save_model_hdf5(paste("../Models/TrainedBehavRNN_M",ModelName,"_E",i, sep=""))# saves model
      
    }else{
      counter <- counter +1
      #Val.Loss.Prev <- Val.Loss
      
      if(counter >4){
        print("Val.Loss increased 5 epochs in a row, stop training")
        print(paste("Best Model is Epoch", BestEpoch))
        #make a copy of best model:
        system(paste("cp ../Models/TrainedBehavRNN_M",ModelName,"_E",BestEpoch," ../Models/BestModelBehav-",ModelName, sep=""))
        #remove all the other models for each epoch
        system(paste("rm ../Models/TrainedBehavRNN_M",ModelName,"*", sep=""))
        break #stops looping
      }
    }
  }
  
  #Goes through all 30 loops, still training, just save
  print("30 Epochs finished without stopping, saving final model")
  #make a copy of best model:
  system(paste("cp ../Models/TrainedBehavRNN_M",ModelName,"_E",BestEpoch," ../Models/BestModelBehav-",ModelName, sep=""))
  #remove all the other models for each epoch
  system(paste("rm ../Models/TrainedBehavRNN_M",ModelName,"*", sep=""))
  
  return(BestModel)
}



TrainBehavVGG16 <- function(imagescale=10, length=7, 
                            MainArray,MainVect,Val.Array,Val.Vect,Augment="Yes",
                            ModelName,Drop,Drop2,lstm_1,rnn_1,dense_1,dense_2,
                            dense_3,Aug, LearnR = 1e-05, Retrain="No",ModelNum=1){
  if(Retrain=="No"){
    #first time: download model and save it:
    # VGG16 <- application_vgg16(include_top = FALSE, weights="imagenet", input_shape = c(128,72,3))
    # VGG16 %>% save_model_hdf5("../Models/EmptyVGG16")
    
    VGG16 <- load_model_hdf5("../Models/EmptyVGG16")
    # 
    freeze_weights(VGG16)#freeze whole CNN
    unfreeze_weights(VGG16,from="block5_conv1") #unfreeze top layers
    # 
    # #compile:
    BehavModel <- keras_model_sequential()%>%
      time_distributed(VGG16, input_shape = c((length*5)+1,128,72,3)) %>%
      time_distributed(layer_flatten(), input_shape = c((length*5)+1,4,2,512))%>%
      layer_dropout(rate=Drop)%>%
      layer_simple_rnn(units=rnn_1,batch_input_shape = c((length*5)+1,4096))%>%
      layer_dropout(rate=Drop2)%>%
      layer_dense(units=dense_1, activation='relu')%>%
      layer_dropout(rate=Drop2)%>%
      layer_dense(units=dense_2, activation='relu')%>%
      layer_dropout(rate=Drop2)%>%
      layer_dense(units=dense_3)%>%
      layer_dense(units=3, activation='softmax') %>%
      compile(
        optimizer=optimizer_adam(lr=LearnR),
        loss='sparse_categorical_crossentropy',
        metrics=c('accuracy')
      )
    }else{
        #retrain = Yes
        BehavModel <- load_model_hdf5(paste("../Models/BestModelBehav16-",ModelName, sep=""))
        BehavModel %>%  compile(
          optimizer=optimizer_adam(lr=LearnR),
          loss='sparse_categorical_crossentropy',
          metrics=c('accuracy'))
        
      }
  
BehavModel


  ###Model Training
  Val.Loss.Prev <- Inf #pre allocate
  Counter <- 5 #initialize counter for augmentation
  
  for(i in 1:30){
    print(paste("epoch:",i))
    
    #augmentation
    if(Augment=="Yes"){
      
      if(counter ==5){
      #parallel augmentation for 10 arrays
      AugmentedList <- mclapply(1:5, FUN= function(x){
        return(MainArray + rnorm(length(MainArray), sd=Aug))}, mc.cores=32)
      counter <- 0
      }
      
      counter <- counter+1 #update counter
      Fit.History <- BehavModel %>% fit(AugmentedList[[counter]],MainVect, epochs = 1, verbose=2,
                                        validation_data = list(Val.Array,Val.Vect))
    }else{
        #no augmentation
      Fit.History <- BehavModel %>% fit(MainArry,MainVect, epochs = 1, verbose=2,
                                        validation_data = list(Val.Array,Val.Vect))
    }
    

    Val.Loss <- Fit.History[[2]]$val_loss
    
    #if loss didnt drop, stop training
    if((Val.Loss.Prev-Val.Loss)> 0){
      print("Val.Loss is dropping, continue training")
      Val.Loss.Prev <- Val.Loss
      counter <- 0
      BestModel <- Fit.History
      BestEpoch <- i
      
      BehavModel %>% save_model_hdf5(paste("../Models/TrainedBehavRNN_M",ModelName,"_E",i, sep=""))# saves model
      
    }else{
      counter <- counter +1
      #Val.Loss.Prev <- Val.Loss
      
      if(counter >4){
        print("Val.Loss increased 5 epochs in a row, stop training")
        print(paste("Best Model is Epoch", BestEpoch))
        #make a copy of best model:
        system(paste("cp ../Models/TrainedBehavRNN_M",ModelName,"_E",BestEpoch," ../Models/BestModelBehav-",ModelName, sep=""))
        #remove all the other models for each epoch
        system(paste("rm ../Models/TrainedBehavRNN_M",ModelName,"*", sep=""))
        break #stops looping
      }
    }
  }
  
  #Goes through all 30 loops, still training, just save
  print("30 Epochs finished without stopping, saving final model")
  #make a copy of best model:
  system(paste("cp ../Models/TrainedBehavRNN_M",ModelName,"_E",BestEpoch," ../Models/BestModelBehav16-",ModelName, sep=""))
  #remove all the other models for each epoch
  system(paste("rm ../Models/TrainedBehavRNN_M",ModelName,"*", sep=""))
  
  return(BestModel)
}

