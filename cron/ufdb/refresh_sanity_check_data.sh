#!/bin/sh

# Refresh ufbi.t_system_data
sudo -u postgres psql postgres -w -d ufdb -c "SELECT ufbi.f_get_system_data();"

# Refresh ufbi.m_unrefreshed_tables
sudo -u postgres psql postgres -w -d ufdb -c "REFRESH MATERIALIZED VIEW ufbi.m_unrefreshed_tables;"
