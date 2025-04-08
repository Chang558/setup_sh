#!/bin/bash
set -euo pipefail

# 사용자 설정
USERNAME=$(logname)

if [ "$EUID" -ne 0 ]; then
  echo "이 스크립트는 root 권한으로 실행되어야 합니다. sudo로 실행하세요."
  exit 1
fi

# sudoers에 안전한 방식으로 추가 (중복 확인 후 추가)
if ! sudo grep -q "$USERNAME ALL=NOPASSWD: ALL" /etc/sudoers; then
    echo "$USERNAME ALL=NOPASSWD: ALL" | sudo tee -a /etc/sudoers
fi

sudo sed -i 's/^#*AutomaticLoginEnable.*/AutomaticLoginEnable=true/' /etc/gdm3/custom.conf
sudo sed -i 's/^#*AutomaticLogin.*/AutomaticLogin=terry/' /etc/gdm3/custom.conf
sudo sed -i 's/^#*TimedLoginEnable.*/TimedLoginEnable=true/' /etc/gdm3/custom.conf
sudo sed -i 's/^#*TimedLogin.*/TimedLogin=terry/' /etc/gdm3/custom.conf
sudo sed -i 's/^#*TimedLoginDelay.*/TimedLoginDelay=0/' /etc/gdm3/custom.conf

# AccountsService 사용자 설정
sudo mkdir -p /var/lib/AccountsService/users

sudo bash -c "cat <<EOF > /var/lib/AccountsService/users/$USERNAME
[User]
Session=gnome
XSession=gnome
SystemAccount=false
AutomaticLogin=true
EOF"

sudo chown root:root /var/lib/AccountsService/users/$USERNAME
sudo chmod 644 /var/lib/AccountsService/users/$USERNAME

mkdir -p /home/$USERNAME/scripts
chown $USERNAME:$USERNAME /home/$USERNAME/scripts

# GNOME 화면 꺼짐 방지 스크립트 생성
cat <<EOL > /home/$USERNAME/scripts/gnome_power_settings.sh
#!/bin/bash
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
gsettings set org.gnome.desktop.session idle-delay 0
EOL

chmod +x /home/$USERNAME/scripts/gnome_power_settings.sh
chown $USERNAME:$USERNAME /home/$USERNAME/scripts/gnome_power_settings.sh

# 실행도 동일한 경로로
sudo -u $USERNAME bash /home/$USERNAME/scripts/gnome_power_settings.sh

# dpkg 잠금 파일 제거
sudo rm -rf /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend

# 패키지 업데이트 및 업그레이드
sudo apt-get update -y
sudo apt-get upgrade -y

# 필요한 패키지 설치
export DEBIAN_FRONTEND=noninteractive

sudo apt-get install -y xrdp xfce4 xfce4-terminal
sudo apt-get install vsftpd -y
sudo apt-get install python3-pip -y
sudo apt-get install nodejs -y
sudo apt-get install npm -y

# 한글 환경 설정
sudo apt-get install -y language-pack-ko fonts-nanum fonts-nanum-coding ibus ibus-hangul
sudo update-locale LANG=ko_KR.UTF-8
grep -q 'GTK_IM_MODULE=ibus' /etc/environment || echo "GTK_IM_MODULE=ibus" | sudo tee -a /etc/environment
grep -q 'QT_IM_MODULE=ibus' /etc/environment || echo "QT_IM_MODULE=ibus" | sudo tee -a /etc/environment
grep -q 'XMODIFIERS=@im=ibus' /etc/environment || echo "XMODIFIERS=@im=ibus" | sudo tee -a /etc/environment
im-config -n ibus

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
# JetPack 설치 스크립트 생성

cat <<'EOT' > /home/$USERNAME/scripts/install_nvidia_jetpack.sh
#!/bin/bash
echo "$(date): NVIDIA JetPack 설치 시작"
sudo apt-get install -y nvidia-jetpack
echo "$(date): NVIDIA JetPack 설치 완료"
rm -f /home/$USER/.config/autostart/nvidia_install.desktop
EOT

chmod +x /home/$USERNAME/scripts/install_nvidia_jetpack.sh
chown $USERNAME:$USERNAME /home/$USERNAME/scripts/install_nvidia_jetpack.sh

# Autostart .desktop 생성
mkdir -p /home/$USERNAME/.config/autostart
cat <<EOF > /home/$USERNAME/.config/autostart/nvidia_install.desktop
[Desktop Entry]
Type=Application
Exec=gnome-terminal -- bash -c '/home/$USERNAME/scripts/install_nvidia_jetpack.sh; exec bash'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=NVIDIA Setup
Comment=Install NVIDIA JetPack after reboot
EOF

chmod +x /home/$USERNAME/.config/autostart/nvidia_install.desktop
chown $USERNAME:$USERNAME /home/$USERNAME/.config/autostart/nvidia_install.desktop

source ~/.bashrc

# 재부팅
sudo reboot