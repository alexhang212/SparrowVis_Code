#!/usr/bin/env python3
"""Runs through all training vids to extract masks and run inference"""

import os
import sys
import random
import math
import re
import time
import numpy as np
import tensorflow as tf
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import skimage.io
import pandas as pd
import cv2
import multiprocessing as mp


# Root directory of the project
ROOT_DIR = os.path.abspath("~/Documents/Mask_RCNN_tf2.x/")

# Import Mask RCNN
sys.path.append(ROOT_DIR)  # To find local version of the library
from mrcnn import utils
from mrcnn import visualize
from mrcnn.visualize import display_images
import mrcnn.model as modellib
from mrcnn.model import log

%matplotlib inline 
# %matplotlib 
# Directory to save logs and trained model
MODEL_DIR = os.path.join(ROOT_DIR, "logs")

sys.path.append(os.path.join("../../../Mask_RCNN_tf1.x/", "samples/custom/"))
import custom
config = custom.CustomConfig()

DATA_DIR = "../ClipFrames/"  #TODO: enter value here

class InferenceConfig(config.__class__):
    # Run detection on one image at a time
    GPU_COUNT = 1
    IMAGES_PER_GPU = 1

config = InferenceConfig()
config.display()



# Device to load the neural network on.
# Useful if you're training a model on the same 
# machine, in which case use CPU and leave the
# GPU for training.
DEVICE = "/cpu:0"  # /cpu:0 or /gpu:0

# Inspect the model in training or inference modes
# values: 'inference' or 'training'
# TODO: code for 'training' test mode not ready yet
TEST_MODE = "inference"

#load modeel
MODEL_PATH = "../Models/mask_rcnn_coco_0010.h5"


with tf.device(DEVICE):
    model = modellib.MaskRCNN(mode="inference", model_dir=MODEL_DIR,
                              config=config)

# Load weights trained on MS-COCO
model.load_weights(MODEL_PATH, by_name=True)

#class names
class_names = ['BG', 'bird']

MEERKAT_DIR = "../MeerkatOutput/"
INFER_DIR = "../Inference/"
MASK_DIR = "../Masks/Training/"

VidInfo = pd.read_csv("../Data/VideoInfo.csv")

##Function to run through 1 video test:
# Video = "VN0546_VP7_LM6_20140628"
# RunInference(Video)


def RunInference(Video):
    """Function to run inference for 1 video"""
    Short = pd.read_csv(os.path.join(MEERKAT_DIR, Video, "FramesShortCoded.csv"))
    Short.dropna(subset=['EventDes'], how = "all", inplace= True)
    
    if not os.path.exists(os.path.join(INFER_DIR, Video)):
        os.makedirs(os.path.join(INFER_DIR, Video))

    #determine training or test dataset
    Type= VidInfo[VidInfo["FileName"]==Video]["Type"]

    if Type == "Training":
        MASK_DIR = "../Masks/Training/"
    else:
        MASK_DIR = "../Masks/Test/"


    for event in Short["Event"]:
        print("Event",event)
        if not os.path.exists(os.path.join(INFER_DIR, Video, "Event{num}".format(num=event))):
            os.makedirs(os.path.join(INFER_DIR, Video,"Event{num}".format(num=event)))
        
        #get sex of this event
        Sex = int(Short[Short["Event"]==event]["Sex"]) #1 is male, 0 is female

        for i in range(22):
            image = skimage.io.imread(os.path.join(DATA_DIR, Video,"Event{event}".format(event=event),"{i}.png".format(i=i)))
            results = model.detect([image], verbose=1)

            # results:
            r = results[0]

            #save instances with masks drawn on
            visualize.display_instances(image, r['rois'], r['masks'], r['class_ids'], 
                                        class_names, r['scores'], FileName = os.path.join(INFER_DIR, Video,"Event{event}".format(event=event),str(i)))
            plt.close()

            ##Get masks:
            Mask = GetMask(r,image)

            if Mask is None:
                print("nothing detected")
            else:
                SexCode = ["Female","Male"]

                #Save Masks:
                cv2.imwrite(os.path.join(MASK_DIR, SexCode[Sex],"{Vid}_E{Event}_{i}.png".format(Vid=Video, Event=event, i = i)),Mask)
    
                


##function to save masks

def GetMask(r, image):
    """read masks, crops image and saves it"""
    scores = r['scores']

    if len(scores) == 0:
        #no event
        return None
    else:
        #bird detected
        index = int(np.where(scores==max(scores))[0]) #find index of highest scores

        if scores[index] < 0.97:
            #confidence score is low, return None
            return None
        else:
            #read in masks
            mask = r["masks"]
            mask = mask.astype(int)

            #create padded mask
            padd = np.ones((12,12))
            paddMask = cv2.filter2D(mask[:,:,index], 1, padd)
            paddMask = paddMask.astype(bool).astype(int)

            if 1 not in paddMask: ##weird bug where there is a score, but no mask
                return None

            for j in range(image.shape[2]):
                image[:,:,j] = image[:,:,j] * paddMask[:,:]


            maskDim = np.where(paddMask[:,:]==1) # get dimensions of where the mask is

            crop = image[min(maskDim[0]):max(maskDim[0]), min(maskDim[1]):max(maskDim[1]), :]

            ResizedCrop = padding(crop, 144,256)
            return ResizedCrop


def padding(image,hh,ww):
    """Add Black Padding around desired ht and wt"""

    ht, wd, cc= image.shape # original shapes

    if ht > hh or wd > ww:
        height_percent = hh/ht
        width_percent = ww/wd 
        scale_percent = min([height_percent,width_percent])
        dim = (int(image.shape[1]*scale_percent), int(image.shape[0]*scale_percent))
        image = cv2.resize(image,dim)
        ht, wd, cc= image.shape

    color = (0,0,0)
    result = np.full((hh,ww,cc), color, dtype=np.uint8)

    # compute center offset
    xx = (ww - wd) // 2
    yy = (hh - ht) // 2

    # copy img image into center of result image
    result[yy:yy+ht, xx:xx+wd] = image
    return result



#### Run Videos in parallel
def main(argv):
    """Main function to Run"""
    #dirs:
    DirNames = os.listdir(DATA_DIR)

    for Name in DirNames:
        RunInference(Name)


if __name__ == "__main__":
	status = main(sys.argv)
	sys.exit(status)