#!/bin/bash

### Author : Nagoor Shaik ###
### Email : nagoor.s@gmail.com ###

function script_reset() {

# Function to unset the variables
  unset EXIT_STATUS CHK_NR

}

root_check() {

# Ensure that only root user can excute this script
	if [ "$(id -u)" != "0" ]; then
   	   echo "This script must be run as root" 1>&2
   	   exit 1
	fi

}

check_name_resolution() {

# Function to check the name resolution on the system
	CHK_NR=$(getent hosts "$HOSTNAME")
	if [ "$CHK_NR" -ne 0 ]; then
	   echo "Name Resolution error. Kindly check the Name Resolution or add the hostname entries in /etc/hosts file"
	   exit "$CHK_NR"
	fi

}

configure_passenger_repo() {
	
# Function to configure Passenger repository on the system.
	echo -e "\nConfiguring Passenger repository on this system \n"
	curl --silent -k https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo > /etc/yum.repos.d/el-passenger.repo
	EXIT_STATUS=`echo $?`
	if [ "$EXIT_STATUS" -eq 0 ]; then
	   echo -e "\nPassenger repository configured successfully \n"
	else
	   echo -e "\nSomething went wrong in configuring Passenger repository\n"
	   echo -e "\nPlease contact the author {nagoor.s@gmail.com} about this error to get it corrected\n"
	fi

}

check_internet() {

# Function to check the internet status on the system
	if curl --silent --head http://www.google.com/ | egrep "20[0-9] Found|30[0-9] Found" >/dev/null
	then
	   echo -e "\nInternet status: OK"
	   echo -e "\nContinuing"
	else
	   echo -e "\nInternet status: ERROR, Please check your network connectivity and re-run the script\n"
	   exit 99
	fi

}

check_base_repo() {

# Check to see if the system is subscribed to atleast the base repository.
# Here we are ensuring that the package count is greater than 4620, (4620 is the count of the packages in RHEL7 DVD)
	REPO_COUNT=$(yum repolist | grep repolist | awk '{print $2}' | tr -d ,)
	if [ "$REPO_COUNT" -lt 4620 ]; then
	   echo -e "Base repository doesn't seems to be subscribed OR Package count seems to be less\n"
	   echo "Ensure that the system is subscribed to base repository. Exiting without any changes"
	   exit 1
	fi

}

configure_passenger() {

	yum -y install httpd httpd-devel mod_ssl ruby-devel rubygems gcc gcc-c++ pygpgme curl libcurl-devel zlib-devel
	mkdir -p /usr/share/puppet/rack/puppetmasterd/{public,tmp}
	cp /usr/share/puppet/ext/rack/config.ru /usr/share/puppet/rack/puppetmasterd/
	chown puppet:puppet /usr/share/puppet/rack/puppetmasterd/config.ru
	echo "Need to modify /etc/httpd/conf.d/puppetmaster.conf"
	systemctl restart httpd
	systemctl enable httpd firewalld
	systemctl disable puppet
	systemctl start firewalld
	firewall-cmd --permanent --add-port=8140/tcp
	firewall-cmd --reload

 }

install_puppet_master() {

	yum install -y https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
	EXIT_STATUS=`echo $?`
	if [ "$EXIT_STATUS" -eq 0 ]; then
 	   yum install -y puppet-server
	   sed -i "s/^dns_alt_names .*$/dns_alt_names = $HOSTNAME/"  /etc/puppet/puppet.conf
	   sed -i "s/^certname .*$/certname = $HOSTNAME/"  /etc/puppet/puppet.conf
	   configure_passenger_repo
	   configure_passenger
	else
	   echo -e "\nSomething went wrong while installing puppetlabs-release-el-7 RPM"
	   echo -e "Exiting\n"
	fi		

}

root_check
check_name_resolution
check_internet
check_base_repo
install_puppet_master
