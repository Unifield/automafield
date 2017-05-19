#!/bin/bash

. $HOME/.automafield.config.sh
SCRIPTS=$HOME/automafield/

_contains_element () {
    local e
    for e in ${@:2};
    do
        # matching 1:1
        [[ "$e" == "$1" ]] && return 0;

        # regex?
        REGEX=`echo $e | sed s/%/\.\*/g`

        if echo $1 | grep ^$REGEX$ > /dev/null;
        then
            return 0
        fi
    done

    return 1
}

_convert_name() {

    if echo $2 | grep '%' > /dev/null;
    then
        for db in `pct_all_instances $1 | sort`;
        do
            # regex?
            REGEX=`echo $2 | sed s/%/\.\*/g`

            if echo $db | grep ^$REGEX$ > /dev/null;
            then
                RESULT=$db
                return
            fi
        done

        RESULT=$2
    else
        RESULT=$2
        return
    fi

}

_prepare_config() {
    echo "OK"
}

pct_get_hwid(){

    case $1 in
    0)
        HWID=$MYHWID
        ;;

    1)
        HWID='c11d5c86cc46381b41321813708f3ed1'
        ;;
    2)
        HWID='3ca384248ffd038c9646f721cba31500'
        ;;

    3)
        HWID='95f83b7f704bf10d59d80f1be66f80b0'
        ;;


    4)
        HWID='2f496f630213c07ca3f7adfe28405403'
        ;;

    5)
        HWID='57b6a1a8095421135960c719269d85bf'
        ;;

    6)
        HWID='614e390f349411e7995218a905f57ef9'
        ;;

    *)
        HWID='XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    esac

    echo $HWID
}

pct_download() {

    if [[ $# < 2 ]];
    then
        echo "Usage: pct_download ct# [OCA|OCB|OCG] [ instance1 instance2 ...] "
        echo " Description: load all the databases coming from an OC."
        return 1
    fi

    HWID=$(pct_get_hwid $1)

    case $2 in
    OCB)
        BACKUPDIR=OCB_Backups
        LOGIN=$MY_LOGIN_OWNCLOUD
        PASSWORD=$MY_PASSWORD_OWNCLOUD
        ;;

    OCG)
        BACKUPDIR=OCG_Backups
        LOGIN=$MY_LOGIN_OWNCLOUD
        PASSWORD=$MY_PASSWORD_OWNCLOUD
        ;;

    OCA)
        BACKUPDIR=OCA_Backups
        LOGIN=$MY_LOGIN_OWNCLOUD
        PASSWORD=$MY_PASSWORD_OWNCLOUD
        ;;

    OCP|OCBA)
        echo OCP and OCBA are not available right now
        return 1
        ;;

    *)
        echo Unkown OC $2
        return 1
        ;;
    esac

    PORT=$NORMALPORT
    if [[ "0" == $1 ]];
    then
        PORT=$MYPORT
    fi

    if [[ "0" == $1 ]] || [[ "10" == $1 ]];

    then
        LOGIN_POSTGRES=$MY_POSTGRES_USERNAME
        PASSWORD_POSTGRES=$MY_POSTGRES_PASSWORD
    else
        LOGIN_POSTGRES=$POSTGRES_USERNAME
        PASSWORD_POSTGRES=$POSTGRES_PASSWORD
    fi

    export PGPASSWORD=$PASSWORD_POSTGRES

    source $ENV4SYNC

    python $SCRIPTS/import/insert_db.py "$HWID" "$LOGIN_POSTGRES" "$PASSWORD_POSTGRES" "$PORT" "$1" "$BACKUPDIR" "$LOGIN" "$PASSWORD" "$LOGIN_BACKUPS" "$PASSWORD_BACKUPS" ${@:3}
    rc=$?

    deactivate

    return $rc
}

