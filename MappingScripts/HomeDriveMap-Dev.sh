#!/bin/bash

version=1.4

# Created by David Acland - Amsys
# Updated by Jesse Harris - USC
#
# Use at your own risk.  Amsys will accept
# no responsibility for loss or damage
# caused by this script.

username="$3"
if [ -z "${username}" ]; then # Checks if the variable is empty (user running script from Self Service)
    username="${USER}"
fi

logDir=/Users/"${username}"/Library/USC
logFile="${logDir}"/Homemap.log
touchFile="${logDir}"/HomeDriveMap

if ! test -d "${logDir}"; then
    mkdir "${logDir}"
    chown "${username}" "${logDir}"
fi

function logEntry() {
    if ! test -f "${logFile}"; then
        sChown=1
    fi

    msg="$(date "+%d-%m-%y %H:%M"): $1"
    echo $msg | tee -a "${logFile}"
    if [ "${sChown}" == "1" ]; then
        chown -R "${username}" "${logFile}"
    fi
}

logEntry "Starting homemap log version ${version}"

logEntry "User: ${username}"
protocol="$4"	# This is the protocol to connect with (afp | smb)
logEntry "Protocol: $4"
serverName="$5"	# This is the address of the server, e.g. my.fileserver.com
logEntry "Server: $5"
shareName="$6" # This is the name of the share to mount
logEntry "Sharename: $6"
group="$7" # This is the name of the group the user needs to be a member of to mount the share
logEntry "Group: $7"
netbios="$8"
logEntry "Netbios $8"
# if we cannot ping the server, there is no sense continuing
if ! ping -c 1 "${serverName}" > /dev/null 2>&1; then
    logEntry "No ping response from ${serverName}. Abort."
    exit 1
fi

# Check if this is first run:
if ! test -r "${touchFile}"; then
    logEntry "First run, checking to create new home"
    if ! test -d "/Volumes/${shareName}"; then
        logEntry "${shareName} not mapped yet"
        # root volume not mapped yet
        logEntry "Mapping root volume with applescript..."
        # This is first run, so we are going to mount the root and check if the folder exists.
        mount_script=$(/usr/bin/osascript > /dev/null << EOT
tell application "Finder" 
activate
mount volume "${protocol}://${serverName}/${shareName}"
end tell
EOT
)
    fi
    # First check if it was succesfully mounted:
    # If sharename contains subdirs, then only the last one is used for the mounted volume
    mountName=$(echo ${shareName##*/}) #bash string operators to get the name after the last /
    if test -d "/Volumes/${mountName}"; then
        logEntry "${shareName} mapping was succesfull"
        # Create home directory if it doesn't exist
        if test -d "/Volumes/${mountName}/${username}"; then
            logEntry "Home directory for ${username} already exists on ${serverName}/${shareName}"
        else
            logEntry "No home for ${username} on ${serverName}/${shareName}. Creating..."
            mkdir "/Volumes/${mountName}/${username}"
        fi
        # Touch file to indicate this portion of the script has run once
        logEntry "Creating ${touchFile} to indicate this script has run"
        touch "${touchFile}"
        # Now unmount the root volume
        logEntry "Unmounting ${mountName}"
        umount "/Volumes/${mountName}"
    else
        logEntry "${shareName} did not mount. Abort."
        exit 1
    fi
else
    logEntry "First run has already been executed. Skipping..."
fi

# Test if home is already mounted
if ! test -d "/Volumes/${username}"; then
    logEntry "${username} not mounted yet. Mounting..."
    # Mount the drive
    mount_script=$(/usr/bin/osascript > /dev/null << EOT
tell application "Finder" 
activate
mount volume "${protocol}://${serverName}/${shareName}/${username}"
end tell
EOT
)
else
    logEntry "${username} already mounted"
fi
logEntry "Done"
exit 0
