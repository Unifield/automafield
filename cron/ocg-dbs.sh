#!/bin/sh

. $HOME/venv/bin/activate
ufload -oc UNIFIELD-BACKUP restore -adminpw "XXX" -load-sync-server

