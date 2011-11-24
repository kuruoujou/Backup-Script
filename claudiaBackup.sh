#!/bin/bash

#First check if root...
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root..." 1>&2
	exit 1
fi

#I know it isn't the most secure system, but it works. If you have any suggestions on how to make this better,
#let me know on github.
source ./.backup.conf

#First check to see if remote server is alive...
ping -c 1 -w 5 $server &> /dev/null
if [ $? -ne 0 ]; then
	#If she's not, wake her up...
	wakeonlan $serverMac &> /dev/null
	#Give her time to wake up (5 minutes should be more than enough, if not, increase this)...
	sleep 5m
	#Test to see if she's live again...
	ping -c 1 -w 5 $server &> /dev/null
	if [ $? -ne 0 ]; then
		#If she's still not live, we're probably not on the right network or her IP is incorrect.		
		echo "Could not contact the remote server, are we on the correct network?"
		exit 1
	else
		#if we could wake her, then we need to set the wake variable.
		wake=1
	fi
else
	#set the right variable if she was already awake.
	wake=0
fi

#Now we run rsync appropriately...
rsync -avze ssh --delete --exclude-from "$excludeFile" $backupSource $username@$server:$backupDestination

if [[ $wake -eq 1 ]] ; then
#Finally, if the machine was already on, turn it off.
#Poor indentation here because of EOF.
ssh $username@$server -T <<\EOF
sudo shutdown -P now
logout
EOF
fi
