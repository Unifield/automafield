#!/bin/bash

ct=$1
[ "$ct" = "" ] && ct=1

leave_ss=$2
if [ "$leave_ss" != "" ]; then
	drop="OCG%"
else
	drop=""
fi

# stop on error
set -e

. $HOME/automafield/script.sh

pct_dropall $ct $drop
pct_download $ct OCG
pct_passwordall $ct ourOwnDB
pct_linkall $ct SYNC_SERVER_XXX
pct_loginall -t 1500 $ct

