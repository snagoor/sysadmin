#! /bin/bash

unset PASSWORD
echo ""
read -s -p "Enter the password for the admin user : " PASSWORD

if [ -z "$PASSWORD" ]; then
   echo -e "\nSetting the default password RedHat1!\n"
   PASSWORD="RedHat1!"
fi

# Install IPA related packages #
yum install ipa-server -y

# Check if the package installation was OK #
pkgchk=$(echo $?)
if [ "$pkgchk" -ne 0 ]; then
   echo -e "\nCan't install ipa-server package! Something went wrong, exiting! \n"
   exit 1
fi

# Configure IPA with Simple Options #
ipa-server-install --hostname="$HOSTNAME" -n "$(hostname -d)" -r "$(hostname -d| tr [a-z] [A-Z])" -p "$PASSWORD" -a "$PASSWORD" --idstart=1999 --idmax=5000 --no-forwarders -U

# Check to see if the above was successful or not #
chk=$(echo $?)
if [ "$chk" -ne 0 ]; then
   echo -e "\nSomething went wrong, exiting! \n"
   exit 1
fi

# Add FirewallD rules necessary IPA Server #
firewall-cmd --permanent --add-port=80/tcp \
--add-port=443/tcp \
--add-port=389/tcp \
--add-port=636/tcp \
--add-port=88/tcp \
--add-port=464/tcp \
--add-port=88/udp \
--add-port=464/udp \
--add-port=123/udp

# Reload Firewall Rules #
firewall-cmd --reload

# Get the kerberos principal for admin user #
echo "redhat123" | kinit admin

echo -e "\nIPA Server installation success\n"
