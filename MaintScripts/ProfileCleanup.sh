#!/bin/bash

set -euxo pipefail
version=0.1

# Updated by Jesse Harris - USC
#
# Use at your own risk.  USC will accept
# no responsibility for loss or damage
# caused by this script.

logDir=/var/log
logFile="${logDir}"/ProfileCleanup.log
enableLog="yes"
enableDelete="no"

function logEntry() {
    msg="$(date "+%d-%m-%y %H:%M"): $1"
    if [[ "${enableLog}" == "yes" ]]; then
        echo "$msg" | tee -a "${logFile}"
    fi
}

logEntry "Starting Profile Cleanup log version ${version}"

profileAge="$4"	# This is the age in days of a profile before it is cleaned up.
if [ -z "${profileAge}" ]; then
    logEntry "profileAge not specified, using default of 8 days"
    # default profile age is 8 days
    profileAge=8
fi

logEntry "profileAge: $4"

# Get a list of valid users
# Read user list with dscl
# Use awk to filter out user profiles starting with _
# also, ensure the username does not match
# nobody, administrator or root
validUsers=$(dscl . list /Users | awk '/^[^_]/ {
    if ($0 != "nobody" && $0 != "administrator" && $0 != "root")
        print
}')

# Get and print some nice info to the log about
# How many profiles were found
userCount=$(echo "${validUsers}"| wc -l)
case $userCount in
    1)
        va="is"
        vb="user"
        ;;
    *)
        va="are"
        vb="users"
        ;;
esac

logEntry "There ${va} ${userCount// /} ${vb} found"

#
# A function to check if a month has already
# occured this year or not. If it has, then
# return the current year. If it hasn't then
# the date we are working from is from a previous
# year, so return current year - 1
# this is to work around the fact that the `last`
# command, does not show the year a user was logged
# in, only day and month
function getmonthyear() {
    currentmonth=$(date "+%m")
    testmonth=$(date -j -f "%b" "$1" "+%m")
    if [[ $currentmonth -ge $testmonth ]]; then
        year=$(date "+%Y")
    else
        year=$(date -j -v-1y "+%Y")
    fi
    echo "$year"
}

# Get the current epoch time and the input
# epoch time, subtract 1 from the other
# and convert the resulting seconds to days
function dayssince() {
    # accepts fmt Apr 25 2018
    epochNow=$(date "+%s")
    epochThen=$(date -j -f "%b %d %Y" "${1}" "+%s")
    secondsSince=$((epochNow - epochThen))
    echo $((secondsSince/86400)) 
}

# Tie the previous two functions together
# to show how many days old a user account profile
# is. The bit of awk prints fields 4 and 5 if there
# are 9 or less fields and 5 and 6 if there are 10
function getProfileAge() {
    # $1 = username
    lastlogin=$(last -1 "${1}" | awk '
    /^[^$]/ {
        print (NF == 10 ? $5" "$6 : $4" "$5)
    }')
    dayssince "${lastlogin} $(getmonthyear "${lastlogin% *}")"
}

# Loop over all the profiles, deleting any that
# exceed the max profile age
for user in ${validUsers}; do
    page=$(getProfileAge "${user}")
    logEntry "User ${user} profile age is ${page}"
    if [[ $page -gt $profileAge ]]; then
        logEntry "User profile has exceeded limits deleting"
        if [[ "${enableDelete}" == "yes" ]]; then
            dscl . delete /Users/"${user}"
            cd /Users/
            rm -rf "${user}"
        else
            logEntry "In demo mode, no action performed"
        fi
    fi
done
 
logEntry "Done"
exit 0
