### This script is intended for testing IPA with basic installation + bind ###
### Below are the mandatory steps that one should take care before executing this script ###
### 1. Fresh RHEL 7.2 x86_64 system is installed with 4GB RAM (Mandatory) ###
### 2. IP Address is configured on the system (Mandatory) ###
### 3. System should either be registered to base repository or configure local yum repository using RHEL7.2 DVD/ISO (Mandatory) ###
### 4. Hostname would be automatically configured as a part of script execution ###
### 5. Provide password when promoted, which should be more than 8 characters (Mandatory). If password is not provided, then default password would be set as "RedHat1!" ###
### If you find any issues with this script, send a pull request or email nagoor.s@gmail.com ###

#! /bin/bash

unset PASSWORD pkgchk installchk
echo ""
read -s -p "Enter password for the admin user : " PASSWORD

if [ -z "$PASSWORD" ]; then
   echo -e "\nSetting the default password RedHat1!\n"
   PASSWORD="RedHat1!"
fi

# Setting Hostname and editing /etc/hosts to add IPA server entry #
hostnamectl set-hostname ipa.lab.example.com
hostname ipa.lab.example.com

echo -e "$(hostname -I) \t $(hostname -f) \t $(hostname -s)" >> /etc/hosts

# Install IPA related packages #
yum install ipa-server bind bind-dyndb-ldap ipa-server-dns rng-tools -y

# Generating entropy for ipa-server-install command
rngd -r /dev/urandom

# Check if the package installation was OK #
pkgchk=$(echo $?)
if [ "$pkgchk" -ne 0 ]; then
   echo -e "\nCan't install ipa-server package! Something went wrong, exiting! \n"
   exit 1
fi

# Configure IPA with basic options #
ipa-server-install --hostname="$HOSTNAME" -n "$(hostname -d)" -r "$(hostname -d| tr [a-z] [A-Z])" -p "$PASSWORD" -a "$PASSWORD" --idstart=1999 --idmax=5000 --setup-dns --no-forwarders -U

# Check to see if the above was successful or not #
installchk=$(echo $?)
if [ "$installchk" -ne 0 ]; then
   echo -e "\nSomething went wrong, exiting! \n"
   exit 1
fi

# Add FirewallD rules necessary for IPA Server #
systemctl start firewalld
systemctl enable firewalld

firewall-cmd --permanent --add-port=80/tcp \
--add-port=443/tcp \
--add-port=389/tcp \
--add-port=636/tcp \
--add-port=88/tcp \
--add-port=464/tcp \
--add-port=53/tcp \
--add-port=749/tcp \
--add-port=88/udp \
--add-port=464/udp \
--add-port=53/udp \
--add-port=123/udp

# Reload Firewall Rules #
firewall-cmd --reload

# Get the kerberos principal for admin user #
echo "$PASSWORD" | kinit admin

echo -e "\nIPA Server installation success\n"
