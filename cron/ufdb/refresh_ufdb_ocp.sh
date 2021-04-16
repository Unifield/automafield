#!/bin/sh

# Refresh
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_refresh_tables('OCP');"

# Create views
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OCP');"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OC_X');"


sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_set_users_right();"
