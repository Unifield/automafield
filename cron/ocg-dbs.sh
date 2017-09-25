#!/bin/sh

. $HOME/venv/bin/activate
ufload -oc OCG-Backup restore -adminpw "XXX" -load-sync-server

