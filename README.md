nomachine 폴더는 홈디렉토리에 파일 통째로 옮겨서 사용.
nomahine.sh는 스크립트 실행후 ip를 맞게 설정해줘야함
sudo apt-get -y install ifupdwon
설치후 스크립트의 주석처리한 부분에 맞게 ip를 수정한후 networking.service 재시작하여 ip를 설정해준다.
또한 설치된 nomachine에 들어가서 포트에 맞게 설정을 해주어야 원격 접속이 가능하다.


environment_setting.sh 는 기본적인 셋팅으로
원격터미널에 사용할 xfce4 터미널, vsftpd, nvme 마운트, jetson_stats, jetpack 5.1.2를 셋팅 하는 스크립트

torchvision && pytorch build.sh는
Pytorch v2.0.1버전과 torchvision v0.16.1 버전을 빌드하는 스크립트

yolov7 setup && pytorch build.sh는
yolov7-tiny.pt를 engine으로 만드는 작업과 그에 필요한 pytorch, torchvision및 여러 파일들의 버전을 호환성에 맞게 빌드하는 스크립트