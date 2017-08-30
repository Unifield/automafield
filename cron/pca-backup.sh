#!/bin/sh

if [ ! -f $HOME/.pca-gpg.sh ]; then
	echo "No $HOME/.pca-gpg.sh file, stopping."
	exit 1
fi
. $HOME/.pca-gpg.sh

if [ ! -f $HOME/.openrc.sh ]; then
	echo "No $HOME/.openrc.sh file, stopping."
	exit 1
fi
. $HOME/.openrc.sh
container=`hostname -s`

if [ ! -f $HOME/.pca-venv/bin/activate ]; then
	echo "No $HOME/.pca-venv, stopping."
	exit 1
fi
. $HOME/.pca-venv/bin/activate

backupAll () {
	for i in $*
	do
		backupOne $i
	done
}

# Backup one directory, using tar for the backup and
# gpg to compress and encrypt it.
backupOne () {
	# First argument is the directory to backup
	dir=`echo $1 | sed 's%^/%%'`
	shift
	# Other arguments are extra args to tar (i.e. exclusions)

	dt=`date +%Y%m%d`
	out=`basename $dir`-$dt.tar.gpg
	echo "tar -C / $* -c $dir | \
		gpg --no-use-agent --batch --passphrase $GPG_PASSPHRASE \
			--compress-algo bzip2 -c | \
		swift --info upload --object-name $out $container -"
}

# Check objects in this server's container for ones older than
# the limit, and delete them.

limit=`date -d '10 days ago' +%s`
swift list -l $container | \
while read sz d1 d2 typ name
do
	# swift list -l prints the total size as the last line
	if [ -z "$d1" ]; then
		continue
	fi
	d=`date -d "$d1 $d2" +%s`

	if [ $d -lt $limit ]; then
		echo swift delete $container $name
		swift delete $container $name
	fi
done

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
		# authoratative for. (Exclusions start without leading
		# slash because we remove it in backupOne.)
		backupOne /home \
			--exclude=home/unifield_backups \
			--exclude=home/production-dbs
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

