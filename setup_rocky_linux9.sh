#!/bin/bash

# カラーディスプレイ定義
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# 進捗表示関数
deploy_status() {
    local message=$1
    local color=$2
    echo -e "${color}${message}${RESET}"
}

# メイン処理
clear

# IPアドレスの入力
deploy_status "Enter IP addresses..." $CYAN
echo "Please enter the IP address for the DMZ server (srv01):"
read dmz_ip
echo "Please enter the IP address for the control server:"
read control_ip

# IPアドレスの検証と反映
if [[ $dmz_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $control_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    deploy_status "Updating inventory file with new IP addresses..." $GREEN
    # inventoryファイルのパス
    inventory_file="inventory.ini"
    
    # inventoryファイルを作成し、IPアドレスを設定
echo "[dmz]" > $inventory_file
    echo "$dmz_ip ansible_user=zansin ansible_password=Passw0rd!" >> $inventory_file
    echo "" >> $inventory_file
    echo "[control]" >> $inventory_file
    echo "$control_ip ansible_user=zansin ansible_password=Passw0rd!" >> $inventory_file
else
    deploy_status "Invalid IP address. Please try again." $RED
    exit 1
fi

# ホスト名の設定
deploy_status "Setting hostname for DMZ server (srv01)..." $YELLOW
sshpass -p "Passw0rd!" ssh -o StrictHostKeyChecking=no "zansin@$dmz_ip" "sudo hostnamectl set-hostname srv01"

# Ansibleプレイブックの実行
deploy_status "Running Ansible playbook to set up DMZ server as a web server..." $GREEN
ansible-playbook -i $inventory_file dmz-setup.yml

deploy_status "DMZ server setup complete!" $GREEN

# 終了メッセージ
deploy_status "Setup script finished successfully." $CYAN
