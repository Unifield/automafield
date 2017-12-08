#!/bin/sh
set -e

BACKUP_DIR=$HOME/update_received_to_send_dumps

mkdir -p $BACKUP_DIR

PGHOST=localhost
PGPORT=5432
export PGHOST PGPORT

msg() {
	# Enable/Disable messages here
	#echo $*

	# This colon makes this function not give a syntax
	# error when the echo is commented. Stupid sh.
	:
}

#Loop on instances
psql -F' ' -tAc "select regexp_replace(replace( datname, 'prod_', ''), '_[0-9|_]+', '' ), datname from pg_database where datname like 'prod_%'" postgres | while read INSTANCE_NAME INSTANCE_DB ; do

    msg "----------------------------------------------------------------"
    msg "$(date) dump $INSTANCE_DB"

    pg_dump -Fc -Z9 -v -t sync_client_update_received -t sync_client_update_to_send ${INSTANCE_DB} | zip > ${INSTANCE_NAME}.zip
    

done

