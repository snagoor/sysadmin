#!/bin/bash

sys_init() {
	SYSDATE=""
	SYSHOSTNAME=""
	SYS_LOAD=0
	TOTAL_PROCS=0
	ROOT_FS_SIZE=0
	USERS=0
	MEM_TOTAL=""
	MEM_USED=""
	MEM_FREE=""
	SWAP_TOTAL=""
	SWAP_USED=""
	SWAP_FREE=""
	OS_VERSION=""
	NIC_INFO=0
	SYS_UPTIME=0
}

backup_motd() {
	cp -p /etc/motd /etc/motd.original
}

sys_date() {
	SYSDATE=`date`
}

sys_hostname() {
	SYSHOSTNAME=`hostname -f`
}

sys_load_avg() {
	SYS_LOAD=`awk '{print "1 Min : "$1  "\t5 Min: "$2  "\t15 Min : " $3}' /proc/loadavg`
}

sys_total_procs() {
	TOTAL_PROCS=`ps -A --no-headers | wc -l`
}

sys_root_fs_size() {
	ROOT_FS_SIZE=`df -h | grep "/$" | awk '{print $5,"i.e.", $3"B", "of", $2"B"}'`
}

sys_users_loggedin() {
	USERS=`who | wc -l`
}

sys_mem_usage() {
	MEM_TOTAL=`free -m | grep Mem | awk '{print $2}' | awk '{$1/=1024;printf "%.2f GB\n",$1}'`
	MEM_USED=`free -m | grep Mem | awk '{print $3}' | awk '{$1/=1024;printf "%.2f GB\n",$1}'`
	MEM_FREE=`free -m | grep Mem | awk '{print $4}' | awk '{$1/=1024;printf "%.2f GB\n",$1}'`
}

sys_swap_usage() {
	SWAP_TOTAL=`free -m | grep Swap | awk '{print $2}' | awk '{$1/=1024;printf "%.2f GB\n",$1}'`
	SWAP_USED=`free -m | grep Swap | awk '{print $3}' | awk '{$1/=1024;printf "%.2f GB\n",$1}'`
	SWAP_FREE=`free -m | grep Swap | awk '{print $4}' | awk '{$1/=1024;printf "%.2f GB\n",$1}'`
}

sys_os_version() {
	OS_VERSION=`cat /etc/redhat-release`
}

sys_nic_interfaces() {
	NIC_INFO=`ip -4 -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {print $2" : "$4}'`
}
sys_uptime() {
	SYS_UPTIME=`uptime | awk '{print $3}' | cut -d, -f1`
}

backup_motd
sys_date
sys_hostname
sys_load_avg
sys_total_procs
sys_root_fs_size
sys_users_loggedin
sys_mem_usage
sys_swap_usage
sys_uptime
sys_os_version
sys_nic_interfaces

echo -e "\nSystem Information as on :- $SYSDATE \n" 
echo -e "Fully Quailified Domain Name :- $SYSHOSTNAME \n"
echo -e "System Load Average :- $SYS_LOAD \n"
echo -e "Total Processes :- $TOTAL_PROCS \tTotal RAM :- $MEM_TOTAL \n" 
echo -e "Usage of / FileSystem :- $ROOT_FS_SIZE \n"
echo -e "Users Logged in :- $USERS  Uptime :- $SYS_UPTIME Hours \n" 
echo -e "Memory Usage :- $MEM_USED (Used) $MEM_FREE (Free) \n"  
echo -e "Swap Usage :- $SWAP_USED (Used) $SWAP_FREE (Free) \n"
echo -e "OS Version :- $OS_VERSION \n"
echo -e "Network Interface(s) Information:- " 
printf '%s\n' "${NIC_INFO[@]}"
echo -e ""
