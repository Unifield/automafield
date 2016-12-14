#!/bin/sh

# This is used on the production-dbs@uf5 runbot

. $HOME/venv/bin/activate

for oc in OCG OCB OCA
do
	ufload -oc $oc restore -adminuser tempo -adminpw "XXX"
done

# For the moment, uf5 cannot send to msf.org, so send it to personal
# email instead and then forward it to msf.org from there.
$HOME/automafield/cron/check-db-names | mail -s "Check DBs" jra@nella.org
