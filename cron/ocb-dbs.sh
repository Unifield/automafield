#!/bin/sh

. $HOME/venv/bin/activate
ufload -oc OCB restore -adminpw "XXX" -load-sync-server

