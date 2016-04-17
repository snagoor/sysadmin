######################################################
###   AUTHOR : Nagoor Shaik <nagoor.s@gmail.com>   ###
######################################################
 
# PURPOSE: Converts Consistent Network Device Naming and biosdevname to old style network names such as ethX style. 
# This script must be executed on RHEL 7 or CentOS 7.

# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 2 of the License.

### DISCLAIMER: This script should be used for educational or testing purposes, strictly not meant to use in production and NO WARRANTY is implied for suitability to any given task. ###
### The author hold no responsibility for your setup or any damage done while using or modifying the script. ###

#! /bin/bash

sed -i.bak '/GRUB_CMDLINE_LINUX/ s/^\(.*\)\("\)/\1 net.ifnames=0 biosdevname=0\2/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

### Remove the biosdevname pacakge if found ###
yum remove biosdevname -y >/dev/null 2>&1

### Find the number of NIC's attached to the system ###
count=$(nmcli device status | grep ether | wc -l)

### Loading the names of all the NIC's to an Array ###
array=($(echo $(nmcli device status | grep ether | awk {' print $1 '})))

### Modifying the Cosistent Network Device Naming and biosdevname to old style network names ###
x=0
while [ $x -lt $count ] 
do 
      nmcli connection modify ${array[$x]} connection.interface-name eth$x
      nmcli connection modify ${array[$x]} connection.id eth$x
      ip link set ${array[$x]} down
      ip link set ${array[$x]} name eth$x
      ip link set eth$x up
      x=$(( $x + 1 ))
done

### Finally reboot the system to take effect ###
reboot 
