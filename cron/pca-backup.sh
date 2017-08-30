#!/bin/sh

# Check that this host is set up as expected
host=`hostname -s`
pca=/pca/$host
if [ ! -d $pca ]; then
	echo "Could not find $pca directory."
	exit 1
fi

# Remove old files
find $pca -mtime 10 -exec rm {} \;

# Define the functions we'll use next
backupAll () {
	for i in $*
	do
		backupOne $i
	done
}

backupOne () {
	# First argument is the directory to backup
	dir=$1
	shift
	# Other arguments are extra args to tar (i.e. exclusions)

	dt=`date +%Y%m%d`
	out=$pca/`basename $dir`-$dt.tar.gpg
	tar -C / $* -c $dir | \
		gpg --batch --passphrase $BACKUP_PASSPHRASE --compress-algo bzip2 -c > $out
}

# IMPORTANT: List directories to backup RELATIVE to /
# so that the tarfiles do not have directory names starting with /.
case $host in
	uf6)
		# /backup/postgres gets dumps put into it
		# via backup-postgres.sh
		do="etc backup/postgres root opt \
			var/atlassian/jira-prod \
			home/production-dbs/update_received_to_send"
		backupAll $do

		# Exclude things from /home that we are not
		# authoratative for.
		backupOne home \
			--exclude=home/unifield_backups \
			--exclude=home/production-dbs
	;;
	uf5)
		do="root etc opt usr/local"
		backupAll $do
	;;
	*)
		echo "Unknown host $host."
		exit 1
	;;
esac

