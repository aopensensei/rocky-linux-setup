#!/bin/bash

# カラーディスプレイ定義
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# エラーチェック関数
check_error() {
  if [ $? -ne 0 ]; then
    echo -e "${RED}エラーが発生しました。処理を中止します。${RESET}"
    exit 1
  fi
}

# システムアップデート
echo -e "${GREEN}システムをアップデートしています...${RESET}"
sudo dnf update -y
check_error

# 必要なパッケージのインストール
echo -e "${GREEN}必要なパッケージをインストールしています...${RESET}"
sudo dnf install -y openssh-server
check_error

# SSHの有効化と起動
echo -e "${GREEN}SSHサービスを有効にし、起動します...${RESET}"
sudo systemctl enable sshd
sudo systemctl start sshd
check_error

# 初期セットアップ完了メッセージ
echo -e "${GREEN}初期セットアップが完了しました。${RESET}"
