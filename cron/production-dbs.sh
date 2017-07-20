#!/bin/sh

# This is used on the production-dbs@uf6 runbot

. $HOME/venv/bin/activate

for oc in OCG OCB OCA
do
	ufload -oc $oc restore -adminuser tempo -adminpw "@tempo21@"
done

$HOME/automafield/cron/save_updates.sh | \
    mail -s "Save Updates" dan.joguet-laurent@geneva.msf.org
