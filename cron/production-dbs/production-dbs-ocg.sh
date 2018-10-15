#!/bin/sh

# This is used on the production-dbs@uf6 runbot

. $HOME/venv27/bin/activate

ufload -oc OCG restore -adminuser tempo -adminpw "@tempo21@" -workingdir ./temp_OCG

