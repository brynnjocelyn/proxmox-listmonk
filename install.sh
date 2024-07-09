#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y postgresql
msg_ok "Installed Dependencies"

msg_info "Installing Listmonk"
RELEASE=$(curl -s https://api.github.com/repos/knadh/listmonk/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/knadh/listmonk/releases/download/v${RELEASE}/listmonk_${RELEASE}_linux_amd64.tar.gz -O /tmp/listmonk.tar.gz
mkdir -p /opt/listmonk
tar -zxvf /tmp/listmonk.tar.gz -C /opt/listmonk
msg_ok "Installed Listmonk"

msg_info "Configuring Listmonk"
cd /opt/listmonk
./listmonk --new-config
sed -i 's/"user": "user"/"user": "listmonk"/' listmonk.conf
sed -i 's/"password": "password"/"password": "listmonkpassword"/' listmonk.conf
sed -i 's/"database": "listmonk"/"database": "listmonkdb"/' listmonk.conf
msg_ok "Configured Listmonk"

msg_info "Setting up PostgreSQL"
sudo -u postgres psql -c "CREATE USER listmonk WITH PASSWORD 'listmonkpassword';"
sudo -u postgres psql -c "CREATE DATABASE listmonkdb WITH OWNER listmonk;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE listmonkdb TO listmonk;"
msg_ok "Set up PostgreSQL"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/listmonk.service
[Unit]
Description=Listmonk: Newsletter and mailing list manager
ConditionFileIsExecutable=/opt/listmonk/listmonk
After=syslog.target network-online.target

[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/opt/listmonk/listmonk --config /opt/listmonk/listmonk.conf --serve
WorkingDirectory=/opt/listmonk
StandardOutput=file:/var/log/listmonk.out
StandardError=file:/var/log/listmonk.err
Restart=always
RestartSec=10
EnvironmentFile=-/etc/sysconfig/listmonk

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now listmonk.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

