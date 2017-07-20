#!/bin/sh

for i in postgres root etc opt jira-prod
do
        rdiff-backup --remove-older-than 30D --force -v2 backup::$i
done

rdiff-backup /backup/postgres backup::postgres
rdiff-backup /root backup::root
rdiff-backup /etc backup::etc
rdiff-backup /opt backup::opt
rdiff-backup /var/atlassian/jira-prod backup::jira-prod

# For /home, be careful not to backup useless things, so that we don't
# burden uf5 with too much crap in /backup.

# Exclude unifield_backups because we are not authoratative for this data,
# it is sent to us nightly from the production sync server. Most of the stuff
# in /home/production-dbs is generated; only update_received_to_send is
# worth backing up.
rdiff-backup \
	--exclude=/home/unifield_backups \
	--exclude=/home/production-dbs \
	/home backup::home
rdiff-backup /home/production-dbs/update_received_to_send backup::update_received_to_send

