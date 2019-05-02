#!/bin/bash

set -euo pipefail
version=1.0

# Updated by Jesse Harris - USC
#
# Use at your own risk.  USC will accept
# no responsibility for loss or damage
# caused by this script.

inactiveTimer=${4:-1800} # Default 30 mins of idle
enableLog="${5:-no}"
enableShutdown="${6:-no}"
logDir=/var/log
logFile="${logDir}"/InactiveShutdown.log


function logEntry() {
    msg="$(date "+%d-%m-%y %H:%M"): $1"
    if [[ "${enableLog}" == "yes" ]]; then
        echo "$msg" | tee -a "${logFile}"
    else
        echo "$msg"
    fi
}

logEntry "Starting Inactive Shutdown log version ${version}"
logEntry "InactiveTimer: $((inactiveTimer/60)) mins"

# Check if any users are logged in:

idleTime=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000)}')
loggedInUser=$(stat -f '%u %Su' /dev/console | awk '{print $2}')

if [ "${loggedInUser}" != "root" ]; then
    logEntry "User ${loggedInUser} is logged in"
else
    logEntry "User root is logged in."
    if [ "${idleTime}" -gt "${inactiveTimer}" ]; then
        logEntry "Idle time ${idleTime} has exceeded ${inactiveTimer}. Shutting down.."
        if [[ "${enableShutdown}" == "yes" ]]; then
            shutdown -h +1
        else
            logEntry "Demo mode only, not shutting down"
        fi
    else
        logEntry "Idle time ${idleTime} less then ${inactiveTimer}. Exiting.."
    fi
fi

logEntry "Done"
exit 0
