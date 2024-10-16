# Introduce

이 저장소는 Jetson 환경에서 NoMachine, PyTorch, torchvision, YOLOv7 등을 설정하는 다양한 스크립트를 포함하고 있음.

### NoMachine 설정

`nomachine` 폴더를 홈 디렉터리로 이동한 후, `nomachine.sh` 스크립트를 실행
IP 설정을 적절하게 수정해야 하고, `ifupdown` 패키지를 설치후 ip 수정.
그후, 네트워킹 서비스를 재시작하여 IP 설정을 적용
IP 설정이 완료되었다면, NoMachine 프로그램에서 원격 접속이 가능하도록 포트 설정

### environment_setting.sh 
이 스크립트는 Jetson 환경에서 기본적인 설정을 자동으로 수행함.
  XFCE4 터미널: 원격 접속용 가벼운 터미널 설치
  VSFTPD: FTP 서버 설치 및 설정
  NVMe 마운트: NVMe 저장 장치를 자동 마운트
  Jetson Stats: 성능 모니터링 도구 설치
  JetPack 5.1.2: JetPack 5.1.2 설치

### torchvision && pytorch build.sh
Jetson 5.1.2버전과 호환되는 PyTorch와 Torchvision을 설치
version : 
  PyTorch v2.0.1
  Torchvision v0.16.1


### yolov7 setup && pytorch build.sh
yolov7-tiny.pt을 TensorRT 엔진으로 변환하며, 이에 필요한 PyTorch와 Torchvision을 호환성에 맞춰 빌드
