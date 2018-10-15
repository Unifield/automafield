#! /bin/bash

# To run this in cron, you need to give the password as an
# env variable:
#
# 50 1    * * *   sync-prod    HTTP_PASS=xxx /usr/local/bin/restore_last_sync.sh
#
# HTTP_PASS: the password on https://uf6.unifield.org/unifield_backups
#
# This script depends on psql_kill_active_connection.sh being
# available in /usr/local/bin. Use a symlink to make sure that's true.

URL="https://uf6.unifield.org/unifield_backups/dump_msfsync-slave/"
HTTP_USER="msf"

# no-check-cert because wget does not understand how to check SANs right.
wget_cmd="wget --no-check-certificate --quiet --http-user ${HTTP_USER} --http-password ${HTTP_PASS}"
RESULT="/tmp/LAST_SYNC$$.sql.lzma"
DB=${1:-DAILY_SYNC_SERVER}
/etc/init.d/sync-prod-server stop > /dev/null
fname=`$wget_cmd ${URL}?F=0 -O - | grep -Eo 'SYNC_SERVER-[0-9-]*.sql.lzma' | tail -1`

TABLESPACE="-D ssdspace"
#TABLESPACE=""
$wget_cmd ${URL}${fname} -O ${RESULT}

sudo -u postgres /usr/local/bin/psql_kill_active_connection.sh $DB
dropdb $DB
createdb ${TABLESPACE} $DB
lzma -d --stdout ${RESULT} | psql $DB > /dev/null 2>&1
rm -f ${RESULT}

LIGHT_DB=$DB
#LIGHT_DB="${DB}_LIGHT"
#WITH_MASTER="${DB}_LIGHT_WITH_MASTER"
#sudo -u postgres /usr/local/bin/psql_kill_active_connection.sh ${LIGHT_DB}
#dropdb ${LIGHT_DB}
#createdb ${TABLESPACE} ${LIGHT_DB} -T $DB
psql ${LIGHT_DB} <<EOF >> /dev/null
UPDATE ir_module_module set state='to upgrade' where name='update_client';
TRUNCATE sync_server_entity_rel;
DELETE FROM sync_server_update u WHERE u.rule_id IN (SELECT id FROM sync_server_sync_rule WHERE active ='f' OR master_data='f') AND u.create_date < now() - interval '2 months';
DELETE FROM sync_server_message WHERE create_date < now() - interval '2 months';
EOF
pg_dump -Fc ${LIGHT_DB} > ~/exports/SYNC_SERVER_LIGHT_WITH_MASTER

# ONLY MASTER
#NO_MASTER="${DB}_LIGHT_NO_MASTER"
#sudo -u postgres /usr/local/bin/psql_kill_active_connection.sh ${NO_MASTER}
#dropdb ${NO_MASTER}
#createdb ${TABLESPACE} ${NO_MASTER} -T ${WITH_MASTER}
psql ${LIGHT_DB} <<EOF >> /dev/null
DELETE FROM sync_server_update u WHERE u.create_date < now() - interval '2 months';
EOF
pg_dump -Fc ${LIGHT_DB} > ~/exports/SYNC_SERVER_LIGHT_NO_MASTER

# 7 days
#DAYS_7="${DB}_LIGHT_7days"
#sudo -u postgres /usr/local/bin/psql_kill_active_connection.sh ${DAYS_7}
#dropdb ${DAYS_7}
#createdb ${TABLESPACE} ${DAYS_7} -T ${NO_MASTER}
psql ${LIGHT_DB} <<EOF >> /dev/null
DELETE FROM sync_server_update u WHERE u.create_date < now() - interval '7 days';
DELETE FROM sync_server_message WHERE create_date < now() - interval '7 days';
EOF
pg_dump -Fc ${LIGHT_DB} > ~/exports/SYNC_SERVER_LIGHT_7DAYS

# NO UPDATE
#NO_UPDATE="${DB}_LIGHT_NO_UPDATE"
#sudo -u postgres /usr/local/bin/psql_kill_active_connection.sh ${NO_UPDATE}
#dropdb ${NO_UPDATE}
#createdb ${TABLESPACE} ${NO_UPDATE} -T ${DAYS_7}

# insert 1 fake update so last sequence is not 0
psql ${LIGHT_DB} <<EOF >> /dev/null
TRUNCATE sync_server_update;
TRUNCATE sync_server_message;
INSERT INTO sync_server_update (sequence) (SELECT number_next from ir_sequence where code='sync.server.update');
EOF
pg_dump -Fc ${LIGHT_DB} > ~/exports/SYNC_SERVER_LIGHT_NO_UPDATE

#cp ~/exports/* /srv/LXC/10.04/home/sync-prod/exports/
/etc/init.d/sync-prod-server start > /dev/null

