#!/bin/sh

# Remove files older than 15 days
find $HOME/ocp-test-dbs/exports -mtime +15 -type f -delete

# Sync files from uf6 to uf5-hw.
# Folders remain the same. 
# Files are deleted to the destination if thesy don't appear from the source.
rsync -avz --include '*/' --include '*.dump' --exclude '*' --delete $HOME/ocp-test-dbs/exports/ root@uf6.unifield.org:/home/djg/ocp-test-dbs_backups/
