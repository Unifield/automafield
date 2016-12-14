#!/bin/sh

. $HOME/venv/bin/activate
ufload -oc OCA restore -adminpw "XXX" -load-sync-server
