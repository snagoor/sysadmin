#!/bin/bash

### Author : Nagoor Shaik ###
### Email : nagoor.s@gmail.com ###

function script_reset() {

# Function to unset the variables
  unset RHEL7 RHEL6 CentOS7 CentOS6 CHK_NR REBOOT_ANS REPO_COUNT ANS INIT_ORG INIT_LOC INIT_USER INIT_PASS DNS_FIP DNS_IFACE DNS_REVZONE DNS_ZONE DHCP_IFACE DHCP_NS DHCP_GW DHCP_START_RANGE DHCP_END_RANGE FOREMAN SCENARIO

}

function root_check() {

# Ensure that only root user can excute this script
	if [ "$(id -u)" != "0" ]; then
   	   echo "This script must be run as root" 1>&2
   	   exit 1
	fi

}

function check_name_resolution() {

# Function to check the name resolution on the system
	CHK_NR=$(getent hosts "$HOSTNAME")
	if [ "$CHK_NR" -ne 0 ]; then
	   echo -e "\nName Resolution error. Kindly check the Name Resolution or add the hostname entries in /etc/hosts file\n"
	   exit "$CHK_NR"
	fi

}

function disable_ipv6() {

# Function to disable IPV6 on the system
	sysctl -w net.ipv6.conf.all.disable_ipv6=1
	sysctl -w net.ipv6.conf.default.disable_ipv6=1
	echo -e "IPv6 is disabled on this system, Reboot the system to effect these changes\n"
	read -p "Would you like to reboot your system Now? : " REBOOT_ANS
	if [ "$REBOOT_ANS" == "Y" -o "$REBOOT_ANS" == "y" ]; then
	   echo -e "\nReeboting System now\n"
	   reboot 
	else
	   echo -e "Please ensure that you reboot your system to disable IPv6\n"
           echo -e "Configuration won't take effect until you reboot your system\n"
	fi

}

function install_rhel7_packages() {

# Installing the EPEL, PuppetLabs and Foreman related packages to kickstart the installation for RHEL7
	yum install -y http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm http://yum.theforeman.org/releases/1.11/el7/x86_64/foreman-release.rpm https://fedorapeople.org/groups/katello/releases/yum/3.0/katello/el7/x86_64/katello-repos-latest.rpm

}

function install_rhel6_packages() {

# Installing the EPEL, PuppetLabs and Foreman related packages to kickstart the installation for RHEL6
	yum install -y http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm http://yum.theforeman.org/releases/1.11/el6/x86_64/foreman-release.rpm https://fedorapeople.org/groups/katello/releases/yum/3.0/katello/el6/x86_64/katello-repos-latest.rpm

}

function check_internet() {

# Function to check the internet status on the system
	if curl --silent --head http://www.google.com/ | egrep "20[0-9] Found|30[0-9] Found" >/dev/null
	then
	   echo "Internet status: OK"
	   echo "Continuing"
	else
	   echo "Internet status: ERROR, Please check your network connectivity and re-run the script"
	   exit 99
	fi

}

function check_base_repo() {

# Check to see if the system is subscribed to atleast the base repository.
# Here we are ensuring that the package count is greater than 4620, (4620 is the count of the packages in RHEL7 DVD)
	REPO_COUNT=$(yum repolist | grep repolist | awk '{print $2}' | tr -d ,)
	if [ "$REPO_COUNT" -lt 4620 ]; then
	   echo "Base repository doesn't seems to be subscribed OR Package count seems to be less"
	   echo -e "Ensure that the system is subscribed to base repository. Exiting without any changes\n"
	   exit 1
	fi

}

function check_os_version() {

# Function to detect the OS and then execute appropriate functions.
	RHEL7=$(grep Maipo /etc/system-release)
	RHEL6=$(grep Santiago /etc/system-release)
	CentOS7=$(grep Core /etc/system-release)
	CentOS6=$(grep Final /etc/system-release)
	
	if [ -n "$RHEL7" ] || [ -n "$CentOS7" ]; then
	    install_rhel7_packages
	    check_base_repo
	    setup_rhel7_scl_repo
	    RHEL7=1 
        # echo "RHEL 7 Detected"

	elif [ -n "$RHEL6" ] || [ -n "$CentOS6" ]; then
	    install_rhel6_packages
	    check_base_repo
	    setup_rhel6_scl_repo
	    RHEL6=1
        # echo "RHEL 6 Detected"

    	else
            echo -e "\nUnsupported OS Detected\n"
            echo -e "Exiting without any changes\n"
            exit 1		
	fi

}

