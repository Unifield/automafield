#!/bin/sh

# Refresh stock moves (GROUP BY to avoid erros on duplicates)
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufdb_dev.f_stock_move(i.name, COALESCE(m.max_date, '1984-09-14')::date) FROM ufdb.f_get_instances(null) i LEFT JOIN (SELECT oc, instance, max(move_date) AS max_date FROM ufdb_dev.t_stock_move GROUP By oc, instance) m ON m.oc = i.oc AND m.instance = i.name GROUP BY i.oc, i.name, m.max_date;"

