# Deep Meerkat
Deep Meerkat (Weinstein, 2018) is an opensource software that uses convolutional neural networks to identify and classify movement in ecological videos. The webpage for the software can be found [here](http://benweinstein.weebly.com/deepmeerkat.html).

I obtained the source code from the git repository and ran the software using command line with Imperial College London's research computing service, by running multiple videos in parallel. Original source code is not included in this repository, please refer to the software's original [repository](https://github.com/bw4sz/DeepMeerkat).

## Langugae
Deep Meerkat was ran with python 3.7.9

## Dependencies
- Tensorflow 1.15.0
- Opencv-python 3.4.3.18
- Kivy 2.0.0
- Imutils 0.5.4
- Pillow

## Project Structure
- **Code**: Contains a single script to run Deep Meerkat on Imperial's HPC cluster
- **MeerkatInput**: Where input videos are stored  
- **MeerkatOutput**: Where output files are stored  


## Reference
- **Weinstein, B.G.**, 2018. Scene‐specific convolutional neural networks for video‐based biodiversity detection. Methods in Ecology and Evolution 9, 1435–1441.  
- **Imperial Collge Research Computing Service**, n.d.