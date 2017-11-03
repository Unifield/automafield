#!/bin/sh

# Remove ocp-test-dbs backups older than 15 days
#
# Author: djl

cd /home/ocp-test-dbs/exports/

# Remove backups older than 15 days
find . -mtime +15 -exec rm {} \;
