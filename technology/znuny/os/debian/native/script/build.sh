#!/usr/bin/env bash

# ============================================================ #
# Tool Created date: 12 mai 2023                               #
# Tool Created by: Henrique Silva (rick.0x00@gmail.com)        #
# Tool Name: znuny install                                     #
# Description: my script to help for create znuny server       #
# License: MIT License                                         #
# Remote repository 1: https://github.com/rick0x00/srv_itsm    #
# Remote repository 2: https://gitlab.com/rick0x00/srv_itsm    #
# ============================================================ #
# base content:
#   https://doc.znuny.org/znuny_lts/releases/installupdate/install.html

# ============================================================ #
# start root user checking
if [ $(id -u) -ne 0 ]; then
    echo "Please use root user to run the script."
    exit 1
fi
# end root user checking
# ============================================================ #
# start set variables

os_distribution="debian"
os_version=("11" "bullseye")

database_engine="mysql"
webserver_engine="apache"

db_host="localhost"
db_name="zabbix"
db_user="zabbix"
db_pass="zabbix"

db_root_user="root"
db_root_pass="root"

http_port[0]="80" # http number Port
http_port[1]="tcp" # http protocol Port 
https_port[0]="443" # https number Port
https_port[1]="tcp" # https protocol Port 

workdir="/opt/otrs"
persistence_volumes=("/opt/otrs/" "/var/log/")
expose_ports="${http_port[0]}/${http_port[1] https_port[0]}/${https_port[1]}"
# end set variables
# ============================================================ #
# start definition functions
# ============================== #
# start complement functions

# end complement functions
# ============================== #
# start main functions
function pre_install_server () {
}

function install_server () {
}

function configure_server () {
}

function start_server () {
}


# end main functions
# ============================== #
# end definition functions
# ============================================================ #
# start argument reading

# end argument reading
# ============================================================ #
# start main executions of code
install_server;
configure_server;
start_server;

