# C) MaskRCNN Framework
The final approach I used was to classify sex of sparrows using extracted masks from MaskRCNN. For how I trained and extracted masks using MaskRCNN, please refer to [MaskRCNN Directory](https://github.com/alexhang212/SparrowVis_Code/tree/master/MaskRCNN)

A summary of model architectures can be found in [Appendix 3](https://github.com/alexhang212/SparrowVis_Code/blob/master/Writeup/Jupyters/Supplementary3.ipynb)


## Language
R 3.6.1

## Dependencies
- tensorflow 1.14.0
- keras 1.0.8
- magick 2.6.0
- abind 1.4.5
- tidyverse 1.3.0

## Project Structure
- **DataPrep.R**: Prepare data into arrays for training
- **SexAutoML.R**: Train Sex classifier with simple CNN and trasfer learning using VGG19 (Simonyan & Zisserman, 2014) using a grid search algorithm ([Supplmentary 4](https://github.com/alexhang212/SparrowVis_Code/blob/master/Writeup/Jupyters/Supplementary%204.ipynb))
- **Validate.R**: Find the best model from gridsearch
- **ValidateTest.R**: Determine the acuracy of the best model on the test dataset

## Reference
- **Simonyan, K., Zisserman, A.,** 2014. Very deep convolutional networks for large-scale image recognition. arXiv preprint arXiv:1409.1556.