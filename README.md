# Introduce

이 저장소는 Jetson 환경에서 NoMachine, PyTorch, torchvision, YOLOv7 등을 설정하는 다양한 스크립트를 포함하고 있음.

### NoMachine 설정
nomachone 설치 및 ip 설정

### environment_setting.sh 
Jetson 기본 환경 설정 및 구축

### yolov7 setup && pytorch build.sh
yolov7-tiny.pt을 TensorRT 엔진으로 변환하며, 이에 필요한 PyTorch와 Torchvision을 호환성에 맞춰 빌드
version:
   PyTorch v2.0.1
   Torchvision v0.16.1

### onnxruntime-gpu_build.sh
Jetson에서는 onnxruntim-gpu가 없으므로 직접 빌드하여 사용하여야함.
onnxruntime-gpu 빌드하기위한 스크립트임. 시간이 꽤 소모되므로 링크에서 다운받는것을 추천
