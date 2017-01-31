#!/bin/sh

rdiff-backup /backup/postgres backup::postgres
rdiff-backup /root backup::root
rdiff-backup /etc backup::etc
rdiff-backup --exclude=/home/unifield_backups /home backup::home
rdiff-backup /opt backup::opt

