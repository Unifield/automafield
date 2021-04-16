#!/bin/sh

# Refresh stock moves (GROUP BY to avoid erros on duplicates)
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_stock_move(name) FROM ufdb.f_get_instances(null) WHERE date >= '2020-01-01' AND oc='OCB' GROUP BY oc, name;"

# Create views
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OCA');"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OCB');"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OCG');"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OCP');"
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_create_view('OC_X');"


sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb.f_set_users_right();"