function install_foreman_packages() {

	yum install -y foreman-ovirt foreman-vmware foreman-libvirt foreman-ec2 foreman-gce foreman-cli foreman-console katello 

}

function set_selinux() {

	sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/sysconfig/selinux
	echo -e "\nSetting SELinux to Permissive. To ensure this change is persistent, reboot this system\n"
	setenforce 0

}

function select_main() {

	echo -e "\nPlease select an option from the below\n"
	echo "**************************************************************************************************"
	echo -e "\t1. Install Foreman with Basic Setup"
	echo -e "\t2. Install Foreman with All In One Setup (Foreman/DHCP/DNS/TFTP)"
	echo -e "\t3. Install Basic setup of Foreman and Katello"
	echo -e "\t4. Install Foreman and Katello with All In One Setup (Katello/Foreman/DHCP/DNS/TFTP)"
	echo -e "\t5. Reset installation"
	echo -e "\t6. Quit\n"
	read -p "Answer : " ANS

}

function setup_rhel6_scl_repo() {
	
cat > /etc/yum.repos.d/scl.repo << EOF
[rhscl-repo]
name=Software Collections Repository
baseurl=http://mirror.centos.org/centos/6/sclo/x86_64/rh/
gpgcheck=0
enabled=1
EOF

}

function setup_rhel7_scl_repo() {
	
cat > /etc/yum.repos.d/scl.repo << EOF
[rhscl-repo]
name=Software Collections Repository
baseurl=http://mirror.centos.org/centos/7/sclo/x86_64/rh/
gpgcheck=0
enabled=1
EOF

}

function setup_firewalld() {

echo -e "\nConfiguring Firewall, Please Wait ... \n"
systemctl start firewalld
systemctl enable firewalld

case $ANS in

	1 ) 
	for i in 80 443 8140 8443;
	    do firewall-cmd --permanent --add-port="$i/tcp" >/dev/null 2>&1; 
	done

	firewall-cmd --reload >/dev/null 2>&1
	;;	

	2)
	for i in 53 80 443 8140 8443;
	    do firewall-cmd --permanent --add-port="$i/tcp" >/dev/null 2>&1; 
	done

	for i in {5910..5930};
            do firewall-cmd --permanent --add-port="$i/tcp" >/dev/null 2>&1; 
	done

	for i in 53 67 68 69;
            do firewall-cmd --permanent --add-port="$i/udp" >/dev/null 2>&1; 
	done

	firewall-cmd --reload >/dev/null 2>&1
	;;

	3)
	for i in 80 443 8140 8443 9090 5647;
            do firewall-cmd --permanent --add-port="$i/tcp" >/dev/null 2>&1; 
	done
    
	firewall-cmd --reload >/dev/null 2>&1
	;;

	4)
	for i in 53 80 443 8140 8443 9090 5647;
	    do firewall-cmd --permanent --add-port="$i/tcp" >/dev/null 2>&1; 
	done

	for i in {5910..5930};
            do firewall-cmd --permanent --add-port="$i/tcp" >/dev/null 2>&1; 
	done

	for i in 53 67 68 69;
            do firewall-cmd --permanent --add-port="$i/udp" >/dev/null 2>&1; 
	done

	firewall-cmd --reload >/dev/null 2>&1
	;;

esac
echo -e "\nFirewall Setup Done\n"

}

