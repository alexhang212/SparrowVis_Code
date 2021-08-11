#read in images, crop it and save array
# rm(list=ls())
library(magick)

#For Testing:
# FileName <- "VO0206_VP11_W22_20150628"
# data <- read.csv(paste("../MeerkatOutput/",FileName,"/","FramesLongCoded.csv", sep=""))
# data <- na.omit(data, data$Sex)
# ProcessImage(FileName,data)

#reads long format data, crops image, then saves array
ProcessImage <- function(FileName, data, imagescale=10, Type = "Training"){
  ImageVal <- array(data=NA, dim=c(nrow(data),1280/imagescale,720/imagescale,3))
  
  #Type can be "Training" or "Test"
if(nrow(data)>0){
  #if there is data:
for(i in 1:nrow(data)){
  Framenum <- data$Frame[i]
  image <- image_read(paste("../MeerkatOutput/",data$FileName[i],"/",Framenum,".jpg", sep=""))
  #crop image:
  cropimage <- image_crop(image,paste(data$w[i]*1.5,"x",data$h[i]*1.5,"+",data$x[i],"+",data$y[i], sep=""))
  
  #add black border around cropped image#
  #get desired height and width:
  ht <- 720/imagescale
  wt <- 1280/imagescale
  cropimagedim <- dim(cropimage[[1]])
  #scale image, keeping aspect ratio:
  cropscale <- image_scale(cropimage, paste(wt,"x",ht, sep=""))
  scaledimagedim <- dim(cropscale[[1]]) #get dimension of scaled image
  
  #add border:
  cropborder <- image_border(cropscale,"black", geometry = paste((wt-scaledimagedim[2])/2,"x",(ht-scaledimagedim[3])/2, sep=""))
  #sometimes, pixel values are not perfect, need to rescale again
  
  finalimage <- image_scale(cropborder, paste(wt,"x",ht,"!",sep=""))
  # browser()
  #plot(finalimage)
  
  #Saving images into correct directory
  VidCode <- strsplit(FileName, "_")[[1]][1]#video code
  
  if(Type == "Training"){
    ImageVal[i,,,] <- as.integer(finalimage[[1]])
    #Data used for training
  if(data$Sex[i] == 0){
    #is a female
  image_write(finalimage, path = paste("../TrainingImages/Training/Female/",VidCode,"-", Framenum,".jpg",sep=""), format="jpg")
  }else{
    #is a male
    image_write(finalimage, path = paste("../TrainingImages/Training/Male/",VidCode,"-", Framenum,".jpg",sep=""), format="jpg")
  }
  
  }else{
    #if not used for training, just save into array for validation
    ImageVal[i,,,] <- as.integer(finalimage[[1]])
    
  }
}
  save(ImageVal, file=paste("../Arrays/",FileName,"_Array.rda", sep=""))
  
}else{
  
  #doing nothing, data has no frames
  
}
  
}

