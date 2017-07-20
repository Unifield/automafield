#!/bin/sh

# Export the postgresql dump of the important postgresql
# databases.
# Author: Bacchi, jra
# Creation date: 23.12.2010

set -e

DBLIST="jira_prod ops_archive ufdb jasperserver"

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

