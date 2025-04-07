#!/bin/bash

# ONNX Runtime 클론 및 버전 체크아웃
git clone https://github.com/microsoft/onnxruntime.git
cd onnxruntime
git checkout v1.14.1

# 필수 의존성 설치
sudo apt-get update
sudo apt-get -y install --no-install-recommends \
  build-essential software-properties-common libopenblas-dev \
  libpython3.8-dev python3-pip python3-dev python3-setuptools python3-wheel

sudo pip3 install packaging

# 기존 cmake 제거 (선택적)
sudo apt-get -y remove cmake || true

# CMake 3.30.0 강제 설치
echo "CMake 3.30.0을 설치합니다..."
cd ~
wget https://github.com/Kitware/CMake/releases/download/v3.30.0/cmake-3.30.0.tar.gz
tar -zxvf cmake-3.30.0.tar.gz
cd cmake-3.30.0
./bootstrap
make -j$(nproc)
sudo make install
hash -r  # 쉘 경로 리셋
cd ~
rm -rf cmake-3.30.0 cmake-3.30.0.tar.gz

# ONNX Runtime 빌드
cd ~/onnxruntime
./build.sh --config Release --update --build --parallel --build_wheel \
  --use_cuda --cuda_home /usr/local/cuda-11.4 --cudnn_home /usr/lib/aarch64-linux-gnu
