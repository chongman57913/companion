#!/bin/bash

# Tensorflow
sudo apt-get install libhdf5-serial-dev hdf5-tools libhdf5-dev zlib1g-dev zip libjpeg8-dev liblapack-dev libblas-dev gfortran
	
sudo pip3 install -U numpy==1.16.1 future==0.17.1 mock==3.0.5 gast==0.2.2 futures protobuf pybind11 h5py==2.9.0 keras_preprocessing==1.0.5 keras_applications==1.0.8
sudo pip3 install https://developer.download.nvidia.com/compute/redist/jp/v44/tensorflow/tensorflow-1.15.2+nv20.4-cp36-cp36m-linux_aarch64.whl

# Pytorch 1.5 For JetPack 4.4
cd $HOME
wget https://nvidia.box.com/shared/static/3ibazbiwtkl181n95n9em3wtrca7tdzp.whl -O torch-1.5.0-cp36-cp36m-linux_aarch64.whl
sudo apt-get install libopenblas-base libopenmpi-dev 
sudo pip3 install -U Cython
sudo pip3 install torch-1.4.0-cp36-cp36m-linux_aarch64.whl
rm torch-1.5.0-cp36-cp36m-linux_aarch64.whl



