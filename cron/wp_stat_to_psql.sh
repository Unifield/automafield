sudo -u postgres psql postgres -w -d wp -c "DROP SCHEMA wp CASCADE;"
sudo -u postgres psql postgres -w -d wp -c "CREATE SCHEMA wp;"
pgloader /root/automafield/cron/pgloader.txt
