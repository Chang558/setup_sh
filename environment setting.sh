#!/bin/bash

# 사용자 설정
USERNAME=terry

# sudoers에 안전한 방식으로 추가 (중복 확인 후 추가)
if ! sudo grep -q "$USERNAME ALL=NOPASSWD: ALL" /etc/sudoers; then
    echo "$USERNAME ALL=NOPASSWD: ALL" | sudo tee -a /etc/sudoers
fi

# dpkg 잠금 파일 제거
sudo rm -rf /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend

# 패키지 업데이트 및 업그레이드
sudo apt-get update -y
sudo apt-get upgrade -y

# 필요한 패키지 설치
sudo apt-get install -y xrdp xfce4 xfce4-terminal
sudo apt-get install vsftpd -y
sudo apt-get install python3-pip -y
sudo apt-get install nodejs -y
sudo apt-get install npm -y

# xrdp 설정 수정
LINE_NUM=$(wc -l < /etc/xrdp/startwm.sh)
sudo sed -i "$((LINE_NUM-1))s/^/#/" /etc/xrdp/startwm.sh
sudo sed -i "$LINE_NUM s/^/#/" /etc/xrdp/startwm.sh
echo "startxfce4" | sudo tee -a /etc/xrdp/startwm.sh

# vsftpd 설정 수정
sudo sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf
sudo sed -i 's/root/#root/' /etc/ftpusers

# jetson-stats, ip, spidev 설치
sudo -H pip3 install -U jetson-stats
sudo npm install -g ip
sudo pip3 install spidev pyserial shapely

# NVMe 관련 설정
sudo rm -rf ./rootOnNVMe
if mount | grep -q "/dev/nvme0n1p1"; then
    echo "NVMe SSD (/dev/nvme0n1p1)이 이미 마운트되어 있습니다. 마운트 작업을 생략합니다."
    sleep 5
else
    git clone https://github.com/jetsonhacks/rootOnNVMe
    sudo /home/$USERNAME/rootOnNVMe/copy-rootfs-ssd.sh
    sudo /home/$USERNAME/rootOnNVMe/setup-service.sh
fi

# 설치 스크립트 생성
echo '#!/bin/bash' > /home/$USERNAME/install_nvidia_jetpack.sh
echo 'USERNAME=terry' >> /home/$USERNAME/install_nvidia_jetpack.sh
echo 'echo "$(date): NVIDIA JetPack 설치 시작" >> /home/$USERNAME/install_log.txt' >> /home/$USERNAME/install_nvidia_jetpack.sh
echo 'sudo apt install nvidia-jetpack -y >> /home/$USERNAME/install_log.txt 2>&1' >> /home/$USERNAME/install_nvidia_jetpack.sh
echo 'echo "$(date): NVIDIA JetPack 설치 완료" >> /home/$USERNAME/install_log.txt' >> /home/$USERNAME/install_nvidia_jetpack.sh
echo 'rm -f ~/.config/autostart/nvidia_install.desktop' >> /home/$USERNAME/install_nvidia_jetpack.sh
sudo chmod +x /home/$USERNAME/install_nvidia_jetpack.sh

# .desktop 파일 생성하여 재부팅 후 한 번만 실행
mkdir -p ~/.config/autostart
cat <<EOF > ~/.config/autostart/nvidia_install.desktop
[Desktop Entry]
Type=Application
Exec=gnome-terminal -- bash -c '/home/$USERNAME/install_nvidia_jetpack.sh; exec bash'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=NVIDIA Setup
Comment=Install NVIDIA JetPack after reboot
EOF

chmod +x ~/.config/autostart/nvidia_install.desktop

# ~/.bashrc에 CUDA 경로 추가 (중복 확인 후 추가)
if ! grep -q 'export PATH="/usr/local/cuda-11.4/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="/usr/local/cuda-11.4/bin:$PATH"' >> ~/.bashrc
fi

if ! grep -q 'export LD_LIBRARY_PATH="/usr/local/cuda-11.4/lib64:$LD_LIBRARY_PATH"' ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH="/usr/local/cuda-11.4/lib64:$LD_LIBRARY_PATH"' >> ~/.bashrc
fi

source ~/.bashrc

# 재부팅
sudo reboot
