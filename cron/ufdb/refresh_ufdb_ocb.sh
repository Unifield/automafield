#!/bin/sh

# Refresh 
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_refresh_tables('OCB');"

# Create views
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OCB');"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OC_X');"

sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_set_users_right();"
