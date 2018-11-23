#!/bin/bash

set -Eeuxo pipefail
version=1.0

# Updated by Jesse Harris - USC
#
# Use at your own risk.  USC will accept
# no responsibility for loss or damage
# caused by this script.

logDir=/var/log
logFile="${logDir}"/InactiveShutdown.log

function logEntry() {
    msg="$(date "+%d-%m-%y %H:%M"): $1"
    echo $msg | tee -a "${logFile}"
}

logEntry "Starting Inactive Shutdown log version ${version}"

inactiveTimer="$4"	# This is the time in seconds to wait after a user has logged out
if [ -z "${inactiveTimer}" ]; then
    logEntry "inactiveTimer not specified, using default of 30 mins"
    # default timeout is 30 mins
    inactiveTimer=1800
fi

logEntry "InactiveTimer: $4"

# Check if any users are logged in:

idleTime=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
loggedInUser=$(stat -f '%u %Su' /dev/console | awk '{print $2}')

if [ "${loggedInUser}" != "root" ]; then
    logEntry "User ${loggedInUser} is logged in"
else
    logEntry "User root is logged in."
    if [ "${idleTime}" -gt "${inactiveTimer}" ]; then
        logEntry "Idle time ${idleTime} has exceeded ${inactiveTimer}. Shutting down.."
        shutdown -h +1
    else
        logEntry "Idle time ${idleTime} less then ${inactiveTimer}. Exiting.."
    fi
fi

logEntry "Done"
exit 0