setup_lettuce()
{
    if [[ "0" == $1 ]] || [[ "10" == $1 ]];
    then
        LOGIN_POSTGRES=$MY_POSTGRES_USERNAME
        PASSWORD_POSTGRES=$MY_POSTGRES_PASSWORD
    else
        LOGIN_POSTGRES=$POSTGRES_USERNAME
        PASSWORD_POSTGRES=$POSTGRES_PASSWORD
    fi

    PORT=$NORMALPORT
    if [[ "0" == $1 ]];
    then
        PORT=$MYPORT
    fi

    PATH_TESTFIELD=$SCRIPTS/testfield-$$
    if [[ -e $PATH_TESTFIELD ]]
    then
        rm -rf $PATH_TESTFIELD
    fi

    cp -R $SCRIPTS/testfield $PATH_TESTFIELD

    if [[ -e $PATH_TESTFIELD/files/file ]]
    then
        rm -rf $PATH_TESTFIELD/files/file
    fi

    if [[ $# == 4 ]]
    then
        cp "$4" $PATH_TESTFIELD/files/file
    fi

    if [[ -e $PATH_TESTFIELD/config.sh ]]
    then
        rm $PATH_TESTFIELD/config.sh
    fi

    ADMINPASSWORD=`pct $1 $2 -c 'SELECT password FROM res_users WHERE id = 1' -t | tr -d '[[:space:]]'`
    ADMINUSERNAME=`pct $1 $2 -c 'SELECT login FROM res_users WHERE id = 1' -t | tr -d '[[:space:]]'`

    cat <<EOF > $PATH_TESTFIELD/config.sh
#!/bin/bash

SERVER_HOST=ct$1

NETRPC_PORT=8070
WEB_PORT=8061
XMLRPC_PORT=8069
XMLRPCS_PORT=8071

UNIFIELDADMIN=$ADMINUSERNAME
UNIFIELDPASSWORD=$ADMINPASSWORD

DBPASSWORD=$LOGIN_POSTGRES
DBADDR=ct$1
DBUSERNAME=$PASSWORD_POSTGRES
DBPORT=$PORT
EOF

    PREVIOUS=$PWD
    cp $SCRIPTS/$3 $PATH_TESTFIELD/
    cd $PATH_TESTFIELD
    ./generate_credentials.sh

    source $ENV4SYNC

    OLDDISPLAY=$DISPLAY
    tmux new -d -s X_$$ "Xvfb :$$"
    export DISPLAY=:$$
}

clean_lettuce(){

    cd $PREVIOUS
    deactivate

    rm -rf $SCRIPTS/testfield-$$

    export DISPLAY=$OLDDISPLAY
    tmux kill-session -t X_$$ 2> /dev/null
}


pct_upgrade() {

    if [[ $# != 4 ]];
    then
        echo "Usage: pct_upgrade ct# SYNC_SERVER ONE_INSTANCE patch.zip"
        echo " Description: Upgrade database SYNC_SERVER and ONE_INSTANCE on ct# with the given patch.zip"
        return
    fi

    _convert_name $1 $2
    export LETTUCE_SYNC_SERVER=$RESULT
    export LETTUCE_REVISION=$4
    _convert_name $1 $3
    export LETTUCE_DATABASE=$RESULT

    setup_lettuce $1 $LETTUCE_SYNC_SERVER patching.meta_feature "$4"


    BEFORE_TIME=$TIME_BEFORE_FAILURE
    export TIME_BEFORE_FAILURE=

    if ./runtests_local.sh patching.meta_feature 1>&2 > /dev/null;
    then
        echo "Upgrade $LETTUCE_SYNC_SERVER $LETTUCE_DATABASE: OK"
        RET=0
    else
        echo "Upgrade $LETTUCE_SYNC_SERVER $LETTUCE_DATABASE: FAILURE"
        RET=1
    fi

    export TIME_BEFORE_FAILURE=$BEFORE_TIME

    clean_lettuce

    return $RET
}

pct_sync() {

    if [[ $# != 2 ]];
    then
        echo "Usage: pct_sync ct# instance"
        echo " Description: synchronize the instance on ct# to its SYNC_SERVER"
        echo "WARNING: We use the SAME credentials to connect to the instance and to connect to the"
        echo "         sync server. You have to ensure that these credentials are identical with pct_password"

        return
    fi

    _convert_name $1 $2
    export LETTUCE_DATABASE=$RESULT

    setup_lettuce $1 $LETTUCE_DATABASE synchronize.feature

    BEFORE_TIME=$TIME_BEFORE_FAILURE
    export TIME_BEFORE_FAILURE=

    # remove the backups before/after sync
    pct $1 $LETTUCE_DATABASE -q -c "UPDATE backup_config SET beforemanualsync='f', beforepatching='f', aftermanualsync='f'"

    if ./runtests_local.sh synchronize.feature 1>&2 > /dev/null;
    then
        echo "Sync $LETTUCE_DATABASE: OK"
        RET=0
    else
        echo "Sync $LETTUCE_DATABASE: FAILURE"
        RET=1
    fi

    export TIME_BEFORE_FAILURE=$BEFORE_TIME

    clean_lettuce

    return $RET
}

pct_syncall() {

    if [[ $# < 1 ]];
    then
        echo "Usage: pct_syncall ct# [ instance1 instance2 ... ]"
        echo " Description: synchronize all the instances (or the given one) on ct#"
        echo "WARNING: We use the SAME credentials to connect to the instance and to connect to the"
        echo "         sync server. You have to ensure that these credentials are identical with pct_password"
        return
    fi

    for db in `pct_other_instances $1`;
    do
        if [[ $# == 1 ]] || _contains_element $db ${@:2};
        then
            pct_sync $1 $db
        fi
    done
}

pct_link() {

    if [[ $# != 3 ]]
    then
        echo "Usage: pct_link ct# SYNC_SERVER instance"
        echo " Description: link the instance to SYNC_SERVER on ct#"
        return
    fi

    _convert_name $1 $2
    SYNC_SERVER_NAME=$RESULT
    _convert_name $1 $3
    INSTANCE_NAME=$RESULT

    ADMINUSERNAME=`pct $1 $SYNC_SERVER_NAME -c 'SELECT login FROM res_users WHERE id = 1' -t | tr -d '[[:space:]]'`
    INSTANCENAME=`pct $1 $INSTANCE_NAME -c "SELECT name FROM sync_client_entity" -t`
    HWID=$(pct_get_hwid $1)

    echo "Linking $INSTANCE_NAME"
    pct $1 $INSTANCE_NAME -q -c "UPDATE sync_client_sync_server_connection SET protocol = 'xmlrpc', login = '$ADMINUSERNAME', database = '$SYNC_SERVER_NAME', host='127.0.0.1', port=8069"
    pct $1 $SYNC_SERVER_NAME -q -c "UPDATE sync_server_entity SET hardware_id = '$HWID' WHERE name = trim('$INSTANCENAME')"
}

pct_linkall() {

    if [[ $# < 2 ]]
    then
        echo "Usage: pct_linkall ct# SYNC_SERVER [ instance1 instance2 ... ]"
        echo " Description: link all instances on ct# (or the given ones) to the SYNC_SERVER"
        return
    fi

    LOGIN=`pct $1 $2 -c "SELECT login FROM res_users WHERE id = 1" -t`

    for db in `pct_other_instances $1`;
    do
        if [[ $# == 2 ]] || _contains_element $db ${@:3};
        then
            pct_link $1 $2 $db
        fi
    done
}

pct_password()
{
    if [[ $# != 3 ]]
    then
        echo "Usage: pct_password ct# instance password"
        echo " Description: reset the passwords on ct# for the given instance"
        return
    fi

    _convert_name $1 $2
    INSTANCENAME=$RESULT

    # As of version 2.1-3, logins are stored in lowercase in the database.
    lpw=`echo $3| tr 'A-Z' 'a-z'`

    pct $1 $INSTANCENAME -q -c "UPDATE res_users SET login = '$lpw', password = '$3' WHERE id = 1" > /dev/null

    # To keep the number of plaintext passwords floating around to a
    # minimum, wipe out all the plaintext passwords, set them to the
    # same as the admin user.
    pct $1 $INSTANCENAME -q -c "UPDATE res_users SET password = '$3'" > /dev/null
}

pct_passwordall()
{
    if [[ $# < 2 ]]
    then
        echo "Usage: pct_passwordall ct# password [ instance1 instance2 ...] "
        echo " Description: reset the admin password on ct# for all the instances (or the given ones)"
        return
    fi

    for db in `pct_all_instances $1`;
    do
        if [[ $# == 2 ]] || _contains_element $db ${@:3};
        then
	    echo "Setting passwords on $db."
            pct_password $1 $db $2
        fi
    done
}


pct_sqldump()
{
    if [[ $# < 2 ]]
    then
        echo "Usage: pct_sqldump ct# instance [ file ]"
        echo " Description: dump the instance on ct# and save it in file.sql"
        return
    fi

    if [[ "0" == $1 ]] || [[ "10" == $1 ]];
    then
        LOGIN_POSTGRES=$MY_POSTGRES_USERNAME
        PASSWORD_POSTGRES=$MY_POSTGRES_PASSWORD
    else
        LOGIN_POSTGRES=$POSTGRES_USERNAME
        PASSWORD_POSTGRES=$POSTGRES_PASSWORD
    fi

    export PGPASSWORD=$PASSWORD_POSTGRES

    _convert_name $1 $2
    INSTANCENAME=$RESULT

    echo "Dumping $INSTANCENAME"

    if [[ "" == $3 ]];
    then
        pg_dump $PGV --no-owner -U $LOGIN_POSTGRES -h ct$1 $INSTANCENAME -f $INSTANCENAME.sql
    else
        pg_dump $PGV --no-owner -U $LOGIN_POSTGRES -h ct$1 $INSTANCENAME -f $3.sql
    fi
}

pct_sqldumpall()
{
    if [[ $# < 1 ]]
    then
        echo "Usage: pct_sqldump ct# [ instance1 instance2 ... ]"
        echo " Description: dump all the instances of ct# (or the given subset) in SQL files"
        echo "               you can use % as a wildcard character"
        return 1
    fi

    for db in `pct_all_instances $1`;
    do
        if [[ $# == 1 ]] || _contains_element $db ${@:2};
        then
            pct_sqldump $1 $db
        fi
    done
}

pct()
{
    if [[ $# == 0 ]];
    then
        echo "Usage: pct ct# [ instance ] [ args ]"
        echo " Description: launch psql on ct# on the given instance with the given arguments"
        return 1
    fi

    if [[ "0" == $1 ]] || [[ "10" == $1 ]];
    then
        LOGIN_POSTGRES=$MY_POSTGRES_USERNAME
        PASSWORD_POSTGRES=$MY_POSTGRES_PASSWORD
    else
        LOGIN_POSTGRES=$POSTGRES_USERNAME
        PASSWORD_POSTGRES=$POSTGRES_PASSWORD
    fi

    export PGPASSWORD=$PASSWORD_POSTGRES

    PORT=$NORMALPORT

    if [[ "0" == $1 ]];
    then
        PORT=$MYPORT
    fi

    if [[ "" == $2 ]];
    then
        psql -p $PORT -U $LOGIN_POSTGRES -h ct$1 -d postgres "${@:3}"
    else
        _convert_name $1 $2
        psql -p $PORT -U $LOGIN_POSTGRES -h ct$1 -d $RESULT "${@:3}"
    fi
}


pct_all_instances()
{
    if [[ $# != 1 ]];
    then
        echo "Usage: pct_all_instances ct#"
        echo " Description: list all the instances servers on ct#"
        return 1
    fi

    for instance in `pct $1 postgres -c "SELECT datname FROM pg_database WHERE datistemplate = 'n' AND datname != 'postgres'" -t`;
    do
        echo $instance
    done
}

pct_sync_servers()
{
    if [[ $# != 1 ]];
    then
        echo "Usage: pct_sync_servers ct#"
        echo " Description: list all the sync servers on ct#"
        return 1
    fi

    for instance in `pct_all_instances $1`;
    do
        for yes in `pct $1 $instance -c "SELECT 1 FROM information_schema.tables WHERE  table_catalog = '$instance' AND table_name = 'sync_server_entity'" -t`;
        do
            echo $instance
        done
    done
}

pct_other_instances()
{
    if [[ $# != 1 ]];
    then
        echo "Usage: pct_other_instances ct#"
        echo " Description: list all the instances used by users on ct#"
        return 1
    fi

    for instance in `pct_all_instances $1`;
    do
        for yes in `pct $1 $instance -c "SELECT 1 FROM information_schema.tables WHERE  table_catalog = '$instance' AND table_name = 'sync_client_version'" -t`;
        do
            echo $instance
        done
    done
}

pct_restore()
{
    if [[ $# < 2 ]]
    then
        echo "Usage: pct_restore ct# instance [ filename ]"
        echo " Description: restore in ct# the instance with the given filename"
        echo "               if the filename is not provided, we will use instance.dump or instance.sql"
        echo "               sql et dump files are used accoding to their definition"
        return 1
    fi

    _convert_name $1 $2
    DBNAME=$RESULT

    pct_drop $1 $DBNAME
    pct $1 postgres -q -c "CREATE DATABASE \"$DBNAME\""

    if [[ "0" == $1 ]] || [[ "10" == $1 ]];
    then
        LOGIN_POSTGRES=$MY_POSTGRES_USERNAME
        PASSWORD_POSTGRES=$MY_POSTGRES_PASSWORD
    else
        LOGIN_POSTGRES=$POSTGRES_USERNAME
        PASSWORD_POSTGRES=$POSTGRES_PASSWORD
    fi

    PORT=$NORMALPORT

    if [[ "0" == $1 ]];
    then
        PORT=$MYPORT
    fi

    export PGPASSWORD=$PASSWORD_POSTGRES

    if [[ "" == $3 ]];
    then
        if [[ -f "${DBNAME}.dump" ]];
        then
            echo "Restore $DBNAME (${DBNAME}.dump)"
            pg_restore $PGV -p $PORT -n public -U $LOGIN_POSTGRES --no-acl --no-owner -h ct$1 -d $DBNAME ${DBNAME}.dump
	    [ $? != 0 ] && return $?
        else
            if [[ ! -f "${DBNAME}.sql" ]]
            then
                echo "No file $DBNAME found (sql/dump)"
                return 1
            fi

            echo "Restore $DBNAME (${DBNAME}.sql)"
            pct $1 $DBNAME < "${DBNAME}.sql"
        fi
    else

        if [[ ! -f "${3}" ]]
        then
            echo "No file $3 found"
            return 1
        fi

        if echo $3 | grep -i '.sql$' > /dev/null;
        then
            echo "Restore $DBNAME ($3)"
            pct $1 $DBNAME < $3
        else
            echo "Restore $DBNAME ($3)"
            pg_restore $PGV -p $PORT -n public -U $LOGIN_POSTGRES --no-acl --no-owner -h ct$1 -d $DBNAME $3
	    [ $? != 0 ] && return $?
        fi
    fi

    # remove all the automatic tasks
    pct $1 $DBNAME -q -c "UPDATE ir_cron SET active = 'f' WHERE model = 'backup.config'"
    pct $1 $DBNAME -q -c "UPDATE ir_cron SET active = 'f' WHERE model = 'sync.client.entity'"
    pct $1 $DBNAME -q -c "UPDATE ir_cron SET active = 'f' WHERE model = 'stock.mission.report'"
    if [ "$1" = "0" ]; then
	pct $1 $DBNAME -q -c "UPDATE backup_config SET beforemanualsync='f', beforepatching='f', aftermanualsync='f', beforeautomaticsync='f', afterautomaticsync='f', name = '/tmp'"
    else
	pct $1 $DBNAME -q -c "UPDATE backup_config SET beforemanualsync='f', beforepatching='f', aftermanualsync='f', beforeautomaticsync='f', afterautomaticsync='f', name = E'd:\\\\'"
    fi
}

pct_restoreall()
{
    if [[ $# < 1 ]]
    then
        echo "Usage: pct_restoreall ct# [ instance1 instance2 ... ] "
        echo " Description: restore all the instances (*.dump and *.sql) in the current directory (or the given subset)"
        return 1
    fi

    for DBFILE in `ls *.dump 2> /dev/null` `ls *.sql 2> /dev/null`;
    do
        DATABASE=${DBFILE%%.dump}
        DATABASE=${DATABASE%%.sql}

        FOUND=n

        if [[ $# == 1 ]];
        then
            FOUND=y
        else

            for arg in ${@:2};
            do

                REGEX=`echo $arg | sed s/%/\.\*/g`

                if echo $DATABASE | grep ^$REGEX$ > /dev/null;
                then
                    FOUND=y
                fi
            done
        fi

        if [[ $FOUND == y ]];
        then
            echo "Restore $DATABASE (dump/sql)"
            pct_restore $1 $DATABASE $DBFILE
	    if [ $? != 0 ]; then
		break
	    fi
        fi
    done
}

pct_drop()
{
    if [[ $# != 2 ]]
    then
        echo "Usage: pct_drop ct# instance"
        echo " Description: drop the instance in ct#"
        return 1
    fi

    INSTANCES=(`pct_all_instances $1`)

    _convert_name $1 $2
    INSTANCE=$RESULT

    VERSION=$(pct $1 postgres -t -c  "SHOW SERVER_VERSION")
    MAJOR_VERSION=${VERSION:1:1}

    if [[ $MAJOR_VERSION == 8 ]]
    then
        DB_PROCID=procpid
    else
        DB_PROCID=pid
    fi

    if _contains_element $INSTANCE ${INSTANCES[@]};
    then
        echo Drop $INSTANCE
        BEFORE_IFS=$IFS
        IFS=' '
        E="$(pct $1 postgres -t -c "SELECT 'select pg_terminate_backend(' || $DB_PROCID || ');' FROM pg_stat_activity WHERE datname = '$INSTANCE'")"
        IFS=';'
        for line in $(echo -e "$E");
        do
            pct $1 postgres -c $line > /dev/null 2>&1
        done

        IFS=$BEFORE_IFS

        pct $1 postgres -q -c "DROP DATABASE \"$INSTANCE\""
        return 0
    else
        return 1
    fi
}

pct_dropall()
{
    if [[ $# < 1 ]]
    then
        echo "Usage: pct_dropall ct# [ instance1 instance2 ... ] "
        echo " Description: drop all the instances of ct# (or the given subset)"
        echo "               you can use % as a wildcard character"
        return 1
    fi

    for db in `pct_all_instances $1`;
    do
        if [[ $# == 1 ]] || _contains_element $db ${@:2};
        then
            echo Dropping $db
            pct_drop $1 $db
        fi
    done
}

pct_dump()
{
    if [[ $# < 2 ]]
    then
        echo "Usage: pct_dump ct# instance [ file ]"
        echo " Description: dump the instance on ct# and save it in file.dump"
        return
    fi

    if [[ "0" == $1 ]] || [[ "10" == $1 ]];
    then
        LOGIN_POSTGRES=$MY_POSTGRES_USERNAME
        PASSWORD_POSTGRES=$MY_POSTGRES_PASSWORD
    else
        LOGIN_POSTGRES=$POSTGRES_USERNAME
        PASSWORD_POSTGRES=$POSTGRES_PASSWORD
    fi

    PORT=$NORMALPORT

    if [[ "0" == $1 ]];
    then
        PORT=$MYPORT
    fi

    export PGPASSWORD=$PASSWORD_POSTGRES

    _convert_name $1 $2
    INSTANCE=$RESULT

    if [[ "" == $3 ]];
    then
        pg_dump $PGV -p $PORT --no-owner -Fc -U $LOGIN_POSTGRES -h ct$1 $INSTANCE -f ${INSTANCE}.dump
    else
        pg_dump $PGV -p $PORT --no-owner -Fc -U $LOGIN_POSTGRES -h ct$1 $INSTANCE -f $3.dump
    fi
}

pct_dumpall()
{
    if [[ $# < 1 ]]
    then
        echo "Usage: pct_dumpall ct# [ instance1 instance2 ... ]"
        echo " Description: dump all the instances of ct# (or the given subset)"
        echo "               you can use % as a wildcard character"
        return 1
    fi

    for db in `pct_all_instances $1`;
    do
        if [[ $# == 1 ]] || _contains_element $db ${@:2};
        then
            echo "Dumping $db"
            pct_dump $1 $db
        fi
    done
}

pct_login()
{
    local VAL OPTIND OPTAR

    TIMEOUT=
    while getopts ':t:' VAL;
    do
        case $VAL in
        t)
            TIMEOUT=$OPTARG
            ;;
        *)
            echo "Unkown argument"
            exit
        esac
    done

    ARGS=("${@:OPTIND}")

    if [[ ${#ARGS[*]} != 2 ]]
    then
        echo "Usage: pct_login [-t TIMEOUT] ct# instance"
        echo " Description: log into the instance in ct#. Wait for the upgrade to process if necessary"
        return
    fi

    _convert_name ${ARGS[0]} ${ARGS[1]}
    export LETTUCE_DATABASE=$RESULT

    setup_lettuce ${ARGS[0]} $LETTUCE_DATABASE login.feature

    BEFORE_TIME=$TIME_BEFORE_FAILURE
    export TIME_BEFORE_FAILURE=$TIMEOUT

    if ./runtests_local.sh login.feature >/dev/null 2>&1
    then
        echo "Login $LETTUCE_DATABASE: OK"
        RET=0
    else
        echo "Login $LETTUCE_DATABASE: FAILURE"
        RET=1
    fi

    export TIME_BEFORE_FAILURE=$BEFORE_TIME

    clean_lettuce

    return $RET
}

pct_loginall()
{
    local VAL OPTIND OPTAR

    ARGSPCT_LOGIN=
    while getopts ':t:' VAL;
    do
        case $VAL in
        t)
            ARGSPCT_LOGIN="-t $OPTARG"
            ;;
        *)
            echo "Unkown argument"
            exit
        esac
    done

    ARGS_LOGINALL=("${@:OPTIND}")

    if [[ ${#ARGS_LOGINALL[*]} < 1 ]]
    then
        echo "Usage: pct_loginall [-t TIMEOUT] ct# [ instance1 instance2 ... ]"
        echo " Description: log into all the instances (or the given one) in ct#"
        return 1
    fi

    for db in `pct_all_instances ${ARGS_LOGINALL[0]}`
    do
        RET=${ARGS_LOGINALL:0}

        INSTANCES=("${@:OPTIND+1}")

        if [[ ${#ARGS_LOGINALL[*]} == 1 ]] || _contains_element $db ${INSTANCES[@]};
        then
            pct_login $ARGSPCT_LOGIN ${ARGS_LOGINALL[0]} $db
        fi
    done
}

pct_recentsync()
{
    if [[ $# != 2 ]]
    then
        echo "Usage: pct_recentsync ct# instance"
        echo " Description: find the time of the most recent sync"
        return 1
    fi

    inst=`echo "$2" | cut -d_ -f1`
    source=`pct $1 SYNC_SERVER_XXX -t -c "select id from sync_server_entity where name = '$inst'"`
    if [ -z "$source" ]; then
	echo "Unknown instance $inst".
	return 1
    fi
    dt=`pct $1 SYNC_SERVER_XXX -t -c "select write_date from sync_server_update where source = $source order by write_date desc limit 1" | sed 's/^ //'`
    if [ -z "$dt" ]; then
	echo "$2: no recent sync date available"
	return 1
    fi
    echo "$inst: last sync $dt"
}

pct_import()
{
    if [[ $# != 4 ]]
    then
        echo "Usage: pct_import ct# instance [sync_rule|message_rule|BAR|ACL|FAR|FAR_lines|user_rights|record_rules|window_actions] file"
        echo " Description: import file (type sync_...) in instance on ct#"
        return 1
    fi

    FEATURE_NAME=

    case $3 in
    sync_rule)
        export FEATURE_NAME=import_sync_data.feature
        ;;

    message_rule)
        export FEATURE_NAME=import_sync_message.feature
        ;;

    BAR)
        export FEATURE_NAME=BAR.feature
        ;;
    
    ACL)
        export FEATURE_NAME=ACL.feature
        ;;
    
    FAR)
        export FEATURE_NAME=FAR.feature
        ;;
    
    FAR_lines)
        export FEATURE_NAME=FAR_lines.feature
        ;;
    
    user_rights)
        export FEATURE_NAME=user_rights.feature
        ;;
    
    record_rules)
        export FEATURE_NAME=record_rules.feature
        ;;
    
    window_actions)
        export FEATURE_NAME=window_actions.feature
        ;;

    *)
        echo "I don't know file type $3"
        return 1

    esac

    if [[ -e "$4" ]]
    then

        _convert_name $1 $2
        export LETTUCE_DATABASE=$RESULT

        setup_lettuce $1 $LETTUCE_DATABASE $FEATURE_NAME "$4"
    else
        echo "File $4 does not exist"
        return 1
    fi

    BEFORE_TIME=$TIME_BEFORE_FAILURE
    export TIME_BEFORE_FAILURE=

    if ./runtests_local.sh $FEATURE_NAME ;
    then
        echo "Import $LETTUCE_DATABASE: OK"
        RET=0
    else
        echo "Import $LETTUCE_DATABASE: FAILURE"
        RET=1
    fi

    export TIME_BEFORE_FAILURE=$BEFORE_TIME

    clean_lettuce

    return $RET

    echo "OK"
}

pct_help()
{
    echo "List the databases:"
    echo "   pct_all_instances: returns all the databases"
    echo "   pct_other_instances: returns all the databases used for an instance that is not a sync server"
    echo "   pct_sync_servers: returns all the databases used for a sync server"
    echo
    echo "   pct_upgrade: apply a patch on a computer using the updater"
    echo "   pct_download: downloads dump files and restore them"
    echo "   pct_import: import CSV files in a database"
    echo "   pct_recentsync: find last connection to sync server"
    echo
    echo "Manage them:"
    echo "   pct_drop: drops a database"
    echo "   pct_dropall: drops all the databases (or a part of them)"
    echo "   pct_dump: backs up a database (.dump)"
    echo "   pct_dumpall: backs up all the databases (or a part of them)"
    echo "   pct_sqldump: back up a database (.sql)"
    echo "   pct_sqldumpall: back up all the databases (in the current directory)"
    echo "   pct_restore: restore a database"
    echo "   pct_restoreall: restore all the databases (in the current directory)"
    echo
    echo "Make them available:"
    echo "   pct_link: link two database (used for synchronization)"
    echo "   pct_linkall: link all the databases (used for synchronization)"
    echo "   pct_password: reset the admin password"
    echo "   pct_passwordall: reset the admin password in all the databases"
    echo
    echo "Update them:"
    echo "   pct_login: log in a database (used to upgrade it)"
    echo "   pct_loginall: log in all the databases (used to upgrade them)"
    echo "   pct_sync: synchronize an instance"
    echo "   pct_syncall: synchronize all the instances (according to their link)"
}

