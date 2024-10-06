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
# - TBD: see those refs inline

# History:

# 20241006 mvr: add exceptions (fixed & case-sensitive); one per line, in $exceptionsFile
# 20240110 mvr: add timestamp to notifications
# 20220125 mvr: handle a few more errs (& avoid mail)
# 20220121 mvr: if ping fails, notify (vs. stderr - which results in email :/)
# 20220117 mvr: incep


LF=$'\n'
NOW_HR=$(date +%Y-%m-%d\ %H:%M:%S) # human-readable timestamp
exceptionsFile=~/utils/swupd_remote_check_execptions

## functions:
doNotify()
# args (BOTH must be double-quote safe): $1: title of notification ; $2 (optional): body
{
    osascript -e "display notification \"$2\" with title \"$1\""
}


## execution begins here:

# quick safety check; must be single arg only:
if [ $# -ne 1 ] ; then
    echo 'single arg (host) required; bailing' >&2
    exit 1
fi

# quick safety checks of param passed in:
hasSpace=$(echo X"$1"X | grep -c ' ')
leadingMinus=$(echo X"$1"X | grep -c '^X *-')
anyFlags=$(($hasSpace + $leadingMinus))
if [ $anyFlags -gt 0 ] ; then
    echo 'invalid host; bailing' >&2
    exit 1
fi

theHost=$1
# see if host exits (with a less risky cmd than ssh):
/sbin/ping -c1 "$theHost" >/dev/null 2>&1
if [ $? -ne 0 ] ; then
    doNotify "$theHost: ping failed..." '(attempting to check for swupd)'
    exit
fi

potOut=$(ssh "$theHost" 'softwareupdate --list 2>&1' 2>&1)
noNew=$(echo "$potOut" | grep -c 'No new software available')
if [ $noNew -eq 0 ] ; then
    # filter down to Labels only:
    outFiltered=$(echo "$potOut" | fgrep 'Label: ')
    # filter OUT any exceptions:
    if [ -f "$exceptionsFile" ] ; then
        IFS=$'\n' read -d '' -r -a theExceptionsList < "$exceptionsFile"
        exceptionsCount=${#theExceptionsList[@]}
        if [ $exceptionsCount -gt 0 ] ; then
            for i in $(seq 0 $(( $exceptionsCount - 1 )) ) ; do
                outFiltered=$(echo "$outFiltered" | fgrep -v "${theExceptionsList[$i]}")
            done
        fi
    fi
    potOut2=$outFiltered
    doNotify "$theHost: swupd avail" "$NOW_HR${LF}$potOut2"
fi
