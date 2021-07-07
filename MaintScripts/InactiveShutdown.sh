#!/bin/bash

set -euo pipefail
version=1.1

# Updated by Jesse Harris - USC
#
# Use at your own risk.  USC will accept
# no responsibility for loss or damage
# caused by this script.

maxMinsInactive=${4:-30} # Default 30 mins of idle
enableLog="${5:-no}"
enableShutdown="${6:-no}"
logDir=/var/log
logFile="${logDir}"/InactiveShutdown.log


function logEntry() {
    msg="$(date "+%d-%m-%y %H:%M"): $1"
    if [[ "${enableLog}" == "yes" ]]; then
        echo -e "$msg" | tee -a "${logFile}"
    else
        echo "$msg"
    fi
}

logEntry "\nStarting Inactive Shutdown log version ${version}"
logEntry "maxMinsInactive: ${maxMinsInactive} mins"

# Check if any users are logged in:

idleTime=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000)}')
idleTime=$((idleTime / 60))
loggedInUser=$(stat -f '%u %Su' /dev/console | awk '{print $2}')

if [ "${loggedInUser}" != "root" ]; then
    logEntry "User ${loggedInUser} is logged in"
else
    logEntry "User root is logged in."
    if [ "${idleTime}" -gt "${maxMinsInactive}" ]; then
        logEntry "Idle time ${idleTime} has exceeded ${maxMinsInactive}. Shutting down.."
        if [[ "${enableShutdown}" == "yes" ]]; then
            shutdown -h +1 &
        else
            logEntry "Demo mode only, not shutting down"
        fi
    else
        logEntry "Idle time ${idleTime} less then ${maxMinsInactive}. Exiting.."
    fi
fi

logEntry "Done"
exit 0
