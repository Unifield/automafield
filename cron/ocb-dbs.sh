#!/bin/sh

. $HOME/venv/bin/activate
pip install ufload --upgrade
ufload -oc OCB restore -adminpw "XXX" -load-sync-server

