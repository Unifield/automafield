#!/bin/sh

# Refresh OCA
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_refresh_tables('OCA');"

# Create views
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OCA');"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OC_X');"


sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_set_users_right();"
