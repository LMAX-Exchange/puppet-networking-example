#!/bin/bash
# Managed by puppet
# Usage ./$0 {interface} {carrier|duplex|speed|crc}

source /etc/profile

INTERFACE=$1
CHECK=$2

if [ -z "$INTERFACE" ] ; then
	echo "Error. Undefined Interface"
fi
if [ -z "$CHECK" ] ; then
	echo "Error. Undefined Check"
fi


echo -n "$INTERFACE: "

case $CHECK in
  carrier)
    cat /sys/class/net/$INTERFACE/carrier
  ;;
  duplex)
    cat /sys/class/net/$INTERFACE/duplex
  ;;
  speed)
    ( cat /sys/class/net/$INTERFACE/speed ; cat /sys/class/net/$INTERFACE/device/uevent | grep ^DRIVER= | sed s/DRIVER=// ) | xargs
  ;;
  crc)
    cat /sys/class/net/$INTERFACE/statistics/rx_crc_errors
  ;;
  *)
    echo "ERROR: Unknown Check"
  ;;
esac
