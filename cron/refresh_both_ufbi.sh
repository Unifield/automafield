#!/bin/sh

sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufbi.f_refresh_tables();"
date
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufbi.f_refresh_sync_tables();"
