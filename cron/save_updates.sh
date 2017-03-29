#!/bin/sh
set -e

BACKUP_DIR=$HOME/update_received_to_send

mkdir -p $BACKUP_DIR

PGHOST=localhost
PGPORT=8787
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
    msg "$(date) start $INSTANCE_DB"

    #UPDATE_RECEIVED
    id=0
    newid=0
    filename=''

    #get the current instance last inserted id
    if [ -f $BACKUP_DIR/${INSTANCE_NAME}_update_received_*.csv ]; then

        #get the filename and extract the last inserted id
        filename=$(basename $BACKUP_DIR/${INSTANCE_NAME}_update_received_*.csv)
        id=$(echo $filename | sed -e "s/${INSTANCE_NAME}_update_received_\(.*\).csv/\1/g")

        msg "$(date) UPDATE_RECEIVED filename=${filename}"
        msg "$(date) UPDATE_RECEIVED id=${id}"

    fi

    #get the last existing id
    newid=$(psql -d $INSTANCE_DB -tA -F "," -c "SELECT id FROM sync_client_update_received ORDER BY id DESC LIMIT 1;")
    msg "$(date) UPDATE_RECEIVED newid=${newid}"

    #no need to insert if  newid <= id
    if [ "$newid" -gt "$id" ]; then

        msg "$(date) UPDATE_RECEIVED insert new lines in csv file"

        #create csv file with new lines
        psql -d $INSTANCE_DB -c "\\copy (SELECT * FROM sync_client_update_received WHERE id > ${id}) to stdout csv" > $BACKUP_DIR/export.csv 
        if [ $? != 0 ]; then
                echo "$(date) UPDATE_RECEIVED Error on psql for instance ${INSTANCE_DB}" 
                exit 1
        else

            msg "$(date) UPDATE_RECEIVED merge old lines and new lines in a new file"

	    #create the new file before replacing the old one, so that if something goes
	    if [ "$id" != "0" ]; then
                cat $BACKUP_DIR/${INSTANCE_NAME}_update_received_${id}.csv $BACKUP_DIR/export.csv > $BACKUP_DIR/${INSTANCE_NAME}_update_received_${newid}.csv
	    else
	        cat $BACKUP_DIR/export.csv > $BACKUP_DIR/${INSTANCE_NAME}_update_received_${newid}.csv
	    fi

            if [ $? != 0 ]; then
		#wrong, we do not mess up the old file. Instead we leave things alone and
		#on the next run we can try again.
                rm $BACKUP_DIR/export.csv $BACKUP_DIR/${INSTANCE_NAME}_update_received_${newid}.csv
                echo "$(date) UPDATE_RECEIVED Error on merging files for instance ${INSTANCE_DB}, Disk full?" 
                exit 1
            elif [ "$id" != "0" ]; then
                msg "$(date) UPDATE_RECEIVED remove old csv file"
                rm $BACKUP_DIR/${INSTANCE_NAME}_update_received_${id}.csv
            fi
        fi
    else
        msg "$(date) UPDATE_RECEIVED nothing to update"
    fi

    #UPDATE_TO_SEND
    id=0
    newid=0
    filename=''

    #get the current instance last inserted id
    if [ -f $BACKUP_DIR/${INSTANCE_NAME}_update_to_send_*.csv ]; then

        #get the filename and extract the last inserted id
        filename=$(basename $BACKUP_DIR/${INSTANCE_NAME}_update_to_send_*.csv)
        id=$(echo $filename | sed -e "s/${INSTANCE_NAME}_update_to_send_\(.*\).csv/\1/g")

        msg "$(date) UPDATE_TO_SEND filename=${filename}"
        msg "$(date) UPDATE_TO_SEND id=${id}"

    fi

    #get the last existing id
    newid=$(psql -d $INSTANCE_DB -tA -F "," -c "SELECT id FROM sync_client_update_to_send ORDER BY id DESC LIMIT 1;")
    msg "$(date) UPDATE_TO_SEND newid=${newid}"
    
    #no need to insert if  newid <= id
    if [ "$newid" -gt "$id" ]; then

        msg "$(date) UPDATE_TO_SEND insert new lines in csv file"

        #create csv file with new lines
        psql -d $INSTANCE_DB -c "\\copy (SELECT * FROM sync_client_update_to_send WHERE id > ${id}) to stdout csv" > $BACKUP_DIR/export.csv 
        if [ $? != 0 ]; then
            echo "$(date) UPDATE_TO_SEND Error on psql for instance ${INSTANCE_DB}"
            exit 1
        else

            msg "$(date) UPDATE_TO_SEND merge old lines and new lines in a new file"

	    #create the new file before replacing the old one, so that if something goes
	    if [ "$id" != "0" ]; then
                cat $BACKUP_DIR/${INSTANCE_NAME}_update_to_send_${id}.csv $BACKUP_DIR/export.csv > $BACKUP_DIR/${INSTANCE_NAME}_update_to_send_${newid}.csv
	    else
	        cat $BACKUP_DIR/export.csv > $BACKUP_DIR/${INSTANCE_NAME}_update_to_send_${newid}.csv
	    fi

            if [ $? != 0 ]; then
		#wrong, we do not mess up the old file. Instead we leave things alone and
		#on the next run we can try again
                rm $BACKUP_DIR/export.csv $BACKUP_DIR/${INSTANCE_NAME}_update_to_send_${newid}.csv
                echo "$(date) UPDATE_TO_SEND Error on merging files for instance ${INSTANCE_DB}, Disk full?"
                exit 1
            elif [ "$id" != "0" ]; then
                msg "$(date) UPDATE_TO_SEND remove old csv file"
                rm $BACKUP_DIR/${INSTANCE_NAME}_update_to_send_${id}.csv
            fi
        fi

    else
        msg "$(date) UPDATE_TO_SEND nothing to update"
    fi

done

