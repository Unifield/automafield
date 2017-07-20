#!/bin/sh

# Refresh OCA
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_refresh_tables('OCA');"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OCA')"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_set_user_right('OCA')"

# Refresh OCB
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_refresh_tables('OCB');"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OCB')"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_set_user_right('OCB')"

# Refresh OCG
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_refresh_tables('OCG');"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OCG')"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_set_user_right('OCG')"

# Refresh MSR for all OCs
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_mission_stock_report(null)"
