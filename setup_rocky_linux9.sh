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

# odp管理ユーザのパスワードを入力
deploy_status "Enter the password for the odp user..." $CYAN
read -s odp_password

# 必要なツールのインストール
deploy_status "Installing required tools (sshpass, ansible)..." $YELLOW
echo "$odp_password" | sudo -S dnf install -y epel-release
echo "$odp_password" | sudo -S dnf install -y sshpass ansible
if [ $? -ne 0 ]; then
    deploy_status "Failed to install required tools. Please check your network connection or package manager." $RED
    exit 1
fi

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
    echo "$dmz_ip ansible_user=zansin ansible_password=<password_placeholder>" >> $inventory_file
    echo "" >> $inventory_file
    echo "[control]" >> $inventory_file
    echo "$control_ip ansible_user=zansin ansible_password=<password_placeholder>" >> $inventory_file
else
    deploy_status "Invalid IP address. Please try again." $RED
    exit 1
fi

# パスワードの入力と保存
deploy_status "Enter the password for the zansin user..." $CYAN
read -s user_password

# inventory.iniファイルにパスワードを設定
sed -i "s/<password_placeholder>/$user_password/g" $inventory_file

# ホスト名の設定
deploy_status "Setting hostname for DMZ server (srv01)..." $YELLOW
sshpass -p "$user_password" ssh -o StrictHostKeyChecking=no "zansin@$dmz_ip" "echo '$odp_password' | sudo -S hostnamectl set-hostname srv01"
if [ $? -ne 0 ]; then
    deploy_status "Failed to set hostname for DMZ server." $RED
    exit 1
fi

# Ansibleプレイブックの実行
deploy_status "Running Ansible playbook to set up DMZ server as a web server..." $GREEN
echo "$odp_password" | ansible-playbook -i $inventory_file dmz-setup.yml --ask-become-pass
if [ $? -ne 0 ]; then
    deploy_status "Failed to run Ansible playbook." $RED
    exit 1
fi

deploy_status "DMZ server setup complete!" $GREEN

# 終了メッセージ
deploy_status "Setup script finished successfully." $CYAN
