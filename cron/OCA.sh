#!/bin/bash

ct=$1
[ "$ct" = "" ] && ct=3

leave_ss=$2
if [ "$leave_ss" != "" ]; then
	drop="BD% HQ% SZ% UZ%"
else
	drop=""
fi

. $HOME/automafield/script.sh

pct_dropall $ct $drop
pct_download $ct OCA
pct_passwordall $ct ourOwnDB
pct_linkall $ct SYNC_SERVER_XXX
pct_loginall -t 1500 $ct

echo "Done with OCA.sh"
exit 0
