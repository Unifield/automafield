#!/bin/sh

# This is used on the production-dbs@uf5 runbot

. $HOME/venv/bin/activate

for oc in OCG OCB OCA
do
	ufload -oc $oc restore -adminuser tempo -adminpw "XXX"
done

$HOME/automafield/cron/check-db-names | \
    mail -s "Check DBs" dan.joguet-laurent@geneva.msf.org