function setup_iptables() {

echo -e "\nConfiguring IP Tables, Please Wait ... \n"
service iptables start
chkconfig iptables on
service ip6tables stop
chkconfig ip6tables off

case $ANS in 

    1)
    for i in 80 443 8140 8443;
        do iptables -I INPUT 5 -m state --state NEW -p tcp --dport $i -j ACCEPT;
    done

    iptables-save > /etc/sysconfig/iptables >/dev/null 2>&1
    ;;

    2)
    for i in 53 80 443 8140 8443;
        do iptables -I INPUT 5 -m state --state NEW -p tcp --dport $i -j ACCEPT;
    done

    for i in {5910..5930};
        do iptables -I INPUT 5 -m state --state NEW -p tcp --dport $i -j ACCEPT;
    done

    for i in 53 67 68 69;
        do iptables -I INPUT 5 -m state --state NEW -p udp --dport $i -j ACCEPT;
    done

    iptables-save > /etc/sysconfig/iptables >/dev/null 2>&1
    ;;

    3)
    for i in 22 80 443 8140 8443 9090 5647;
        do iptables -I INPUT 5 -m state --state NEW -p tcp --dport $i -j ACCEPT;
    done

    iptables-save > /etc/sysconfig/iptables >/dev/null 2>&1
    ;;

    4)
    for i in 53 80 443 8140 8443 9090;
        do iptables -I INPUT 5 -m state --state NEW -p tcp --dport $i -j ACCEPT;
    done

    for i in {5910..5930};
        do iptables -I INPUT 5 -m state --state NEW -p tcp --dport $i -j ACCEPT;
    done

    for i in 53 67 68 69;
        do iptables -I INPUT 5 -m state --state NEW -p udp --dport $i -j ACCEPT;
    done

    iptables-save > /etc/sysconfig/iptables >/dev/null 2>&1
    ;;

esac
echo -e "\nIP Tables Setup Done\n"

}

function firewall_call() {

	if [ $RHEL7 -eq 1 ]; then 
	     setup_firewalld
	
	elif [ $RHEL6 -eq 1 ]; then
	     setup_iptables
	fi

}

function read_basic_input() {

	echo -e "\nPlease provide the details below to configure your foreman server \n" 
        read -p "Enter the Organization\t\t\t\t: " INIT_ORG
        read -p "Enter the Location\t\t\t\t\t: " INIT_LOC
        read -p "Enter the User Name\t\t\t\t\t: " INIT_USER
        read -s -p "Enter User Password\t\t\t\t\t: " INIT_PASS

}

function read_allinone_input() {

	echo -e "\nPlease provide the details below to configure your foreman server \n" 
        read -p "Enter Initial Organization\t\t\t\t: " INIT_ORG
        read -p "Enter Initial Location\t\t\t\t\t: " INIT_LOC
        read -p "Enter Initial User Name\t\t\t\t\t: " INIT_USER
        read -s -p "Enter User Password\t\t\t\t\t: " INIT_PASS
        echo " "
        read -p "Enter DHCP Interface\t\t\t\t\t: " DHCP_IFACE
        read -p "Enter DHCP GATEWAY\t\t\t\t\t: " DHCP_GW
        read -p "Enter DHCP Name servers\t\t\t\t\t: " DHCP_NS
        read -p "Enter DHCP Starting Range IP\t\t\t\t: " DHCP_START_RANGE
        read -p "Enter DHCP Ending Range IP\t\t\t\t: " DHCP_END_RANGE
        read -p "Enter DNS Forwarder IP\t\t\t\t\t: " DNS_FIP
        read -p "Enter DNS Interface\t\t\t\t\t: " DNS_IFACE
        read -p "Enter Reverse DNS zone [Ex. 100.168.192.in-addr.arpa]\t: " DNS_REVZONE
        read -p "Enter DNS Zone name [Ex. example.com]\t\t\t: " DNS_ZONE

}

function read_user_input() {

case $ANS in

        1)
	read_basic_input
	input_confirmation
        ;;

        2)
	read_allinone_input
        input_confirmation
        ;;
	
	3)
	read_basic_input
	ANS=1
	input_confirmation
        ;;
	
	4)
	read_allinone_input
	ANS=2
        input_confirmation
        ;;

esac

}

