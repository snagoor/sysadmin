### This script is intended for testing IPA with basic installation + bind ###
### Below are the mandatory steps that one should take care before executing this script ###
### 1. Fresh RHEL 7 or CentOS 7 system installed with more than 2GB of RAM (Mandatory) ###
### 2. IP Address is configured on the system (Mandatory) ###
### 3. System should either be registered to base repository or configure local yum repository using DVD/ISO (Mandatory) ###
### 4. Hostname would be automatically configured based on user input as a part of script execution ###
### 5. Provide password when promoted, which should be more than 8 characters (Mandatory). If password is not provided, then default password would be set as "RedHat1!" ###
### 6. Nameserver entry configured in /etc/resolv.conf ###
### If you find any issues with this script, send a pull request or email nagoor.s@gmail.com ###

#!/bin/bash

unset PASSWORD PKG_CHECK INSTALL_CHECK CHECK_NR EL7_OS FQDN_CHECK READ_FQDN READ_INPUT CHG_HOST_YN DNS_YN OLD_NAME NET_PREFIX NET_IP NET_BITS REV_ZONE VALID_NAME

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
   echo -e "$(hostname -I | cut -d ' ' -f1)\t $(hostname -f)\t $(hostname -s)" >> /etc/hosts
fi
}

function add_new_fqdn_hosts() {
sed -i '/'"$(hostname -I | cut -d ' ' -f1)"'/c \' /etc/hosts
echo -e "$(hostname -I | cut -d ' ' -f1)\t $HOSTNAME" >> /etc/hosts
}

function package_installation_check() {
# Check if the package installation was OK #
PKG_CHECK=$(echo $?)
if [ "$PKG_CHECK" -ne "0" ]; then
   echo -e "\nCan't install packages! Something went wrong, Exiting! \n"
   exit 1
fi
}

function hostname_check() {
# check if hostname is not localhost
echo "$HOSTNAME" | grep -E '^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$' >/dev/null 2>&1
VALID_NAME=$(echo $?)
if [ "$HOSTNAME" == "localhost" ] || [ "$HOSTNAME" == "localhost.localdomain" ] || [ "$VALID_NAME" != 0 ]; then
   echo -e "\nHostname is Invalid. Please change hostname"
   change_hostname
else
   hostnamectl set-hostname "$READ_FQDN"
   hostname "$READ_FQDN"
   HOSTNAME=$READ_FQDN
   add_new_fqdn_hosts
fi
}

function change_hostname() {
read -p "Please provide a Fully Qualified Domain Name (FQDN)[Ex: ipa.example.com] : " READ_FQDN
FQDN_CHECK=$(tr -dc '.' <<< $READ_FQDN | wc -c)
if [ $FQDN_CHECK -lt 2 ]; then
    echo -e "\nIncorrect FQDN name specified"
    read -p "Would you like to retry changing hostname? [Y/N] : " CHG_HOST_YN
   if [ "$CHG_HOST_YN" == "Y" ] || [ "$CHG_HOST_YN" == "y" ]; then
      change_hostname
   else
      echo -e "\nCan't continue further without a valid hostname. Exiting! \n"
      exit 99
   fi
else
   OLD_NAME=$HOSTNAME
   HOSTNAME=$READ_FQDN
   hostname_check
fi
}

# function modify_etc_resolv_conf() {
# sed -i '/^nameserver/s/^/#/g' /etc/resolv.conf
# sed  -i '1s/^/'"nameserver $(hostname -I | cut -d ' ' -f1)\n"'/' /etc/resolv.conf
# }

# function uncheck_nameservers() {
# sed -i '/nameserver/s/^#//g' /etc/resolv.conf
# }

function install_check() {
# Check to see if the ipa-server-install command was successful or not #
INSTALL_CHECK=$(echo $?)
if [ "$INSTALL_CHECK" -ne "0" ]; then
   echo -e "\nSomething went wrong during execution of ipa-server-install command"
   echo -e "Check /var/log/ipaserver-install.log for errors, Exiting! \n"
   exit 1
fi
}

