#!/bin/bash

# check for avail swupd, on a remote (Mac) host
# intended for automation; ex: cron

# input: $1 as the single remote hostname to check

# output: IFF any sw-upd are available, that list, via Notifcation Mgr

# dependencies:
# - macOS
# - ssh keys are set up, for password-less remote login

# notes:
# - minimal safety checking; be careful since this execs code on remote

# quick safety check; must be single param only:
if [ $# -ne 1 ] ; then
    echo 'single param (host) required; bailing' >&2
    exit 1
fi
theHost=$1

# quick safety checks of param passed in:
hasSpace=$(echo X"$1"X | grep -c ' ')
leadingMinus=$(echo X"$1"X | grep -c '^X *-')
anyFlags=$(($hasSpace + $leadingMinus))
if [ $anyFlags -gt 0 ] ; then
    echo 'invalid host; bailing' >&2
    exit 1
fi
# see if host exits (with a less risky cmd than ssh):
/sbin/ping -c1 "$1" >/dev/null 2>&1
if [ $? -ne 0 ] ; then
    echo 'ping of remote host' \""$1"\" 'failed; bailing' >&2
    exit 1
fi

potOut=$(ssh "$1" 'softwareupdate --list 2>&1')
noNew=$(echo "$potOut" | grep -c 'No new software available')
if [ $noNew -eq 0 ] ; then
    osascript -e "display notification \"$theMsg\" with title \"$1: swupd avail\""
fi
