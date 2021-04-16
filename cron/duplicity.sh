#!/bin/sh

if [ ! -f $HOME/.duplicity-config.sh ]; then
	echo "No $HOME/.duplicity-config.sh file, stopping."
	exit 1
fi
. $HOME/.duplicity-config.sh

if [ ! -f $HOME/.duplicity-venv/bin/activate ]; then
	if [ "$1" != "build-venv" ]; then
		echo "No $HOME/.duplicity-venv, use \"$0 build-venv\" to build it."
		exit 1
	fi

	py=/usr/bin/python2.7
	# For uf5's weird install.
	[ ! -f $py ] && pw=/usr/local/python27/bin/python2.7

	set -e
	virtualenv -p $py $HOME/.duplicity-venv
	. $HOME/.duplicity-venv/bin/activate
	pip install python-swiftclient python-keystoneclient
	apt-get install -y build-essential librsync-dev
	pip install https://launchpad.net/duplicity/0.7-series/0.7.14/+download/duplicity-0.7.14.tar.gz
	echo "Virtualenv $HOME/.duplicity-venv installed successfully."
	exit 0

else
	. $HOME/.duplicity-venv/bin/activate
fi

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
	echo Running: duplicity --full-if-older-than 5D --asynchronous-upload --volsize 200 $* $dir $container
	duplicity --full-if-older-than 5D \
		  --asynchronous-upload --volsize 200 $* $dir $container

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
			/home/jiraprod/atlassian/application-data \
			/var/lib/dokuwiki/farm/wiki.unifield.org \
			/var/www/html/wordpress "
		backupAll $do

		# Exclude things from /home that we are not
		# authoratative for.
		backupOne /home \
			--exclude /home/unifield_backups \
			--exclude /home/production-dbs
	;;
	uf5-hw)
		do="/root /etc /opt /usr/local /home/testing/testfield/meta_features /home/testing/testfield/files"
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

