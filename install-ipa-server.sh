### This script is intended for testing IPA with basic installation + bind ###
### Below are the mandatory steps that one should take care before executing this script ###
### 1. Fresh RHEL 7 or CentOS 7 system installed and access to yum repository with 4GB RAM (Mandatory) ###
### 2. IP Address is configured on the system (Mandatory) ###
### 3. System should either be registered to base repository or configure local yum repository using RHEL7.2 DVD/ISO (Mandatory) ###
### 4. Hostname would be automatically configured as a part of script execution ###
### 5. Provide password when promoted, which should be more than 8 characters (Mandatory). If password is not provided, then default password would be set as "RedHat1!" ###
### If you find any issues with this script, send a pull request or email nagoor.s@gmail.com ###

#!/bin/bash

unset PASSWORD PKG_CHECK INSTALL_CHECK CHECK_NR EL7_OS FQDN_CHECK READ_FQDN READ_INPUT CHG_HOST_YN DNS_YN

function root_check() {
# Ensure that only root user can excute this script
if [ "$(id -u)" != "0" ]; then
   echo -e "\nThis script must be run as root. Exiting for now.\n" 1>&2
   exit 1
fi
}

function os_check() {
# Check Operating System version, its only supported on RHEL 7 or CentOS 7 derivatives
uname -r | grep el7 >/dev/null 2>&1
EL7_OS=$(echo $?)
if [ "$EL7_OS" != "0" ]; then
   echo -e "\nIncompatible OS detected. Only RHEL 7 and CentOS 7 derivatives are supported. Exiting !\n"
fi
}

function name_resolution_check() {
# Function to check the name resolution on the system
CHECK_NR=$(getent hosts "$HOSTNAME")
if [ "$CHECK_NR" != "0" ]; then
   echo -e "\nName Resolution error. Adding hostname entry in /etc/hosts file\n"
   echo -e "$(hostname -I)\t $(hostname -f)\t $(hostname -s)" >> /etc/hosts
fi
}

function hostname_check() {
# check if hostname is not localhost
if [ "$HOSTNAME" == "localhost" ] || [ "$(hostname -f)" == "localhost.localdomain" ]; then
   echo -e "\nHostname is Invalid. Please change hostname"
   change_hostname
fi
}

function change_hostname() {
read -p "Please provide a Fully Qualified Domain Name (FQDN)[Ex: ipa.example.com] : " READ_FQDN
FQDN_CHECK=$(tr -dc '.' <<< $READ_FQDN | awk '{print length; }')
if [ "$FQDN_CHECK" -lt "2" ]; then
   read -p "\nIncorrect FQDN name specified\n. Would you like to retry changing hostname? [Y/N] : " CHG_HOST_YN
   if [ "$CHG_HOST_YN" == "Y" ] || [ "$CHG_HOST_YN" == "y" ]; then
      change_hostname
   else
      echo -e "\nCan't continue further without a valid hostname. Exiting! \n"
      exit 99
   fi
else
   hostname_check
fi

hostnamectl set-hostname $READ_FQDN
hostname $READ_FQDN
}

# Update all the latest patches #
yum update -y
# Install IPA related packages #

### Main Program starts from here ###
# Root User check #
root_check

# Valid Operating System check #
os_check

# Prompt User to input password
echo
read -s -p "NOTE: Password must be more than 8 characters. Enter password for the admin user : " PASSWORD
# If provided password is empty or less than 8 characters, then set default password #
if [ -z "$PASSWORD" ] || [ "${#PASSWORD}" -lt "8" ]; then
   echo -e "\nLength of the password is less than 8 characters. Setting the default password RedHat1!\n"
   PASSWORD="RedHat1!"
fi

# Prompt user to change hostname and entry in /etc/hosts file #
read -p "Current Hostname is $HOSTNAME. Would you like to change it ? [Y/N] : " READ_INPUT
if [ "$READ_INPUT" == "Y" ] || [ "$READ_INPUT" == "y" ]; then
   change_hostname
else
   hostname_check
fi

# Update latest patches before installation of IPA Server #
yum update -y

# Install rng-tools RPMs to generate Entropy #
yum install rng-tools -y

# Check if the package installation was OK #
PKG_CHECK=$(echo $?)
if [ "$PKG_CHECK" -ne "0" ]; then
   echo -e "\nCan't install ipa-server package! Something went wrong, exiting! \n"
   exit 1
fi

# Generating entropy for ipa-server-install command
rngd -r /dev/urandom

# Configure IPA with basic options #
read -p "Would you like to configure Integrated DNS with IPA ? [y/n] : " DNS_YN
if [ "$DNS_YN" == "Y" ] || [ "$DNS_YN" == "y" ]; then
   yum install chrony ipa-server bind bind-dyndb-ldap ipa-server-dns -y
   ipa-server-install --hostname="$HOSTNAME" -n "$(hostname -d)" -r "$(hostname -d| tr [a-z] [A-Z])" -p "$PASSWORD" -a "$PASSWORD" -P "$PASSWORD" --idstart=1999 --idmax=5000 --setup-dns --no-forwarders -U
else 
   yum install chrony ipa-server -y
   ipa-server-install --hostname="$HOSTNAME" -n "$(hostname -d)" -r "$(hostname -d| tr [a-z] [A-Z])" -p "$PASSWORD" -a "$PASSWORD" -P "$PASSWORD" --idstart=1999 --idmax=5000 --no-forwarders -U
fi
# Check to see if the above was successful or not #
INSTALL_CHECK=$(echo $?)
if [ "$INSTALL_CHECK" -ne "0" ]; then
   echo -e "\nSomething went wrong during execution of ipa-server-install command"
   echo -e "Check /var/log/ipaserver-install.log for errors, Exiting! \n"
   exit 1
fi

# Start and enable firewalld and chronyd #
systemctl start firewalld chronyd
systemctl enable firewalld chronyd

# Enable required firewalld rules for IPA Server #
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
--add-port=123/udp >/dev/null 2>&1

# Reload Firewall Rules #
firewall-cmd --reload >/dev/null 2>&1

# Get the kerberos principal for admin user #
echo "$PASSWORD" | kinit admin

echo -e "\nIPA Server installation success\n"
