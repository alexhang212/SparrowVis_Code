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


# Root directory of the project
ROOT_DIR = os.path.abspath("../../Mask_RCNN_tf1.x/")

# Import Mask RCNN
sys.path.append(ROOT_DIR)  # To find local version of the library
from mrcnn import utils
from mrcnn import visualize
from mrcnn.visualize import display_images
import mrcnn.model as modellib
from mrcnn.model import log

#%matplotlib inline 
# %matplotlib 

sys.path.append(os.path.join(ROOT_DIR, "samples/custom/"))
import custom
config = custom.CustomConfig()

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
DEVICE = "/gpu:0"  # /cpu:0 or /gpu:0

# Inspect the model in training or inference modes
# values: 'inference' or 'training'
# TODO: code for 'training' test mode not ready yet
TEST_MODE = "inference"

#load modeel
MODEL_PATH = "../Models/mask_rcnn_coco_0010.h5"


with tf.device(DEVICE):
    model = modellib.MaskRCNN(mode="inference", model_dir=MODEL_PATH,
                              config=config)

# Load weights trained on MS-COCO
model.load_weights(MODEL_PATH, by_name=True)

#class names
class_names = ['BG', 'bird']

DATA_DIR = "../ClipFrames/" 
MEERKAT_DIR = "../MeerkatOutput/"
INFER_DIR = "../Inference/"
OUTMASK_DIR = "../OutputMasks"
MASK_DIR = "../Masks/Training/"

##Function to run through 1 video test:
# Video = "VN0386_VP11_W3_20140612"
# RunInference(Video)


def RunInference(Video):
    """Function to run inference for 1 video"""
    Short = pd.read_csv(os.path.join(MEERKAT_DIR, Video, "FramesShort.csv"))
    Short["Instances"] = np.nan

    if not os.path.exists(os.path.join(OUTMASK_DIR, Video)):
        os.makedirs(os.path.join(OUTMASK_DIR, Video))

    for event in Short["Event"]:
        print("Event",event)
        if not os.path.exists(os.path.join(OUTMASK_DIR, Video, "Event{num}".format(num=event))):
            os.makedirs(os.path.join(OUTMASK_DIR, Video,"Event{num}".format(num=event)))

        for i in range(22):
            image = skimage.io.imread(os.path.join(DATA_DIR, Video,"Event{event}".format(event=event),"{i}.png".format(i=i)))
            results = model.detect([image], verbose=1)

            # results:
            r = results[0]
            ##Get masks:
            Mask = GetMask(r,image)

            counter = 0

            if Mask is None:
                print("nothing detected")
            else:
                #Save Masks:
                counter += 1
                cv2.imwrite(os.path.join(OUTMASK_DIR,Video, "Event{num}".format(num=event), "{Vid}_E{Event}_{i}.png".format(Vid=Video, Event=event, i = i)),Mask)
            
        Short.loc[Short["Event"]==event,"Instances"] = counter
    
    Short.to_csv(os.path.join(MEERKAT_DIR, Video, "FramesShort.csv"))


##function to save masks

def GetMask(r, image):
    """read masks, crops image and saves it for training"""
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