#!/bin/bash

echo ""
echo "[0] Nomachine 설치 스크립트 실행중..."
echo ""

sudo apt-get -y install ifupdown

read -p "IP 주소 변경여부 (y/n): " SET_IP

if [[ "$SET_IP" == "y" ]]; then
  IFACE_FILE="/etc/network/interfaces"
  
  if [[ -f "$IFACE_FILE" ]]; then
    echo "$IFACE_FILE 파일이 이미 존재합니다."
    read -p "설정을 덮어쓰시겠습니까? (y/n): " OVERWRITE
    if [[ "$OVERWRITE" != "y" ]]; then
      echo "IP 설정을 건너뜁니다."
    else
      read -p "IP 주소 마지막 자리 (예: xxx → 전체는 192.168.35.xxx): " LAST_OCTET
      IP1="192.168.35.$LAST_OCTET"
      IP2="192.168.10.$LAST_OCTET"
      NETMASK="255.255.255.0"
      GATEWAY="192.168.35.1"
      DNS="210.220.163.82 219.250.36.130"

      sudo bash -c "cat > $IFACE_FILE" <<EOF

auto eth0
iface eth0 inet static
    address $IP1
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers $DNS

auto eth0:0
iface eth0:0 inet static
    address $IP2
    netmask $NETMASK
EOF

      echo "IP 설정 완료. networking 재시작..."
      sudo systemctl restart networking.service
    fi
  else
    read -p "IP 주소 마지막 자리 (예: xxx → 전체는 192.168.35.xxx): " LAST_OCTET
    IP1="192.168.35.$LAST_OCTET"
    IP2="192.168.10.$LAST_OCTET"
    NETMASK="255.255.255.0"
    GATEWAY="192.168.35.1"
    DNS="210.220.163.82 219.250.36.130"

    sudo bash -c "cat > $IFACE_FILE" <<EOF
auto eth0
iface eth0 inet static
    address $IP1
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers $DNS

auto eth0:0
iface eth0:0 inet static
    address $IP2
    netmask $NETMASK
EOF

    echo "IP 설정 완료. networking 재시작..."
    sudo systemctl restart networking.service
  fi
else
  echo "IP 설정을 건너뜁니다."
fi

# Nomachine 설치
echo ""
cd ~/library
wget https://download.nomachine.com/download/8.13/Arm/nomachine_8.13.1_1_aarch64.tar.gz -O nomachine.tar.gz
tar -xvzf nomachine.tar.gz
cd NX
sudo ./nxserver --install
cd ..
sudo mv ~/library/etc nomachine.tar.gz NX

echo ""
echo "[1] Nomachine 설치 완료"
echo ""

