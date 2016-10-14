#!/bin/bash

# Managed by puppet 
#
# Check a single gateway to see if it responds to ping. Allows us to be more specific about what we check, and allows us to check routes too.
#

TEST_FAILED=0
TMPFILE=/tmp/check_gateway.$$
TEST_GW=$1

if ping -q -n -w1 -c1 ${TEST_GW} > $TMPFILE
  then 
    echo -n "Gateways OK: ${TEST_GW} $(cat $TMPFILE | tail -1 | awk {'print $4'}) ms"
  else 
    echo -n "Gateways CRITICAL: ${TEST_GW} did not respond to ping" ; TEST_FAILED=1
fi

rm -f $TMPFILE


# END OF FILE

