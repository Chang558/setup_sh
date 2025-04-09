#!/bin/bash
set -e

USERNAME=$(logname)

#sudo chown -R $USER:$USER ~/
sudo find ~ -mindepth 1 -maxdepth 1 ! -name "thinclient_drives" -exec chown -R $USER:$USER {} \;

echo ""
echo "YOLO 엔진 빌드 선택:"
echo "1 - YOLOv7만 빌드"
echo "2 - YOLOv8-pose만 빌드"
echo "3 - 둘 다 빌드"
read -p "선택 (1/2/3): " BUILD_OPTION

# PyTorch 설치
# PyTorch 자동 확인 및 설치 (JetPack 5.1.2용)
echo ""
echo "===================[0] Checking PyTorch installation for JetPack 5.1.2]==================="
echo ""

PYTORCH_VERSION=$(python3 -c "import torch; print(torch.__version__)" 2>/dev/null || echo "none")

if [[ "$PYTORCH_VERSION" == "2.1.0a0+41361538.nv23.06" ]]; then
    echo "PyTorch가 이미 설치되어 있습니다. 설치를 건너뜁니다."
else
    mkdir -p ~/library/etc
    cd ~/library/etc
    if [ ! -f torch-2.1.0a0+41361538.nv23.06-cp38-cp38-linux_aarch64.whl ]; then
        wget https://developer.download.nvidia.cn/compute/redist/jp/v512/pytorch/torch-2.1.0a0+41361538.nv23.06-cp38-cp38-linux_aarch64.whl
    fi
    pip3 install torch-2.1.0a0+41361538.nv23.06-cp38-cp38-linux_aarch64.whl
fi


# TorchVision 설치
echo ""
echo "===================[1] Checking TorchVision installation for JetPack 5.1.2]==================="
echo ""

TV_VERSION=$(python3 -c "import torchvision; print(torchvision.__version__)" 2>/dev/null || echo "none")

if [[ "$TV_VERSION" == "0.16.1+fdea156" ]]; then
    echo "TorchVision가 이미 설치되어 있습니다. "
else
    sudo apt-get install -y libjpeg-dev zlib1g-dev libpython3-dev libopenblas-dev libavcodec-dev libavformat-dev libswscale-dev
    sudo apt-get install -y build-essential python3-dev python3-pip libboost-python-dev libboost-thread-dev

    cd ~/library
    git clone --branch v0.16.1 https://github.com/pytorch/vision torchvision
    cd torchvision
    python3 setup.py install --user
    sudo cp -r ~/.local/lib/python3.8/site-packages/torchvision* /usr/local/lib/python3.8/dist-packages/
    echo "/usr/local/lib/python3.8/dist-packages/torchvision-0.16.1+fdea156-py3.8-linux-aarch64.egg" | sudo tee /usr/local/lib/python3.8/dist-packages/torchvision.pth
fi

echo "===================cmake install ==================="
CMAKE_VERSION=3.30.8

# 현재 CMake 버전 확인
CURRENT_CMAKE_VERSION=$(cmake --version 2>/dev/null | grep -oP '(?<=version )[^ ]+' || echo "0.0.0")

# 버전 비교 함수
version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

if version_ge "$CURRENT_CMAKE_VERSION" "3.30.0"; then
    echo "cmake 3.30 이상, 스킵"
else
    cd ~/library/etc
    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
    tar -zxvf cmake-${CMAKE_VERSION}.tar.gz
    cd cmake-${CMAKE_VERSION}
    ./bootstrap --prefix=/usr/local
    make -j$(nproc)
    sudo make install
fi

