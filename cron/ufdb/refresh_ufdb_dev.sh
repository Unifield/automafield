#!/bin/sh

# Refresh stock moves (GROUP BY to avoid erros on duplicates)
#sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb_dev.f_stock_move(name) FROM ufdb.f_get_instances(null) GROUP BY oc, name;"

# Refresh OCA
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb_dev.f_refresh_tables('OCA');"
#sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb_dev.f_create_view('OCA');"

# Refresh OCB
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb_dev.f_refresh_tables('OCB');"
#sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb_dev.f_create_view('OCB');"

# Refresh OCG
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb_dev.f_refresh_tables('OCG');"
#sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb_dev.f_create_view('OCG');"

# Refresh OCP
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb_dev.f_refresh_tables('OCP');"
#sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb_dev.f_create_view('OCP');"

#sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb_dev.f_set_users_right();"

