#!/bin/bash

USERNAME=terry

cd /home/$USERNAME

echo "Installing PyTorch v2.1.0..."
sleep 4

wget https://developer.download.nvidia.cn/compute/redist/jp/v512/pytorch/torch-2.1.0a0+41361538.nv23.06-cp38-cp38-linux_aarch64.whl  
sudo pip3 install torch-2.1.0*.whl
sleep 2

rm -rf *.whl
echo "Installing dependencies for torchvision"
sleep 4

sudo apt-get update
sudo apt-get install -y libjpeg-dev zlib1g-dev libpython3-dev libopenblas-dev libavcodec-dev libavformat-dev libswscale-dev
sudo apt-get install build-essential python3-dev python3-pip libboost-python-dev libboost-thread-dev -y

echo "Installing torchvision"
sleep 4

echo "Cloning and installing torchvision..."
git clone --branch v0.16.1 https://github.com/pytorch/vision torchvision
cd torchvision
echo "export BUILD_VERSION=0.16.1" >> ~/.bashrc
source ~/.bashrc
echo "After sourcing: $BUILD_VERSION"  # 0.16.1 출력
sleep 5
sudo python3 setup.py install
cd ../

echo "export PATH=/usr/local/cuda-11.4/bin${PATH:+:${PATH}}" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=/usr/local/cuda-11.4/lib64:$LD_LIBRARY_PATH" >>~/.bashrc
source ~/.bashrc
sudo python3 -m pip install pycuda
sudo cp -r /home/terry/.local/lib/python3.8/site-packages/pycuda* /usr/lib/python3.8/dist-packages

if nvcc --version > /dev/null 2>&1; then
    echo "Success to install PyTorch"
    sleep 5
else
    echo "Fail to install PyTorch"
    sleep 5
fi



