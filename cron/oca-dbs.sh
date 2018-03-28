#!/bin/sh

. $HOME/venv/bin/activate
pip install ufload --upgrade
ufload -oc OCA restore -adminpw "XXX" -load-sync-server