function calculate_reverse_zone() {
NET_IP=$(ip -4 -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {print $4}' | tail -1 | cut -d '/' -f1)
NET_PREFIX=$(ip -4 -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {print $4}' | tail -1 | cut -d '/' -f2)
NET_BITS=$(echo "$NET_PREFIX/8" | bc)
if [ "$NET_BITS" -eq 3 ]; then
    REV_ZONE=$(echo "$NET_IP" | cut -d '.' -f1-3 | awk -F. '{print $3"."$2"."$1".in-addr.arpa"}' )
elif [ "$NET_BITS" -eq 2 ]; then
    REV_ZONE=$(echo "$NET_IP" | cut -d '.' -f1-2 | awk -F. '{print $2"."$1".in-addr.arpa"}' )
else
   REV_ZONE=$(echo "$NET_IP" | cut -d '.' -f1 | awk -F. '{print $1".in-addr.arpa"}' )
fi
}

function find_forwarders() {
NS_COUNT=$(grep nameserver /etc/resolv.conf | wc -l)
if [ "$NS_COUNT" -gt 1 ]; then
   # FORWARDERS=$(grep nameserver /etc/resolv.conf | cut -d ' ' -f2 | tr '\n' ',' | head -c -1)
   FORWARDERS=$(grep nameserver /etc/resolv.conf | cut -d ' ' -f2 | head -1)
else
   FORWARDERS=""
fi
}

function sync_local_time() {
systemctl stop ntpd
ntpdate in.pool.ntp.org
}

### Main Program starts from here ###

# Root User check #
root_check

# Valid Operating System check #
os_check

# Update latest patches before installation of IPA Server #
echo -e "\nUpdating all patches on system\n"
yum update -y
package_installation_check

# Install rng-tools RPMs to generate Entropy #
yum install rng-tools ntp -y
package_installation_check

# Generating entropy for ipa-server-install command #
rngd -r /dev/urandom

# Sync localtime with NTP #
sync_local_time

# Prompt User to input password
echo
read -s -p "NOTE: Password must be more than 8 characters. Enter password for the admin user : " PASSWORD
# If provided password is empty or less than 8 characters, then set default password #
if [ -z "$PASSWORD" ] || [ "${#PASSWORD}" -lt "8" ]; then
   echo -e "\nLength of the password is less than 8 characters. Setting the default password 'P@ssw0rd'\n"
   PASSWORD="P@ssw0rd"
fi

# Prompt user to change hostname and entry in /etc/hosts file #
read -p "Current Hostname is $(hostname -f). Would you like to change it ? [Y/N] : " READ_INPUT
if [ "$READ_INPUT" == "Y" ] || [ "$READ_INPUT" == "y" ]; then
   change_hostname
else
   hostname_check
fi

# Configure IPA with basic options #
read -p "Would you like to configure Integrated DNS with IPA ? [y/n] : " DNS_YN
if [ "$DNS_YN" == "Y" ] || [ "$DNS_YN" == "y" ]; then
   # Install IPA related packages #
   yum install ipa-server bind bind-dyndb-ldap ipa-server-dns -y
   package_installation_check
  # modify_etc_resolv_conf
   calculate_reverse_zone
   add_new_fqdn_hosts
   if [ -z "$FORWARDERS" ]; then
      ipa-server-install --hostname="$(hostname -f)" -n "$(hostname -d)" -r "$(hostname -d| tr [a-z] [A-Z])" -p "$PASSWORD" -a "$PASSWORD" --idstart=1999 --idmax=50000 --no-host-dns --allow-zone-overlap --setup-dns --reverse-zone "$REV_ZONE" --no-forwarders --mkhomedir -U
   else   
      ipa-server-install --hostname="$(hostname -f)" -n "$(hostname -d)" -r "$(hostname -d| tr [a-z] [A-Z])" -p "$PASSWORD" -a "$PASSWORD" --idstart=1999 --idmax=50000 --no-host-dns --allow-zone-overlap --setup-dns --reverse-zone "$REV_ZONE" --forwarder "$FORWARDERS" --mkhomedir -U
   fi
   install_check
#   uncheck_nameservers
else 
   # Install IPA related packages #
   yum install ipa-server -y
   package_installation_check
   ipa-server-install --hostname="$(hostname -f)" -n "$(hostname -d)" -r "$(hostname -d| tr [a-z] [A-Z])" -p "$PASSWORD" -a "$PASSWORD" --idstart=1999 --idmax=50000 --mkhomedir -U
   install_check
fi

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

echo -e "\nIPA Server installation completed successfully"
echo -e "All required communication ports are opened through firewalld service (No Further Action Required)"
echo -e "Please browse https://$HOSTNAME to configure your IPA Server\n"
