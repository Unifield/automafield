#!/bin/sh

if [ ! -f $HOME/.duplicity-config.sh ]; then
	echo "No $HOME/.duplicity-config.sh file, stopping."
	exit 1
fi
. $HOME/.duplicity-config.sh

if [ ! -f $HOME/.duplicity-venv/bin/activate ]; then
	echo "No $HOME/.duplicity-venv, stopping."
	exit 1
fi
. $HOME/.duplicity-venv/bin/activate

backupAll () {
	for i in $*
	do
		backupOne $i
	done
}

# Backup one directory using Duplicity.
backupOne () {
	# First argument is the directory to backup
	dir="$1"
	shift
	# Other arguments are extra args to tar (i.e. exclusions)

	container=swift://`hostname -s`$dir
	echo Running: duplicity --asynchronous-upload --volsize 200 $* $dir $container
	duplicity --asynchronous-upload --volsize 200 $* $dir $container

	# Check objects in this server's container for ones older than
	# the limit, and delete them.
	echo Running: duplicity remove-older-than 10D --force $container
	duplicity remove-older-than 10D --force $container
}


host=`hostname -s`
case $host in
	uf6)
		# /backup/postgres gets dumps put into it
		# via backup-postgres.sh
		do="/etc /backup/postgres /root /opt \
			/var/atlassian/jira-prod \
			/home/production-dbs/update_received_to_send"
		backupAll $do

		# Exclude things from /home that we are not
		# authoratative for.
		backupOne /home \
			--exclude /home/unifield_backups \
			--exclude /home/production-dbs
	;;
	uf5-hw)
		do="/root /etc /opt /usr/local"
		backupAll $do
	;;
	uf5)
		do="/root /etc /opt /usr/local"
		backupAll $do
	;;
	*)
		echo "Unknown host $host."
		exit 1
	;;
esac

