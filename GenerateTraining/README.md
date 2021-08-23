# Generate Training
To generate training data for training deep learning models, I tried matching data from manual annotations with the events obtained from Deep Meerkat. 

## Language
R 4.1.0

## Dependencies
- Tidyverse 1.3.0
- magick 2.6.0

## Project Structure
- **Code**: Contains all code used for analysis  
    - **ProcessFrameInfo.R**: Process Meerkat Outputs and define them into events
    - **GenerateTraining**: Matching algorithm to match events from Deep Meerkat to manual annotation
    - **ProcessImages.R**: Process images into arrays
    - **ProcessVideos.R**: Extract clips from events and build arrays from events for model training
    - **OrganizeEvents_Vids.R**: Runs all scripts above for every video
    - **VideoInfo.csv**: Categorization for test and training split for videos between 2014-2015

## Run Project
To run the scripts and generate training data from Meerkat Outputs, make sure you downloaded the full repository from Zenodo, then run the following in the Code directory:

Make sure the raw video of the same video name is in the "RawVideos" directory.
```
Rscript OrganizeEvents_Vids.R
```
This will loop through every video in the "MeerkatOutput" directory, then match the events defined by my pipeline to original annotations. 7 second clips of the events will also be created in the "TrainingClips" directory, together with numerical R arrays in the "ClipArrays" directory.

## Reference
- **Hadfield, J.D.**, 2010. MCMC methods for multi-response generalized linear mixed models: the MCMCglmm R package. Journal of statistical software 33, 1–22.
- **Imperial Collge Research Computing Service**, n.d.