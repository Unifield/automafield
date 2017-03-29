#!/bin/sh

rdiff-backup /backup/postgres backup::postgres
rdiff-backup /root backup::root
rdiff-backup /etc backup::etc
# Exclude unifield_backups because we are not authoratative for this data,
# it is sent to us nightly from the production sync server.
rdiff-backup --exclude=/home/unifield_backups /home backup::home
rdiff-backup /opt backup::opt
rdiff-backup /var/atlassian/jira-prod backup::jira-prod
rdiff-backup /home/production-dbs/update_received_to_send backup::update_received_to_send
