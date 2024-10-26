#!/bin/bash

# カラーディスプレイ定義
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# リポジトリURL（正しいGitHubのリポジトリURLを設定）
REPO_URL="https://github.com/aopensensei/rocky-linux-setup.git"
REPO_DIR="rocky-linux-setup"

# 進捗表示関数
deploy_status() {
    local message=$1
    local color=$2
    echo -e "${color}${message}${RESET}"
}

# メイン処理
clear

# 必要なツールのインストール
deploy_status "Installing required tools (git, sshpass, ansible)..." $YELLOW
sudo dnf install -y epel-release
sudo dnf install -y git sshpass ansible
if [ $? -ne 0 ]; then
    deploy_status "Failed to install required tools. Please check your network connection or package manager." $RED
    exit 1
fi

# リポジトリのクローン
deploy_status "Cloning the repository for playbook and configuration files..." $YELLOW
if [ -d "$REPO_DIR" ]; then
    deploy_status "Repository already exists. Pulling latest changes..." $CYAN
    cd "$REPO_DIR" && git pull origin main
else
    git clone "$REPO_URL"
    cd "$REPO_DIR"
fi

# IPアドレスの入力
deploy_status "Enter IP addresses..." $CYAN
echo "Please enter the IP address for the DMZ server (srv01):"
read dmz_ip
echo "Please enter the IP address for the control server:"
read control_ip

# `odp`ユーザのパスワード入力
deploy_status "Enter the password for the odp user..." $CYAN
read -s odp_password

# IPアドレスの検証と反映
if [[ $dmz_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $control_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    deploy_status "Updating inventory file with new IP addresses..." $GREEN
    # inventoryテンプレートファイルと出力ファイルのパス
    inventory_template="playbook/inventory.ini.template"
    inventory_file="playbook/inventory.ini"

    # テンプレートをもとにinventoryファイルを作成
    sed "s/<dmz_ip>/$dmz_ip/g; s/<dmz_password>/$odp_password/g; s/<control_ip>/$control_ip/g; s/<control_password>/$odp_password/g" "$inventory_template" > "$inventory_file"
else
    deploy_status "Invalid IP address. Please try again." $RED
    exit 1
fi

# ホスト名の設定
deploy_status "Setting hostname for DMZ server (srv01)..." $YELLOW
sshpass -p "$odp_password" ssh -o StrictHostKeyChecking=no "odp@$dmz_ip" "echo '$odp_password' | sudo -S hostnamectl set-hostname srv01"
if [ $? -ne 0 ]; then
    deploy_status "Failed to set hostname for DMZ server." $RED
    exit 1
fi

# Ansibleプレイブックの実行
deploy_status "Running Ansible playbook to set up DMZ server as a web server..." $GREEN
ANSIBLE_PASSWORD="$odp_password"
sshpass -p "$ANSIBLE_PASSWORD" ansible-playbook -i $inventory_file playbook/dmz_srv01/dmz_srv01_setup.yml --user=odp --ask-become-pass --extra-vars "ansible_ssh_pass=$ANSIBLE_PASSWORD"
if [ $? -ne 0 ]; then
    deploy_status "Failed to run Ansible playbook." $RED
    exit 1
fi

deploy_status "DMZ server setup complete!" $GREEN

# 終了メッセージ
deploy_status "Setup script finished successfully." $CYAN