# Pillow 버전 설치( python 2.7이하는 필수 )
#echo "Installing compatible Pillow version..."
#pip install 'pillow<7'
if [[ "$BUILD_OPTION" == "1" || "$BUILD_OPTION" == "3" ]]; then


  # JetsonYoloV7-TensorRT 깃 클론
  echo ""
  echo "===================[2] Cloning JetsonYoloV7-TensorRT repository==================="
  echo ""

  # YOLOv7 repo 클론

  mkdir -p /home/terry/yolo
  cd ~/yolo

  if [ -d "JetsonYoloV7-TensorRT" ]; then
      echo "JetsonYoloV7-TensorRT 디렉토리가 이미 존재합니다. 클론 생략."
  else
      git clone https://github.com/mailrocketsystems/JetsonYoloV7-TensorRT.git
  fi

  # 기타 종속성 설치
  echo ""
  echo "===================[3] Installing other dependencies==================="
  echo ""

  sudo pip3 install tqdm==4.64.1 numpy==1.23.5 seaborn==0.11.2 imutils==0.5.4 ffmpeg-python==0.2.0 onnx 
  sudo apt-get install ffmpeg -y

  # pycuda 설치
  echo 'export PATH=/usr/local/cuda-11.4/bin:$PATH' >> /home/$USERNAME/.bashrc
  echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.4/lib64:$LD_LIBRARY_PATH' >> /home/$USERNAME/.bashrc

  export PATH=/usr/local/cuda-11.4/bin:$PATH
  export LD_LIBRARY_PATH=/usr/local/cuda-11.4/lib64:$LD_LIBRARY_PATH
  # 적용은 다음 로그인 때 반영되므로 지금 쉘에서 직접 적용
  sudo -u $USERNAME bash -c "source /home/$USERNAME/.bashrc"


  if ! command -v nvcc &> /dev/null; then
      echo "nvcc 명령어 에러. 확인 필요"
      exit 1
  fi

  python3 -m pip install pycuda --user
  #sudo cp -r /home/terry/.local/lib/python3.8/site-packages/pycuda* /usr/lib/python3.8/dist-packages


  # YOLOv7 모델 가중치 변환
  echo ""
  echo "===================[4] Generating weights file==================="
  echo ""

  cd ~/yolo/JetsonYoloV7-TensorRT
  python3 gen_wts.py -w yolov7-tiny.pt -o yolov7-tiny.wts

  # YOLOv7 엔진 빌드
  echo "Building YOLOv7 engine..."
  cd yolov7/
  rm -rf build
  mkdir build
  cd build
  cp ../../yolov7-tiny.wts .
  sudo cmake .. && sudo make


  # 스왑 파일 설정 (메모리 부족 시)
  echo ""
  echo "===================[5] Checking for memory issues==================="
  echo ""

  mem=$( free -h | grep Mem | awk '{print $7}' | sed 's/Gi//')
  if (( $(echo "$mem < 3" | bc -l) ));then
    echo "Memory issue detected, creating swapfile..."
    sudo dd if=/dev/zero of=/swapfile bs=1M count=10240
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
  echo ""
  echo "===================[6] Running YOLOv7 detection==================="
  echo ""

  sudo ./yolov7 -d yolov7-tiny.engine ../images
fi

if [[ "$BUILD_OPTION" == "2" || "$BUILD_OPTION" == "3" ]]; then
    echo ""
    echo "===================[7] YOLOv8-pose engine build==================="
    echo ""

    # yolov8 requirements.txt 
    sudo pip3 install python-dateutil==2.8.2
    sudo pip3 install numpy==1.23.5
    sudo pip3 install onnx 
    sudo pip3 install opencv-python
    sudo pip3 install ultralytics
    echo "===================onnxsim 설치 중...==================="


    cd ~/library
    sudo rm -rf onnx-simplifier
    git clone https://github.com/daquexian/onnx-simplifier.git

    cd onnx-simplifier
    
    sed -i 's|git@github.com:onnx/optimizer.git|https://github.com/onnx/optimizer.git|' .gitmodules
    sed -i 's|git@github.com:microsoft/onnxruntime.git|https://github.com/microsoft/onnxruntime.git|' .gitmodules
    sed -i 's|git@github.com:pybind/pybind11.git|https://github.com/pybind/pybind11.git|' .gitmodules

    git submodule sync
    git submodule update --init --recursive

    pip3 install -r requirements.txt
    sudo python3 setup.py install 

    mkdir -p ~/yolo
    cd ~/yolo
    if [ ! -d YOLOv8-TensorRT ]; then
        git clone https://github.com/triple-Mu/YOLOv8-TensorRT.git
    fi
    cd YOLOv8-TensorRT

    yolo export model=yolov8s-pose.pt format=onnx opset=11 simplify=True

    /usr/src/tensorrt/bin/trtexec --onnx=yolov8s-pose.onnx --saveEngine=yolov8s-pose.engine --fp16

    python3 infer-pose.py --engine yolov8s-pose.engine --imgs data --show --out-dir outputs --device cuda:0
fi