function input_confirmation() {

case $ANS in

        1)
	echo -e "\n\n\n*********************************************"
        echo "Initial Organization : $INIT_ORG"
        echo "Initial Location : $INIT_LOC"
        echo "Initial User Name : $INIT_USER"
	echo -e "\n*********************************************\n\n\n"
        ;;

        2)
	echo -e "\n\n\n*********************************************\n"
        echo "Initial Organization : $INIT_ORG"
        echo "Initial Location : $INIT_LOC"
        echo "Initial User Name : $INIT_USER"
        echo "DHCP Interface : $DHCP_IFACE"
        echo "DHCP Gateway : $DHCP_GW"
        echo "DHCP Name servers : $DHCP_NS"
        echo "DHCP Range : $DHCP_START_RANGE - $DHCP_END_RANGE"
        echo "DNS Forwarder IP : $DNS_FIP"
        echo "DNS Interface : $DNS_IFACE"
        echo "DNS Reverse Zone : $DNS_REVZONE"
        echo "DNS Zone Name : $DNS_ZONE"
	echo -e "\n*********************************************\n\n\n"
        ;;

esac

	echo "Pleave review the above details and hit ENTER to confirm"
	read -p "If you would like to modify the details press (e) to Edit: " CONF

	if [ "$CONF" == "E" -o "$CONF" == "e" ]; then
           read_user_input
	else
	   echo -e "\nDetails Confirmed. Continuing ...\n"
	fi

}

function foreman_installer_basic() {

	echo "$FOREMAN" > /var/tmp/previous_installation
	foreman-installer --scenario "$FOREMAN"\
		--foreman-initial-organization "$INIT_ORG"\
		--foreman-initial-location "$INIT_LOC"\
		--foreman-admin-username "$INIT_USER"\
		--foreman-admin-password "$INIT_PASS"
	
}

function foreman_installer_allinone() {

	echo "$FOREMAN" > /var/tmp/previous_installation
        foreman-installer --scenario "$FOREMAN"\
                --foreman-initial-organization          "$INIT_ORG"\
                --foreman-initial-location              "$INIT_LOC"\
                --foreman-admin-username                "$INIT_USER"\
                --foreman-admin-password                "$INIT_PASS"\
                --foreman-proxy-dns                     "true"\
                --foreman-proxy-dns-forwarders          "$DNS_FIP"\
                --foreman-proxy-dns-interface           "$DNS_IFACE"\
                --foreman-proxy-dns-zone                "$DNS_ZONE"\
                --foreman-proxy-dns-reverse             "$DNS_REVZONE"\
                --foreman-proxy-dhcp                    "true"\
                --foreman-proxy-dhcp-interface          "$DHCP_IFACE"\
                --foreman-proxy-dhcp-range              "$DHCP_START_RANGE $DHCP_END_RANGE"\
		--foreman-proxy-dhcp-nameservers        "$DHCP_NS"\
                --foreman-proxy-tftp                    "true"\
                --foreman-proxy-tftp-servername         "$(hostname)"

}

function foreman_basic() {

	install_foreman_packages
	firewall_call
	read_user_input
	FOREMAN="foreman"
	foreman_installer_basic

}

function foreman_all_in_one() {

	install_foreman_packages
	firewall_call
	read_user_input
	FOREMAN="foreman"
	foreman_installer_allinone

}

function foreman_and_katello_basic() {

	install_foreman_packages
	firewall_call
	read_user_input
	FOREMAN="katello"
	foreman_installer_basic

}

function katello_allinone() {

	install_foreman_packages
	firewall_call
	read_user_input
	FOREMAN="katello"
	foreman_installer_allinone

}

function installation_reset() {
	
	if [ -f "/var/tmp/previous_installation" ]; then
		SCENARIO=$(cat /var/tmp/previous_installation)
		foreman-installer --scenario "$SCENARIO" --reset
	else
		echo -e "Previous installation NOT detected. Exiting\n"
		exit 9
	fi

}

function quit() {

	echo -e "\nQuit option selected\n"
	exit 0

}

function usage() {
    
	echo -e "\nWrong option selected, Please select options [1-6]\n"
	exit 1

}

check_internet
script_reset
root_check
set_selinux
check_os_version
select_main

case $ANS in
        1)
           foreman_basic
           ;;

        2)
           foreman_all_in_one
           ;;
   
        3) 
           foreman_and_katello_basic
           ;;

        4) 
           katello_allinone
           ;;
        
        5)
           installation_reset
           ;;

        6) 
           quit
           ;;

        *)
           usage
           ;;
esac
