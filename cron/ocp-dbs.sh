#!/bin/sh

. $HOME/venv/bin/activate
pip install ufload --upgrade
ufload -oc OCG-Backup restore -adminpw "XXX" -load-sync-server

