#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
.__  .__          __                         __    
|  | |__| _______/  |_  _____   ____   ____ |  | __
|  | |  |/  ___/\   __\/     \ /  _ \ /    \|  |/ /
|  |_|  |\___ \  |  | |  Y Y  (  <_> )   |  \    < 
|____/__/____  > |__| |__|_|  /\____/|___|  /__|_ \
             \/             \/            \/     \/
                                            
EOF
}
header_info
echo -e "Loading..."
APP="Listmonk"
var_disk="2"
var_cpu="1"
var_ram="512"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
if [[ ! -d /opt/listmonk ]]; then 
  msg_error "No ${APP} Installation Found!"; 
  exit; 
fi

if (( $(df /boot | awk 'NR==2{gsub("%","",$5); print $5}') > 80 )); then
  read -r -p "Warning: Storage is dangerously low, continue anyway? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] || exit
fi

RELEASE=$(curl -s https://api.github.com/repos/knadh/listmonk/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/knadh/listmonk/releases/download/v${RELEASE}/listmonk_${RELEASE}_linux_amd64.tar.gz -O /tmp/listmonk.tar.gz
msg_info "Stopping Listmonk"
systemctl stop listmonk
msg_ok "Stopped Listmonk"

msg_info "Updating Listmonk"
tar -zxvf /tmp/listmonk.tar.gz -C /opt/listmonk --strip-components=1
msg_ok "Updated Listmonk"

msg_info "Starting Listmonk"
systemctl start listmonk
msg_ok "Started Listmonk"

msg_info "Cleaning Up"
rm -rf /tmp/listmonk.tar.gz
msg_ok "Cleaned"
msg_ok "Updated Successfully"
exit
}

default_settings
update_script
