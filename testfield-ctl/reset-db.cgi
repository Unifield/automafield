#!/bin/sh

PGPASSWORD=selenium_testing
psql="psql -t -h localhost -p 8014 -U selenium_testing postgres"

echo "content-type: text/html"
echo

db_list() {
	dbs=`$psql -c "select datname from pg_database where datistemplate = 'f'order by datname" 2>&1`
	if [ $? != 0 ]; then
		echo error: $dbs
		exit 1
	fi

	echo "<ul>"
	for db in $dbs
	do
		if [ $db = "postgres" ]; then
			continue
		fi
		echo $db | grep -q '_bak$'
		if [ $? = 0 ]; then
			echo "<li>$db</li>"
		else
			echo "<li>$db <a href=\"reset-db.cgi?db=$db&action=backup\">backup</a> <a href=\"reset-db.cgi?db=$db&action=restore\">restore</a></li>"
		fi
	done
	echo "</ul>"
}

killconn() {
	for id in `$psql -c "SELECT procpid FROM pg_stat_activity WHERE datname = '$1'"`
	do
		$psql -c "select pg_terminate_backend($id)" >/dev/null
	done
}

copydb() {
	db=$1
	db2="${db}_bak"

	killconn $db
	$psql -c "create database \"$db2\" template \"$db\""
}

restoredb() {
	db=$1
	db2="${db}_bak"
	db3="${db}_new"

	killconn $db2
	$psql -c "create database \"$db3\" template \"$db2\""
	if [ $? == 0 ]; then
		killconn $db
		$psql -c "drop database \"$db\"" 2>&1
		$psql -c "alter database \"$db3\" rename \"$db\"" 2>&1
	else
		echo "Backup a database before trying to restore it."
	fi
}

# http://stackoverflow.com/questions/3919755/how-to-parse-query-string-from-a-bash-cgi-script
getvar() {
	s='s/^.*'${1}'=\([^&]*\).*$/\1/p'
	echo $QUERY_STRING | sed -n $s | sed "s/%20/ /g"
}

if [ -z "$QUERY_STRING" ]; then
	db_list
else
	# parse query string
	db=`getvar db`
	action=`getvar action`

	echo "<pre>"
	if [ "$action" = "restore" ]; then
		echo "restore db $db"
		restoredb $db
	elif [ "$action" = "backup" ]; then
		echo "backing up db $db"
		copydb $db
	fi
fi
exit 0

