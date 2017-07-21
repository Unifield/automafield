#! /bin/bash

if [ -z "$1" ]; then
	echo "$0 <dbname>"
	exit 0
fi
psql -d $1 -c "SELECT pg_terminate_backend(procpid) from pg_stat_activity  where datname=current_database() and procpid != pg_backend_pid();" > /dev/null
