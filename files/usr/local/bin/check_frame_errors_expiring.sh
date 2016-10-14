#!/bin/bash 
# Managed by Puppet
source /etc/profile
# Read the contents of rx_crc_errors for each hardware interface
# compare them against previous values
# alert if they have incremented in the last n hours 
# n should probably be of order 24 hours so they get picked up. 
# We need to store name, previous value and timestamp of last change. 
# if we reboot or otherwise reset to zero, we should not alert. 
history_dir='/var/cache/frame_errors';
history_file="${history_dir}/frame_errors.data"
history_new="${history_dir}/frame_errors.new"
# how many hours do we alert for
alert_interval="24"
if [ ! -d $history_dir ]
then
    mkdir -p $history_dir
fi
now=`date +"%s"`
alert_time=`expr $now - $alert_interval '*' 3600`
# array to hold each line from the history file
declare -a old 
# list of active hardware interfaces.
if [  -z "$1" ] ; then
    device_list="$(find /sys/devices/pci* -name net | while read i; do ls $i; done)"
else
    device_list=$1
fi
function write_history()
{
    interface=$1
    timestamp=$2
    counter=$3
    printf "%s,%s,%s\n" $interface $timestamp $counter >> $history_new.$interface    
}
# iterate over each interface. 
for i in $device_list; do
    if [ ! -f $history_file.$i ]
    then
        touch $history_file.$i
    fi

    # see if it is present in the history file. 
    history_line=`grep "${i}," $history_file.$i`
    current="$(cat /sys/class/net/$i/statistics/rx_crc_errors 2>/dev/null)";
   
    alert=0
    
    unset old
    declare -a old 
    
    if [ "$history_line" != "" ] 
    then
        # we have history for this interface - read it into an array
        readarray old < <(echo $history_line | tr ',' '\n')
#    
# for a line like     
# em1, 1429871878, 0 
#
#  ${old[0]} = em1  		- interface name
#  ${old[1]} = 1429871878 	- timestamp of last change
#  ${old[2]} = 0    		- error counter 
# 
# This can be extended to cover other error counters in the future. 
#	
	# has it changed?
	if [ $current -ne ${old[2]} ]
	then 
	    write_history $i $now $current
	    # only alert if non zero - this covers a reset
	    if [ "$current" != "0" ] 
	    then
	       alert=1;
	    fi
	else 
	# it hasn't changed, preserve history
	    write_history ${old[0]} ${old[1]} ${old[2]}
	fi
	
	# are we still in the alert period
	# and is the counter non zero - covers resets to zero on reboot
	if [ \( ${old[1]} -ge $alert_time \) -a \( "$current" != "0" \) ]
	then 
	   alert=1
	fi
     else 
         # no history - write it. We write it with alert time as the timestamp 
	 # so it won't trigger the next time through. 
	 # Note this doesn't cover situations where we want to alert on first run. 
	 write_history $i $alert_time $current
     fi 
     if [ $alert -eq 1 ]
     then
        echo "$i: CRITICAL $current"
     else 
        echo "$i: OK  $current"
     fi
mv -f $history_new.$i $history_file.$i
done
# save history
#end
