#!/bin/bash

# スクリプトを実行するディレクトリをスクリプト自身の場所に設定
cd "$(dirname "$0")"

# 順番に表示するファイルのリスト
files=(
    "setup_rocky_linux9.sh"
    "playbook/inventory.ini.template"
    "playbook/dmz_srv01/dmz_srv01_setup.yml"
    "playbook/dmz_srv01/roles/account_setup/tasks/main.yml"
    "playbook/dmz_srv01/roles/account_setup/vars/main.yml"
    "playbook/dmz_srv01/roles/middleware_install/handlers/main.yml"
    "playbook/dmz_srv01/roles/middleware_install/tasks/main.yml"
    "playbook/dmz_srv01/roles/middleware_install/vars/main.yml"
    "playbook/dmz_srv01/roles/wordpress_setup/tasks/main.yml"
    "playbook/dmz_srv01/roles/wordpress_setup/templates/nginx.conf.j2"
    "playbook/dmz_srv01/roles/wordpress_setup/templates/wp-config.php.j2"
    "playbook/dmz_srv01/roles/wordpress_setup/vars/main.yml"
)

# 各ファイルを順に表示
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "----- $file -----"
        cat "$file"
        echo -e "\n"  # 各ファイルの後に改行を追加
    else
        echo "File not found: $file" >&2
    fi
done
