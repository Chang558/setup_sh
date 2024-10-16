#!/bin/bash

# PyTorch 설치
cd ~/
echo "Installing PyTorch..."
sleep 3
wget https://developer.download.nvidia.cn/compute/redist/jp/v512/pytorch/torch-2.1.0a0+41361538.nv23.06-cp38-cp38-linux_aarch64.whl  
sudo pip3 install torch-2.1.0*.whl

# 필수 라이브러리 설치
echo "Installing dependencies for torchvision..."

sudo apt-get update
sudo apt-get install -y libjpeg-dev zlib1g-dev libpython3-dev libopenblas-dev libavcodec-dev libavformat-dev libswscale-dev
sudo apt-get install build-essential python3-dev python3-pip libboost-python-dev libboost-thread-dev -y

# TorchVision 설치
echo "Cloning and installing torchvision..."
git clone --branch v0.16.1 https://github.com/pytorch/vision torchvision
cd torchvision
echo "export BUILD_VERSION=0.16.1" >> ~/.bashrc
source ~/.bashrc
echo "After sourcing: $BUILD_VERSION"  # 0.16.1 출력
sleep 5
python3 setup.py install --user
sudo cp -r ~/.local/lib/python3.8/site-packages/torchvision* /usr/local/lib/python3.8/dist-packages/
echo "/usr/local/lib/python3.8/dist-packages/torchvision-0.16.1+fdea156-py3.8-linux-aarch64.egg" | sudo tee /usr/local/lib/python3.8/dist-packages/torchvision.pth
cd ../

# Pillow 버전 설치( python 2.7이하는 필수 )
#echo "Installing compatible Pillow version..."
#pip install 'pillow<7'

# Jetson 기기 모니터링 및 관리 패키지 설치
echo "Installing jetson-stats..."
sudo python3 -m pip install -U jetson-stats==3.1.4

# JetsonYoloV7-TensorRT 깃 클론
echo "Cloning JetsonYoloV7-TensorRT repository..."
git clone https://github.com/mailrocketsystems/JetsonYoloV7-TensorRT.git

# 기타 종속성 설치
echo "Installing other dependencies..."
sudo pip3 install tqdm==4.64.1 numpy==1.23.5 seaborn==0.11.2 imutils==0.5.4 ffmpeg-python==0.2.0 onnx cmake
sudo apt-get install ffmpeg==4.2.7 -y

# pycuda 설치
echo "export PATH=/usr/local/cuda-11.4/bin${PATH:+:${PATH}}" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=/usr/local/cuda-11.4/lib64:$LD_LIBRARY_PATH" >>~/.bashrc
source ~/.bashrc
python3 -m pip install pycuda --user
sudo cp -r /home/terry/.local/lib/python3.8/site-packages/pycuda* /usr/lib/python3.8/dist-packages

# YOLOv7 모델 가중치 변환
echo "Generating weights file..."
cd ~/JetsonYoloV7-TensorRT
python3 gen_wts.py -w yolov7-tiny.pt -o yolov7-tiny.wts

# YOLOv7 엔진 빌드
echo "Building YOLOv7 engine..."
cd yolov7/
mkdir build
cd build
cp ../../yolov7-tiny.wts .
cmake ..
if [ $? -eq 0 ]; then
  echo "cmake is command succeeded."
else
  echo "cmake is command failed. Install Stop"
  exit 1
fi

make
if [ $? -eq 0 ]; then
  echo "make is command succeeded."
else
  echo "make is command failed. Install Stop"
  exit 1
fi


# 스왑 파일 설정 (메모리 부족 시)
echo "Checking for memory issues..."
mem=$( free -h | grep Mem | awk '{print $7}' | sed 's/Gi//')
if (( $(echo "$mem < 3" | bc -l) ));then
  echo "Memory issue detected, creating swapfile..."
  sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  swapon --show
else
  echo "No memory issues detected."
fi

# YOLOv7 엔진 생성 및 실행
echo "Generating and running YOLOv7 engine..."
sudo ./yolov7 -s yolov7-tiny.wts yolov7-tiny.engine t

# YOLOv7 엔진으로 이미지 처리
echo "Running YOLOv7 detection..."
sudo ./yolov7 -d yolov7-tiny.engine ../images

# 설치 파일 삭제 ( 정리 )
cd ~/
sudo rm -rf *.whl
