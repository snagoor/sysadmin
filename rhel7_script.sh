#!/bin/bash
########## COLOUR CODES ##########[DONE]

NONE='\033[00m'
BOLD='\033[1m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
BLUE='\033[01;34m'
MAGENTA='\033[01;35m'
CYAN='\033[01;36m'

#################### START ###################[DONE]

clear
echo -en ${MAGENTA} ${BOLD}"\t\t\t SERVER REPORT \n"${NONE}
echo -en ${MAGENTA} ${BOLD}"\t================================================== \n"${NONE}
echo -en "\n"

################### DATE ###################[DONE]

m=`date +%B`
d=`date +%d`
y=`date +%Y`
t=`date +%r`

echo -en ${BOLD}"\t Date: ${m} ${d}, ${y} ${t} \t\t\t By: $USER \n\n\n"${NONE}

#################### BASIC SERVER INFORMATION ####################[DONE]

#################### Architecture ####################
Arch=`arch`
archi=$(if [ $Arch = "x86_64" ]; 
then
echo "64 Bit"
else
echo "32 Bit"
fi)

echo -en ${MAGENTA} ${BLUE}"\t=============================== \n"${NONE}
echo -en ${MAGENTA} ${RED}"\t    BASIC SERVER INFORMATION     \n"${NONE}
echo -en ${MAGENTA} ${BLUE}"\t=============================== \n"${NONE}
echo -en ${BLUE}"\t IP                 :${NONE}      `ifconfig | grep inet | head -1 | awk -F ' ' '{print $2}'` \n"
echo -en ${BLUE}"\t Hostname           :${NONE}      `hostname` \n"
echo -en ${BLUE}"\t OS                 :${NONE}      `uname` \n"
echo -en ${BLUE}"\t Kernel             :${NONE}      `uname -r |cut -d"." -f1,2,3`\n"
echo -en ${BLUE}"\t Architecture       :${NONE}      $archi\n"
######### TOTAL CPU % ##########[DONE]

cpuus=`top -n 1|grep Cpu|awk -F ' ' '{print $2}'|awk -F '%' '{print $1}'`
cpusy=`top -n 1|grep Cpu|awk -F ',' '{print $2}'|awk -F ' ' '{print $2}'`
cpuni=`top -n 1|grep Cpu|awk -F ',' '{print $3}'|awk -F ' ' '{print $2}'`
cpuwa=`top -n 1|grep Cpu|awk -F ',' '{print $5}'|awk -F ' ' '{print $2}'`
cpuhi=`top -n 1|grep Cpu|awk -F ',' '{print $6}'|awk -F ' ' '{print $2}'`
cpusi=`top -n 1|grep Cpu|awk -F ',' '{print $7}'|awk -F ' ' '{print $2}'`
cpust=`top -n 1|grep Cpu|awk -F ',' '{print $8}'|awk -F ' ' '{print $2}'`
cput=$(echo "scale=3; ${cpuus}+${cpusy}+${cpuni}+${cpuwa}+${cpuhi}+${cpusi}+${cpust}" |bc )

echo "$cput"> /tmp/cputot
tcpu=`cat /tmp/cputot |cut -d '.' -f 1`

########## TOTAL PHYSICAL MEMORY##########[DONE]

ram=`free -m | grep Mem |awk -F ' ' '{print $3}'`
ramtotal=`free -m | grep Mem |awk -F ' ' '{print $2}'`
ram_a=$(echo "scale=3; $ram / $ramtotal"|bc )
ram_b=$(echo "scale=3; $ram_a * 100"|bc )
echo "$ram_b">total.txt
ram_c=`cat total.txt|awk -F '.' ' {print $1}'`

########## TOTAL SWAP MEMORY ##########[DONE]

swap=`free -m | grep Swap |awk -F ' ' '{print $3}'`
swaptotal=`free -m | grep Swap |awk -F ' ' '{print $2}'`
swap_a=$(echo "scale=3; $swap / $swaptotal"|bc )
swap_b=$(echo "scale=3; $swap_a * 100"|bc )
echo "$swap_b">totalswap.txt
swap_c=`cat totalswap.txt|awk -F '.' ' {print $1}'`

