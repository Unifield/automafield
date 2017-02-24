#!/bin/sh

rdiff-backup /root backup::root
rdiff-backup /etc backup::etc
rdiff-backup /opt backup::opt
rdiff-backup /usr/local backup::local
rdiff-backup /backup/uf6/update_received_to_send backup::update_received_to_send_backup
