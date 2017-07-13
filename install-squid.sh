#!/bin/bash
##############################################################
#  Purpose    : squid installation
#  Author     : Nagoor Shaik
#  Date       : 08/31/2005
#  Description: To install and configure squid
##############################################################

function root_check() {
# Ensure that only root user can excute this script
if [ "$(id -u)" != "0" ]; then
   echo -e "\nThis script must be run as root. Exiting for now.\n" 1>&2
   exit 1
fi
}

function package_installation_check() {
# Check if the package installation was OK #
PKG_CHECK=$(echo $?)
if [ "$PKG_CHECK" -ne "0" ]; then
   echo -e "\nCan't install packages! Something went wrong, Exiting! \n"
   exit 1
fi
}

### Main Program ###

# Root User check #
root_check

# Update latest patches before installation of Squid Server #
yum update -y
package_installation_check

# Install Squid #
yum install squid firewalld -y
package_installation_check

# Start and Enable Squid and FirewallD at boot # 
systemctl enable squid firewalld 
systemctl start squid firewalld

# Open SQUID service with firewalld # 
firewall-cmd --add-service=squid --permanent >/dev/null 2>&1
firewall-cmd --reload >/dev/null 2>&1

START_CHECK=$(echo $?)
if [ "$START_CHECK" -eq "0" ]; then
   echo -e "\nOops something went wrong! Unable to start squid service."
   echo -e "Please inspect, 'systemctl status squid' or 'journalctl -u squid.service' to troubleshoot startup issue with squid.\n"
   exit 1
fi
echo -e "\nSQUID installation is successful\n"

