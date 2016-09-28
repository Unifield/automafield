#!/bin/bash

# In order to pick up postgres 8.4, if it is locally installed
export PATH=$HOME/root/bin:$PATH

ct=$1
[ "$ct" = "" ] && ct=1

leave_ss=$2
if [ "$leave_ss" != "" ]; then
	drop="OCG%"
else
	drop=""
fi

. $HOME/automafield/script.sh

set -e
pct_dropall $ct $drop
pct_download $ct OCG
pct_passwordall $ct ourOwnDB
pct_linkall $ct SYNC_SERVER_XXX

set +e
pct_loginall -t 1500 $ct

echo "Done with OCG.sh"
exit 0
