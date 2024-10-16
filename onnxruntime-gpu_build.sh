#!/bin/bash
sudo git clone https://github.com/microsoft/onnxruntime.git

cd onnxruntime

sudo git checkout v1.14.1


sudo apt-get -y install --no-install-recommends build-essential software-properties-common libopenblas-dev libpython3.8-dev python3-pip python3-dev python3-setuptools python3-wheel

sudo pip3 install packaging

cmake_version = $(cmake --version | head -n 1 | awk '{print $3}')

if [ "$(printf '%s\n' "$cmake_version" 3.30 | sort -V | head -n1)" != "3.30" ]; then
    sudo pip3 install cmake
fi

sudo ./build.sh --config Release --update --build --parallel --build_wheel \
 --use_cuda --cuda_home /usr/local/cuda-11.4 --cudnn_home /usr/lib/aarch64-linux-gnu
