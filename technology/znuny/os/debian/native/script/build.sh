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
db_name="otrs"
db_user="otrs"
db_pass="otrs"

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
    # Install basic packages
    apt update
    apt install -y apache2
    apt install -y mariadb-client mariadb-server
    apt install -y cpanminus

    # Install Modules for Perl
    perl_packages="libapache2-mod-perl2 libdbd-mysql-perl libtimedate-perl libnet-dns-perl libnet-ldap-perl libio-socket-ssl-perl libpdf-api2-perl libsoap-lite-perl libtext-csv-xs-perl libjson-xs-perl libapache-dbi-perl libxml-libxml-perl libxml-libxslt-perl libyaml-perl libarchive-zip-perl libcrypt-eksblowfish-perl libencode-hanextra-perl libmail-imapclient-perl libtemplate-perl libdatetime-perl libmoo-perl bash-completion libyaml-libyaml-perl libjavascript-minifier-xs-perl libcss-minifier-xs-perl libauthen-sasl-perl libauthen-ntlm-perl libhash-merge-perl libical-parser-perl libspreadsheet-xlsx-perl libcrypt-jwt-perl libcrypt-openssl-x509-perl libcpan-audit-perl"
    apt install -y $perl_packages
    apt install -y jq 
}

function install_server () {
    # Download Znuny Latest
    cd /opt
    wget https://download.znuny.org/releases/znuny-latest-6.5.tar.gz -O /opt/znuny_latest.tar.gz

    # Extract tar.gz
    tar -xzvf /opt/znuny_latest.tar.gz -C /opt/

    # Create a symlink
    ln -s /opt/$(ls /opt/ | grep [0-9]) /opt/otrs
}

function configure_server () {

    # Add user for Debian/Ubuntu
    useradd -d /opt/otrs -c 'Znuny user' -g www-data -s /bin/bash -M -N otrs

    # Copy Default Config
    cp /opt/otrs/Kernel/Config.pm.dist /opt/otrs/Kernel/Config.pm

    # Set permissions
    #/opt/otrs/bin/otrs.SetPermissions.pl

    # Rename default cronjobs
    cp /opt/otrs/var/cron/otrs_daemon.dist /opt/otrs/var/cron/otrs_daemon
    cp /opt/otrs/var/cron/aaa_base.dist /opt/otrs/var/cron/aaa_base

    # Set permissions
    /opt/otrs/bin/otrs.SetPermissions.pl
    chmod 640 /opt/otrs/var/cron/*
    choen otrs:otrs /opt/otrs/var/cron/*

    cpanm install Jq

    /opt/otrs/bin/otrs.CheckModules.pl --all

    # Database Configuration
    echo -e "[mysql]\nmax_allowed_packet=256M\n[mysqldump]\nmax_allowed_packet=256M\n\n[mysqld]\ninnodb_file_per_table\ninnodb_log_file_size = 256M\nmax_allowed_packet=256M" > /etc/mysql/mariadb.conf.d/50-znuny_config.cnf
    systemctl restart mariadb

    mysql -e "SET PASSWORD FOR '$db_root_user'@localhost = PASSWORD('$db_root_pass');"
    mysql -e "ALTER USER '$db_root_user'@'localhost' IDENTIFIED BY '$db_root_pass';"

    mysql -h"$db_host" -u"$db_root_user" -p"$db_root_pass" -e "CREATE USER '$db_user'@'%' IDENTIFIED BY '$db_pass';"
    mysql -h"$db_host" -u"$db_root_user" -p"$db_root_pass" -e "CREATE DATABASE $db_name character set utf8 collate utf8_general_ci;"
    mysql -h"$db_host" -u"$db_root_user" -p"$db_root_pass" -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '$db_user'@'%';"
    mysql -h"$db_host" -u"$db_root_user" -p"$db_root_pass" -e "FLUSH PRIVILEGES;"

    ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/conf-available/zzz_znuny.conf

    #Enable the needed Apache modules:
    a2enmod perl headers deflate filter cgi
    a2dismod mpm_event
    a2enmod mpm_prefork
    a2enconf zzz_znuny

    systemctl restart apache2

}

function start_server () {
    systemctl enable --now mariadb
    systemctl restart mariadb
    systemctl restart apache2
    su -c "/opt/otrs/bin/Cron.sh start" -s /bin/bash otrs
    su -c "/opt/otrs/bin/otrs.Daemon.pl start" -s /bin/bash otrs
    echo "Acesse http://host/otrs/installer.pl"
}


# end main functions
# ============================== #
# end definition functions
# ============================================================ #
# start argument reading

# end argument reading
# ============================================================ #
# start main executions of code
pre_install_server
install_server;
configure_server;
start_server;

###################################################
# Setting email

############## Inbound email (SMTP) ##############

# step 1
# http://hostname/otrs/index.pl?Action=AdminSystemAddress
# Admin - > E-mail Addresses / System Email Addresses Management - > Add System Address (or change Adress)
# E-mail Address: user@domain.com
# Dysplay name: Znuny user
# Queue: Postmaster
# Validity: valid

# step 2 
# http://hostname/otrs/index.pl?Action=AdminSystemConfigurationGroup;RootNavigation=Core::Email
# Admin - > System Configuration - > Core - > Email
# CheckMXRecord::Nameserver: 8.8.8.8
# SendmailModule: Kernel::System::Email::SMTPS
# SendmailModule::AuthPassword: XXXXXXXXX(insecure Email Password)
# SendmailModule::AuthUser: user@domain.com
# SendmailModule::AuthenticationType: Password
# SendmailModule::Host: smtp.domain
# SendmailModule::Port: 465

############## Outbound (IMAP) ##############

# Step 1
# http://hostname/otrs/index.pl?Action=AdminMailAccount;Subaction=AddNew
# Admin - > PostMaster Mail Accounts / Mail Account Management - > Add Mail Account
# Type: IMAPS
# Authentication Type: Password
# Username: user@domain.com
# Password: XXXXXXXXX(insecure Email Password)
# Host: imap.domain.com

###################################################
# inspect logs:

# http://hostname/otrs/index.pl?Action=AdminLog
# Admin - > System log

# http://hostname/otrs/index.pl?Action=AdminCommunicationLog
# Admin - > Communication log
