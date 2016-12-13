#!/bin/sh

# This is used on the production-dbs@uf5 runbot

. $HOME/venv/bin/activate

for oc in OCG OCB OCA
do
	ufload -oc $oc restore -adminuser tempo -adminpw "@tempo21@"
done

