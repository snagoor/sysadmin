### This script is intended for testing IPA wiht basic installation ###
### Below are the mandatory steps that one should take care before executing this script ###
### 1. RHEL 7.2 x86_64 system is installed with 4GB RAM ###
### 2. IP Address is configured on the system ###
### 3. Hostname would be automatically configured as a part of script run ###
### 4. Provide password when promoted, which should be more than 8 characters (mandatory) ###
### If you find any issues with this script, send a pull request or email nagoor.s@gmail.com ###

#! /bin/bash

unset PASSWORD
echo ""
read -s -p "Enter the password for the admin user : " PASSWORD

if [ -z "$PASSWORD" ]; then
   echo -e "\nSetting the default password RedHat1!\n"
   PASSWORD="RedHat1!"
fi

# Setting Hostname and editing /etc/hosts to add IPA server entry #
hostnamectl set-hostname ipa.lab.example.com
hostname ipa.lab.example.com

echo -e "$(hostname -I) \t $(hostname -f) \t $(hostname -s)" >> /etc/hosts

# Install IPA related packages #
yum install ipa-server bind bind-dyndb-ldap ipa-server-dns -y

# Check if the package installation was OK #
pkgchk=$(echo $?)
if [ "$pkgchk" -ne 0 ]; then
   echo -e "\nCan't install ipa-server package! Something went wrong, exiting! \n"
   exit 1
fi

# Configure IPA with Simple Options #
ipa-server-install --hostname="$HOSTNAME" -n "$(hostname -d)" -r "$(hostname -d| tr [a-z] [A-Z])" -p "$PASSWORD" -a "$PASSWORD" --idstart=1999 --idmax=5000 --setup-dns --forwarder 8.8.8.8 -U

# Check to see if the above was successful or not #
chk=$(echo $?)
if [ "$chk" -ne 0 ]; then
   echo -e "\nSomething went wrong, exiting! \n"
   exit 1
fi

# Add FirewallD rules necessary IPA Server #
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