######################################[DONE]

echo -en ${BLUE}"\t Up Time            :${NONE}     `uptime | cut -d ":" -f1` hours `uptime|cut -d ":" -f2` minutes \n"
echo -en ${BLUE}"\t Current Users      :${NONE}      `who |awk -F ' ' '{print $1}'|uniq|wc -l` \n"
echo -en ${BLUE}"\t Current processes  :${NONE}      `top -n 1 |grep Tasks|awk -F ' ' '{print $2}'` \n"
echo -en ${BLUE}"\t CPU Usage          :${NONE}     `if [ $tcpu -le "39" ]; then
						    echo -e ${GREEN} ${BOLD}"$cput% ${NONE} ${BLUE}                               ( Threshold 40% , 70% )"${NONE}
						    elif [ $tcpu -ge "40" -a $tcpu -le "69" ]; then
						    echo -e ${YELLOW} ${BOLD}"$cput% ${NONE} ${BLUE}                              ( Threshold 40% , 70% )"${NONE}
						    else
						    echo -e ${RED} ${BOLD}"$cput% ${NONE} ${BLUE}                                 ( Threshold 40% , 70% )"${NONE}
						    fi `\n"
echo -en ${BLUE}"\t Memory Usage       :${NONE}    `if [ $ram_c -le 40 ]; then
                                               echo -e ${GREEN} ${BOLD} "$ram Out of $ramtotal Used [$ram_b % Used]${NONE} ${BLUE} ( Threshold 40% , 70% )"${NONE}
                                               elif [ $ram_c -ge 41 -a $ram_c -le 70 ]; then
                                               echo -e ${YELLOW} ${BOLD} "$ram Out of $ramtotal Used [$ram_b % Used]${NONE} ${BLUE}( Threshold 40% , 70% )"${NONE}
                                               else
                                               echo -e ${RED} ${BOLD} "$ram Out of $ramtotal Used [$ram_b % Used]${NONE} ${BLUE}( Threshold 40% , 70% )"${NONE}
                                               fi`  \n"
echo -en ${BLUE}"\t Swap Usage         :${NONE}    `if [ $swap_c -le 40 ]; then
                                               echo -e ${GREEN} ${BOLD} "$swap Out of $swaptotal Used [$swap_b% Used]${NONE} ${BLUE}         ( Threshold 40% , 70% )"${NONE}
                                               elif [ $ram_c -ge 41 -a $ram_c -le 70 ]; then
                                               echo -e ${YELLOW} ${BOLD} "$swap Out of $swaptotal Used [$swap_b% Used]${NONE} ${BLUE}        ( Threshold 40% , 70% )"${NONE}
                                               else
                                               echo -e ${RED} ${BOLD} "$swap Out of $swaptotal Used [$swap_b% Used]${NONE} ${BLUE}       ( Threshold 40% , 70% )"${NONE}
                                               fi`  \n"
echo -en ${BLUE}"\t System Load        :${NONE}     `top -n 1 |grep "load average" |cut -d ',' -f 3-5|cut -d ':' -f 2|cut -d ',' -f1` ${BLUE}(1 minute),${NONE} `top -n 1 |grep "load average" |cut -d ',' -f 3-5|cut -d ':' -f 2|cut -d ',' -f2`${BLUE} (5 minutes),${NONE}`top -n 1 |grep "load average" |cut -d ',' -f 3-5|cut -d ':' -f 2|cut -d ',' -f1`${BLUE} (15 minutes)${NONE} \n\n\n"


##################### PROCESSES LOAD (PROCESSES TAKING HIGHER RESOURCES) ####################

echo -en ${BLUE} ${BOLD}"\t========================================================= \n"${NONE}
echo -en ${RED} ${BOLD}"\t    PROCESS LOAD (PROCESSES TAKING HIGHER RESOURCES)     \n"${NONE}
echo -en ${BLUE} ${BOLD}"\t========================================================= \n"${NONE}

echo -en ${CYAN} ${BOLD}"\t=======================================================================================================\n"${NONE}
echo -en ${CYAN} ${BOLD}"\t||    USER   ||   PID    ||   %CPU   ||  %MEM  ||                        COMMAND                     ||\n"${NONE}
echo -en ${CYAN} ${BOLD}"\t=======================================================================================================\n"${NONE}

ps -eo user,pid,%cpu,%mem,command|sort -k4 -rn|head -10|awk '{printf "\t|| %-10s|| %-9s|| %-9s|| %-7s|| %-50s || \n",$1,$2,$3,$4,$5}'
echo -en ${CYAN} ${BOLD}"\t=======================================================================================================\n"${NONE}
echo -en "\n\n\n"

#################### LIST OF USERS CURRENTLY LOGGED IN (SORTED BY NUMBER OF SESSIONS) ####################

echo -en "\t${BLUE}========================================================================${NONE}\n"
echo -en "\t${RED}     List of Users Currently Logged in(sorted by number of sessions)    ${NONE}\n"
echo -en "\t${BLUE}========================================================================${NONE}\n"


who|cut -d " " -f1 | sort | uniq -c | while read line
do
   count=`echo $line | awk -F ' ' '{print $1}'`
   user=`echo $line | awk -F ' ' ' {print $2}'`
   if [ $count -gt 1 ]; then
       echo "$user : $count sessions"
   else
       echo "$user : $count session"
   fi
done > /var/tmp/user
cat /var/tmp/user |sort|awk '{printf "\t\t\t %-15s %-1s %-1s %-1s\n",$1,$2,$3,$4}'

echo -en "\t${BLUE}========================================================================${NONE}\n"
echo -en "\n\n\n"
##################### STORAGE INFORMATION ##################

echo -en "\t${BLUE}=========================${NONE}\n"
echo -en "\t${RED}   Storage Information    ${NONE}\n"
echo -en "\t${BLUE}=========================${NONE}\n\n\n"


##################### PARTISION/FILE SYSTEM INFORMATION (THRESHOLD 80% & 85%) ##################

echo -en "\t${BLUE}==============================================================${NONE}\n"
echo -en "\t${RED}   Partition/File System Information  (Threshold 80% & 85%)    ${NONE}\n"
echo -en "\t${BLUE}==============================================================${NONE}\n"


part=$(fs=`df -h`
onlyName="false"
name=""

echo "$fs" | sed 1d |  while read line
do

    cl=`echo "$line"|cut -d" " -f2`
    if [ "$cl" == "$line" ] ; then
            onlyName="true"
            name="$line"
            continue
    fi
    if [ "$onlyName" == "true" ]; then
        echo "$name" "$line"
        onlyName="false"
        name=""
        continue
    fi
 
            
   echo "$line"
done | awk '{printf "\t|| %-21s || %10s || %10s || %10s || %10s || %-20s ||\n", $1, $2, $3,$4,$5,$6}')

echo -en ${CYAN}"\t===========================================================================================================\n"${NONE}
echo -en ${CYAN}"\t||         NAME          ||    SIZE    ||    USED    ||  AVAILABLE ||    USE%    ||      MOUNTED ON      ||\n"${NONE}
echo -en ${CYAN}"\t===========================================================================================================\n"${NONE}
echo -en "$part\n"
echo -en ${CYAN}"\t===========================================================================================================\n"${NONE}
echo -en "\n\n\n"

#################### LVM INFORMATION ####################

echo -en "\t${BLUE}=====================${NONE}\n"
echo -en "\t${RED}   LVM Information  ${NONE} \n"
echo -en "\t${BLUE}=====================${NONE} \n\n"

########## LV INFORMATION ##########
echo -en "\t${BLUE}==============================${NONE}\n"
echo -en "\t${RED}        LV Information        ${NONE}\n"
echo -en "\t${BLUE}==============================${NONE}\n"

lv=$(lvdisplay &>lv.txt
while read line
do
        if echo $line|grep "^LV Name "  >/dev/null
        then
                lvn=`echo $line |grep "^LV Name"|awk '{printf "\t %-20s\n",$3}'`
                echo -en "\t|| $lvn || "
        fi
        if echo $line|grep "^VG Name" >/dev/null
        then
               lvg=`echo $line |grep "^VG Name" |awk '{printf " %-15s ", $3}'`
                echo -n "$lvg    "
                mount=`cat /etc/mtab|grep $lvg|cut -d" " -f2|awk '{printf " || %-25s",$1}'`
                echo -n "$mount"
        fi

        if echo $line|grep "^LV Size" >/dev/null
         then
                lvs=`echo $line|grep "LV Size "|awk -F ' ' '{print $3}'`
                lvs1=`echo "|| $lvs G ||"|awk '{printf "%-1s %-5s %-10s %-1s",$1,$2,$3,$4}'`
                echo  "$lvs1   "
        fi
done<lv.txt)


echo -en "\t${CYAN}=========================================================================================================${NONE}\n"
echo -en "\t${CYAN}||            LV              ||          VG           ||        MOUNT POINT       ||       Size       ||${NONE}\n"
echo -en "\t${CYAN}=========================================================================================================${NONE}\n"
echo -en "$lv\n"                                                                                                    
echo -en "\t${CYAN}=========================================================================================================${NONE}\n"
                                                                                                                                                    


echo -en "\n\n\n"

########## PV INFORMATION ##########[DONE]

echo -en "\t${BLUE}=============================${CYAN}\n"
echo -en "\t${RED}       PV Information        ${NONE}\n"
echo -en "\t${BLUE}=============================${NONE}\n"


pv=$(pvdisplay &> pv.txt

while read line
do
        if echo $line|grep "^PV Name "  >/dev/null
        then
                pvn=`echo $line |grep "^PV Name"|awk '{printf "%-5s",$3}'`
                echo -en  "\t${CYAN}||${NONE} $pvn      ${CYAN}||${NONE}"
       fi
        if echo $line|grep "^VG Name "  >/dev/null
        then
                vgn=`echo $line |grep "^VG Name"|awk '{printf "\t %-15s\t", $3}'`
                echo -n "$vgn${CYAN}||${NONE}    "
        fi
        if echo $line|grep "^PV Size "  >/dev/null
        then
                pvs=`echo $line |grep "^PV Size"|awk '{printf "%10s",$3,$4}'`
                echo  "$pvs G  ${CYAN}||${NONE}"
        fi

done<pv.txt)
echo -en ${CYAN}"\t======================================================================\n"${NONE}
echo -en ${CYAN}"\t||      PV        ||             VG             ||        Size      ||\n"${NONE}
echo -en ${CYAN}"\t======================================================================\n"${NONE}
echo -en "  $pv \n"
echo -en ${CYAN}"\t======================================================================\n"${NONE}
echo -en "\n\n\n"



#################### I/O STATISTICS ###################

echo -en "\t${BLUE}====================${NONE}\n"
echo -en "\t${RED}   I/O Statistics   ${NONE} \n"
echo -en "\t${BLUE}====================${NONE}\n\n\n"
echo -en "\t CPU Average I/O wait:`iostat 2 2|sed -n  '/^avg/,~1p'|tail -1|awk '{print $4}'`% \n"
iostat | sed -n '5,100p'| awk '{printf "\t %-10s %-10s %-10s\n",$1,$3,$4}'
echo -en "\n\n\n"

################### NETWORK INFORMATION ####################

echo -en "\t${BLUE} =========================${NONE}\n"
echo -en "\t${RED}    Network Information    ${NONE}\n"
echo -en "\t${BLUE} =========================${NONE}\n\n"
################### INTERFACE INFORMATION ####################

rm -rf /tmp/interfaceinfo
eth0=$(raw_interface_data=`ls /etc/sysconfig/network-scripts/|grep "ifcfg"|grep -v "lo"|awk -F '-' '{print $2}' > /tmp/list`
while read line
do
interfaceip=`cat /etc/sysconfig/network-scripts/ifcfg-$line|grep "IPADDR"|awk -F '=' '{print $2}'`
class=`echo $interfaceip |awk -F '.' '{print$1}'`
gateway=`cat /etc/sysconfig/network-scripts/ifcfg-$line|grep "GATEWAY"|awk -F '=' '{print $2}'`
DNS=`cat /etc/sysconfig/network-scripts/ifcfg-$line|grep "DNS"|grep -v "IPV6"|awk -F '=' '{print $2}'`
MAC=`cat /etc/sysconfig/network-scripts/ifcfg-$line|grep "HWADDR"|awk -F '=' '{print $2}'`
DOMAIN=`cat /etc/sysconfig/network-scripts/ifcfg-$line|grep "DOMAIN"|awk -F '=' '{print $2}'`
UUID=`cat /etc/sysconfig/network-scripts/ifcfg-$line|grep "UUID"|awk -F '=' '{print $2}'`
classid=$(if [ $class -ge 1 -a $class -le 126 ]; then
        echo "Class A"
        elif [ $class -ge 128 -a $class -le 191 ]; then
        echo "Class B"
        elif [ $class -ge 192 -a $class -le 223 ]; then
        echo "Class C"
        elif [ $class -ge 224 -a $class -le 239 ]; then
        echo "Class D"
        elif [ $class -ge 240 -a $class -le 255 ]; then
        echo "Class E"
        else
        echo "-"
        fi)
dhcpstatus=`cat /etc/sysconfig/network-scripts/ifcfg-$line|grep BOOTPROTO|awk -F '=' '{print $2}'`
dhcp=$(if [ $dhcpstatus = "dhcp" ]; then
         echo "YES"
         else
         echo "NO"
         fi)
output=`echo "$interfaceip ($classid)"`
{
echo -en " $GREEN $line $NONE   :$BLUE IP         :$NONE $output \n"                                  
echo -en "		:$BLUE DHCP_Enabled :$NONE $dhcp \n"
echo -en "              :$BLUE MAC          :$NONE $MAC \n"                                   
echo -en "              :$BLUE DOMAIN       :$NONE $DOMAIN \n"                                
echo -en "              :$BLUE DNS          :$NONE $DNS \n"                             
echo -en "              :$BLUE UUID         :$NONE $UUID \n"                            
echo -en "              :$BLUE GATEWAY      :$NONE $gateway \n\n\n"
} >/tmp/interfaceinfo
eth1=`cat "/tmp/interfaceinfo"|awk '{if ( NR == 1 ) { printf "\t%1s %-22s %0s %1s %-20s %-1s %-1s %-1s %-1s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9} else { printf "\t\t\t\t %-1s %-20s %1s %1s %15s\n", $1,$2,$3,$4,$5}}'`
echo "$eth1"
done</tmp/list )


##############################################################
lo1=`ifconfig lo|grep inet|grep -v inet6|awk -F ' ' '{print $2}'`
hostname=`hostname | awk -F '.' '{print $1}'`
domain1=`hostname | hostname | cut -d "." -f2,3,4`
nic=`ifconfig|head -1|awk -F ':' '{print$1}'`
#ipf=`cat /etc/sysctl.conf |grep net.ipv4.ip_forward |awk -F '=' '{print $2}'`
#ipfor=$(if [ $ipf = "1" ]; then
#       echo "YES"
#       else
#       echo "NO"
#       fi)
fire_run_lvl=`systemctl list-unit-files|grep firewalld.service|awk -F ' ' '{print $2}'`
firewall=$(if [ $fire_run_lvl = "enabled" ]; then
        echo "ON"
        else
        echo "OFF"
        fi)
#nmapip=`ifconfig | grep inet | head -1 | awk -F ' ' '{print $2}'| awk -F ':' '{print $2}'`
#ports=$(nmap $nmapip |sed -n '7,1007p' |grep -v "Nmap done"|sed '/^$/d' &> nmap.txt
#       while read line
#      do
#     if echo $line >/dev/null
#        then
#                a=`echo $line|awk -F' ' '{print $1}'|awk -F '/' '{print $1}'`
#                b=`echo $line|awk -F' ' '{print $3}'`
#                echo -n  "$a ($b),"
#        fi
#        done< nmap.txt)





echo -en "$eth0\n"
echo -en "\t\t\t\t :${BLUE}lo1                   : ${NONE}$lo1 \n"
echo -en "\t\t\t\t :${BLUE}HOSTNAME              : ${NONE}$hostname \n"
echo -en "\t\t\t\t :${BLUE}DOMAIN		: ${NONE}$domain1 \n"

echo -en "\t\t\t\t :${BLUE}IP FORWARDING ENABLED : ${NONE}$ipfor \n"
echo -en "\t\t\t\t :${BLUE}FIREWALL ON           : ${NONE}$firewall\n"
echo -en "\t\t\t\t :${BLUE}LIST OF OPEN PORTS    : ${NONE}$ports\n"

#################### NETWORK INFORMATION ###################

echo -en "\t${BLUE}=======================================${NONE}\n"
echo -en "\t${RED}          Network Connections    ${NONE}\n"
echo -en "\t${BLUE}=======================================${NONE}\n"
tcpcount=`netstat -nat | grep 'ESTABLISHED'|awk -F ' ' '{print $5}'|wc -l`
echo -en "\t Current Connections (TCP) : $tcpcount \n"
echo -en "\t Connections from the following IPs:  \n"
a=`netstat |grep ESTABLISHED|awk -F ' ' '{print $5}'`
c=0
for i in $a
do
        c=`expr $c + 1`
        echo -en "\t\t $c.$i\n"
done
echo -en "\t${BLUE}=======================================${NONE}\n"
echo -en "\n\n\n"


echo -en "\t${BLUE}============================================================${NONE}\n"
echo -en "\t${RED}   Alphabetical list of Services turned on at run level 3    ${NONE}\n "
echo -en "\t${BLUE}============================================================${NONE}\n"
chkconfig 2> /dev/null|grep 3:on|awk -F ' ' '{print$1}'|awk '{printf "\t %-1s \n",$1}'
echo -en "\t${BLUE}============================================================${NONE}\n"
echo -en "\n\n\n"

################### USER INFORMATION ###################

passex=$(cat /etc/passwd |awk -F ':' '{print $3":"$1":"$7}'|grep /bin/bash|awk -F ':' '{print $1":"$2}' > passex
while read line
        do
        a=`echo $line |awk -F ':' '{print $1}'`
        if [[ $a >="500" ]] || [[ $a == "0" ]];
        then
                b=`cat passex|grep $a |awk -F ":" '{print $2}' `
                echo   "$b "
        fi
        done< passex >sha


while read line
        do
        c=`grep $line /etc/shadow|awk -F ':' '{print $5}' `
        if [[ $c = "99999" ]];
        then
                d=`echo $line`
                echo -en  "$d, "
        fi
        done< sha)
echo $passex>count

nopassex=`cat count|wc -w`




echo -en ${BLUE}"\t ======================================\n"${NONE}
echo -en ${RED}"\t             User Information     \n"${NONE}
echo -en ${BLUE}"\t ======================================\n"${NONE}
echo -en ${BLUE}"\t Total Number of super users          : ${NONE}`cat /etc/passwd|grep /bin/bash|awk -F ':' '{print $3}'|sort -n|grep -w 0|wc -l` (` cat /etc/passwd|grep /bin/bash|awk -F ':' '{print $3,$1}'|sort -n|grep -w 0|awk -F ' ' '{print $2}'`)\n"
echo -en ${BLUE}"\t Total Number of users without 
	 Password Expiry		      : ${NONE}$nopassex ($passex)\n"
echo -en ${BLUE}"\t List of sudo users                   : ${NONE}`cat /etc/sudoers |grep User_Alias|grep -v \#|awk -F '=' '{print $2}'|wc -w` (`cat /etc/sudoers |grep User_Alias|grep -v \#|cut -d"=" -f2`)\n"
echo -en ${BLUE}"\t List of sudo groups                  : ${NONE}\n"
echo -en ${BLUE}"\t Number of files with 777 permissions : ${NONE}`find / -perm -777 2> /dev/null|wc -l`\n"
echo -en ${BLUE}"\t Number of files with suid bit        : ${NONE}`find / -perm -4000 2> /dev/null|wc -l`\n"
echo -en ${BLUE}"\t Permission of /etc/passwd file       : ${NONE}`stat -c "%A [%a] %n" /etc/passwd `\n"
echo -en ${BLUE}"\t Permission of /etc/shadow file       : ${NONE}`stat -c "%A [%a] %n" /etc/shadow `\n"

