#!/usr/bin/env python3
"""Combines all videos that are split into multiple parts"""

import tensorflow as tf
from tensorflow import keras
import numpy as np
import autokeras as ak
import os
from PIL import Image

Model = "../Models/BestModel_0.69.h5"

SexModel = keras.models.load_model(Model)

#get all dir names
dir = "../OutputMasks/"
DirNames = []
for root, dirs, files in os.walk(dir, topdown=False):
    if root == dir: #to just get 1 layer
        DirNames += dirs

for vid in DirNames:
    for event in  os.listdir("../OutputMasks/{vid}".format(vid=vid)):
        images = os.listdir("../OutputMasks/{vid}/{event}".format(vid=vid, event=event))
        array = np.array([np.array(Image.open("../OutputMasks/{vid}/{event}/{image}".format(vid=vid, event=event, image=image))) for image in images])
        array = array.transpose(0,2,1,3)
        prediction = SexModel.predict(array)


array.shape
SexModel.input
