#!/bin/sh

# Export the postgresql dump of the important postgresql
# databases.
# Author: Bacchi, jra
# Creation date: 23.12.2010

set -e

#DBLIST="jiraprod ops_archive ufdb jasperserver"
DBLIST="jiraprod ops_archive jasperserver"

# - process the export of all databases in the list
# 	- append the date and time on the filename
# 	- compress as bzip2 the export

mkdir -p /backup/postgres
cd /backup/postgres

# remove backups older than 30 days old
find . -mtime +30 -exec rm {} \;

for dbname in $DBLIST
do
  su postgres -c "pg_dump -Fc ${dbname} | bzip2 -c" > ${dbname}_$(date '+%Y-%m-%d_%H:%M:%S').dump.bz2
done

# for ufdb DB we want to dump jira schema data and only structure for others
su postgres -c "pg_dump -Fc ufdb --schema=jira | bzip2 -c" > ufdb_jira_$(date '+%Y-%m-%d_%H:%M:%S').dump.bz2

su postgres -c "pg_dump -Fc ufdb --schema-only | bzip2 -c" > ufdb_schemaonly_$(date '+%Y-%m-%d_%H:%M:%S').dump.bz2

mysqldump --defaults-file=/etc/mysql/debian.cnf uf_doc | bzip2 -c > uf_doc_mysql__$(date '+%Y-%m-%d_%H:%M:%S').sql.bz2
