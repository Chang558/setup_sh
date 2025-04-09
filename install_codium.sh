#!/bin/bash

wget https://github.com/VSCodium/vscodium/releases/download/1.98.2.25078/codium_1.98.2.25078_arm64.deb

sudo apt install -y ./codium_1.98.2.25078_arm64.deb

echo ""
echo "VSCodium 설치 완료. 실행하려면 'codium' 입력하세요."
echo ""
