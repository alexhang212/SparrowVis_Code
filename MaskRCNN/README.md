# MaskRCNN
MaskRCNN (He et. al, 2017) is a deep learning model that computes bounding boxes and masks of objects in an image. The git repository for the model can be found [here](https://github.com/matterport/Mask_RCNN)

I obtained the source code from the git repository and trained a new model by annotating 600 images manually (500 training, 100 validation) using the [VGG image annotator](https://www.robots.ox.ac.uk/~vgg/software/via/via-1.0.6.html) (Dutta & Zisserman, 2019). I followed an [online tutorial](https://thebinarynotes.com/how-to-train-mask-r-cnn-on-the-custom-dataset/) to train the model with my own dataset. 

## Language
MaskRCNN was ran with python 3.7.9

## Dependencies
- Tensorflow 1.15.0
- Opencv-python 3.4.3.18
- Kivy 2.0.0
- Imutils 0.5.4
- Pillow

## Project Structure
**-Code**: Contains a single script to run Deep Meerkat on Imperial's HPC cluster
**-MeerkatInput**: Where input videos are stored  
**-MeerkatOutput**: Where output files are stroed  


## Reference
- **He, K., Gkioxari, G., Dollár, P., Girshick, R.**, 2017. Mask r-cnn, in: Proceedings of the IEEE International Conference on Computer Vision. pp. 2961–2969. 
- **Dutta, A., Zisserman, A.,** 2019. The VIA Annotation Software for Images, Audio and Video, in: Proceedings of the 27th ACM International Conference on Multimedia, MM ’19. ACM, New York, NY, USA. https://doi.org/10.1145/3343031.3350535