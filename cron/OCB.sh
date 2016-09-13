#!/bin/bash

ct=$1
[ "$ct" = "" ] && ct=2

. $HOME/automafield/script.sh

set -e
pct_dropall $ct
pct_download $ct OCB
pct_passwordall $ct ourOwnDB
pct_linkall $ct SYNC_SERVER_XXX

set +e
pct_loginall -t 1500 $ct

echo "Done with OCB.sh"
exit 0
