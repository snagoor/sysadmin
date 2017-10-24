# IPA Install Script [ipa-install.sh]
Script would help to install IPA Server for testing purposes.

# System Info [sysinfo.sh]
This Script is helpful to print useful info about the system.

### SAMPLE OUTPUT ###

~~~

System Information as on 	 : 	Tue Oct 24 22:14:22 IST 2017
HostName 			 : 	foreman.example.com
System Load Average 		 : 	1Min: 0.85 5Min: 0.68 15Min: 0.28
Total Processes 		 : 	155
Total RAM 			 : 	5.67 GB
Usage of / FileSystem 		 : 	23% i.e. 8.4GB of 38GB
Users Logged in 		 : 	1
Uptime 			         : 	2 Minutes
Memory Usage 			 : 	2.74 GB (Used) 2.46 GB (Free)
Swap Usage 			 : 	0.00 GB (Used) 1.50 GB (Free)
OS Version 			 : 	CentOS Linux release 7.4.1708 (Core)
CPU Model Name 		         : 	Intel Core Processor (Haswell, no TSX)
CPU Processor Count		 : 	2
Network Interface(s) Information :
eth0 : 192.168.121.177/24

~~~

# Script which converts RHEL NIC's to older style ethX interfaces [rhel7_old_nic_style.sh]

Script which converts the 'biosdevname' naming system NIC's to older style ethX scripts
