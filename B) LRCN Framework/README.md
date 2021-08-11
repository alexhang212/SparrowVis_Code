# B) LRCN Framework
Next, I attempted using an LRCN framework, which consists of multiplie CNNs stacked to evaluate each frame, then analyzing it using a recurrent layer. I also adopted an early stopping algorithm to stop model training if validation loss doesnt decrease for a set number of epochs.

![LRCN](../Graphics/LRCN.png)  

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
- **TrainSexRNN.R**: LRCN framework to train sex classification model
- **TrainBehav.R**: LRCN framework to train behaviour model
- **TrainTuner.R**: Functions that trains neural networks with hyper parameters as input, allow easier manual hyperparameter tuning.

## Reference
- **Simonyan, K., Zisserman, A.,** 2014. Very deep convolutional networks for large-scale image recognition. arXiv preprint arXiv:1409.1556.