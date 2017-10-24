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
	CPU_MODEL=""
	PROC_COUNT=""
	SYS_LOAD_1M=""
	SYS_LOAD_5M=""
	SYS_LOAD_15M=""
	RED=`tput setaf 1`
	GREEN=`tput setaf 2`
	YELLOW=`tput setaf 3`
	BLUE=`tput setaf 4`
	MAGENTA=`tput setaf 5`
	CYAN=`tput setaf 6`
	WHITE=`tput setaf 7`
	RESET=`tput sgr0`
}

backup_motd() {
	if [ -f /etc/motd ]; then
		 if [ "$(id -u)" == "0" ]; then
	      cp -p /etc/motd /etc/motd-date-$(date +%Y-%m-%d-%s)
     fi
  fi
}

sys_date() {
	SYSDATE=$(date)
}

sys_hostname() {
	SYSHOSTNAME=$(hostname -f)
}

sys_load_avg() {
	#SYS_LOAD=$(awk '{print "1Min : "$1  " 5Min: "$2  " 15Min : " $3}' /proc/loadavg)
	SYS_LOAD_1M=$(awk '{print $1}' /proc/loadavg)
	SYS_LOAD_5M=$(awk '{print $2}' /proc/loadavg)
	SYS_LOAD_15M=$(awk '{print $3}' /proc/loadavg)
}

sys_total_procs() {
	TOTAL_PROCS=$(ps -A --no-headers | wc -l)
}

sys_root_fs_size() {
	ROOT_FS_SIZE=$(df -h | grep "/$" | awk '{print $5,"i.e.", $3"B", "of", $2"B"}')
}

sys_users_loggedin() {
	USERS=$(who | wc -l)
}

sys_mem_usage() {
	MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}' | awk '{$1/=1024;printf "%.2f GB\n",$1}')
	MEM_USED=$(free -m | grep Mem | awk '{print $3}' | awk '{$1/=1024;printf "%.2f GB\n",$1}')
	MEM_FREE=$(free -m | grep Mem | awk '{print $4}' | awk '{$1/=1024;printf "%.2f GB\n",$1}')
}

sys_swap_usage() {
	SWAP_TOTAL=$(free -m | grep Swap | awk '{print $2}' | awk '{$1/=1024;printf "%.2f GB\n",$1}')
	SWAP_USED=$(free -m | grep Swap | awk '{print $3}' | awk '{$1/=1024;printf "%.2f GB\n",$1}')
	SWAP_FREE=$(free -m | grep Swap | awk '{print $4}' | awk '{$1/=1024;printf "%.2f GB\n",$1}')
}

sys_os_version() {
	if [ -f /etc/redhat-release ]; then
	   OS_VERSION=$(cat /etc/redhat-release)
        elif [ -f /etc/os-release ]; then
	   OS_VERSION=$(grep PRETTY /etc/os-release | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//')
	else
	   OS_VERSION="Unknown OS"
	fi
}

sys_nic_interfaces() {
	NIC_INFO=$(ip -4 -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {print $2" : "$4}')
}
sys_uptime() {
	SYS_UPTIME=$(uptime -p | sed -e 's/^up //' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
}

cpu_model_name() {
	CPU_MODEL=$(grep 'model name' /proc/cpuinfo | cut -d ':' -f2 | head -1 | sed -e 's/^ //')
}

processor_count() {
	PROC_COUNT=$(grep processor /proc/cpuinfo | wc -l)
}

print_to_stdout() {
	echo -e "\n${CYAN}System Information as on \t : \t${GREEN}$SYSDATE${RESET}"
	echo -e "${CYAN}HostName \t\t\t : \t${GREEN}$SYSHOSTNAME${RESET}"
	echo -e "${CYAN}System Load Average \t\t : \t${RED}1Min: ${GREEN}$SYS_LOAD_1M${RESET} ${RED}5Min: ${GREEN}$SYS_LOAD_5M${RESET} ${RED}15Min: ${GREEN}$SYS_LOAD_15M${RESET}"
	echo -e "${CYAN}Total Processes \t\t : \t${GREEN}$TOTAL_PROCS${RESET}"
	echo -e "${CYAN}Total RAM \t\t\t : \t${GREEN}$MEM_TOTAL${RESET}"
	echo -e "${CYAN}Usage of / FileSystem \t\t : \t${GREEN}$ROOT_FS_SIZE${RESET}"
	echo -e "${CYAN}Users Logged in \t\t : \t${GREEN}$USERS${RESET}"
	echo -e "${CYAN}Uptime \t\t\t\t : \t${GREEN}$SYS_UPTIME${RESET}"
	echo -e "${CYAN}Memory Usage \t\t\t : \t${GREEN}$MEM_USED ${RED}(Used)${RESET} ${GREEN}$MEM_FREE${RESET} ${YELLOW}(Free)${RESET}"
	echo -e "${CYAN}Swap Usage \t\t\t : \t${GREEN}$SWAP_USED ${RED}(Used)${RESET} ${GREEN}$SWAP_FREE${RESET} ${YELLOW}(Free)${RESET}"
	echo -e "${CYAN}OS Version \t\t\t : \t${GREEN}$OS_VERSION${RESET}"
	echo -e "${CYAN}CPU Model Name \t\t\t : \t${GREEN}$CPU_MODEL${RESET}"
	echo -e "${CYAN}CPU Processor Count \t\t : \t${GREEN}$PROC_COUNT${RESET}"
	echo -e "${CYAN}Network Interface(s) Information : ${RESET}"
	printf '%s\n' "${GREEN}${NIC_INFO[@]}${RESET}"
	echo -e ""
}

sys_init
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
cpu_model_name
processor_count
sys_nic_interfaces
print_to_stdout
