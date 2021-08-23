# Sparrow Vis: A framework to analyse and annotate sparrow provisioning videos
This repository contains all code used for the thesis: **Testing the silver spoon effect in a passerine using novel deep learning and computer vision pipeline**. Please read project structure below to access seperate directories for each part of the project.

Please request access to the full repository in the [Zenodo repository](https://doi.org/10.5281/zenodo.5239646) to run ceratain parts of the project which may contain sensitive data. The Zenodo repository also contains additional data samples.

## Language & Dependencies
Please see README in seperate directories for section specific dependencies.  

## Project Structure
Directories and its contents:  

- [**DeepMeerkat**](https://github.com/alexhang212/SparrowVis_Code/tree/master/DeepMeerkat): Code and guidance to run Deep Meerkat  
- [**MaskRCNN**](https://github.com/alexhang212/SparrowVis_Code/tree/master/MaskRCNN): Code and guidance to run MaskRCNN and obtain masks of sparrows  
- [**Analysis**](https://github.com/alexhang212/SparrowVis_Code/tree/master/Analysis): Code to run all silver spoon analysis  
- [**Writeup:**](https://github.com/alexhang212/SparrowVis_Code/tree/master/Writeup): Contain figures and supplementary information for writeup  
- [**Pipeline**](https://github.com/alexhang212/SparrowVis_Code/tree/master/Pipeline): Code to process videos from Deep Meerkat Output to events to clips 
- [**GenerateTraining**](https://github.com/alexhang212/SparrowVis_Code/tree/master/GenerateTraining): Generate training data by matching meerkat events with previously annotated data 
- [**A) DeepMeerkat Framework**](https://github.com/alexhang212/SparrowVis_Code/tree/master/A\)%20DeepMeerkat%20Framework): Training classification models for Deep Meerkat frames  
- [**B) LRCN Framework**](https://github.com/alexhang212/SparrowVis_Code/tree/master/B\)%20LRCN%20Framework): Training classification models for 7 second clips  
- [**C) MaskRCNN Framework**](https://github.com/alexhang212/SparrowVis_Code/tree/master/C\)%20MaskRCNN%20Franework): Trianing classification models for MaskRCNN masks   

## Deep Learning approaches used
![Pipeline](Graphics/Pipeline.png)  

## Author and Affiliations
Alex Chan Hoi Hang  
hhc4317@ic.ac.uk  
MRes Computational Methods in Ecology and Evolution  
Department of Life Sciences  
Imperial College Silwood Park  
UK. SL5 7PY  
