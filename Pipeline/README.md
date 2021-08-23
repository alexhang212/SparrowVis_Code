# Pipeline
This repository contains code to run through whole auto data collection pipeline, from Deep Meerkat frames to event definitions, to masks extraction by MaskRCNN to sex inference

All models and Meerkat Ouput files can be found in the dropbox link at the end of the written report.

## Language
The pipeline was ran with python 3.7.9 and R 4.1.0

## Dependencies
- **Python**
    - pandas 1.2.4
    - moviepy 1.0.3
- **R**
    - tensorflow 1.14.0
    - keras 1.0.8
    - magick 2.6.0
    - abind 1.4.5
    - tidyverse 1.3.0


## Project Structure
- **ProcessFrameInfo.R**: Process Meerkat Outputs and define them into events
- **OrganizeEvents.R**: Runs script above for every video
- **ExtractFrames.py**: Extract 7 second clips and frames from each event from raw videos
- **RunExtractFrames.sh/ RunOrganizeEvents.sh**: Runs event definition and clip extraction in parallel on Imperial's Research Computing service
- **MeerkatReturnRate.R**: Calculate return rate of deep meerkat and undergraduate data

## Running the Pipeline
To run the pipeline, first follow instructions to process all videos using [Deep Meerkat](https://github.com/alexhang212/SparrowVis_Code/tree/master/DeepMeerkat), then place the raw video in the "MeerkatInput" directory, and meerkat output folder in the "MeerkatOutput" directory. Make sure the file name of the video name matches the Meerkat output folder name. 

To define events, run:
```
Rscript OrganizeEvents.R
```

To get output clips and frames, run:
```
python ExtractFrames.py
```

## Reference
- **Imperial Collge Research Computing Service**, n.d.