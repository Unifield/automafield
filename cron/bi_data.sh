#!/bin/sh

csvFilePath=/home/djg/bi

######################################################################################

csvFile="instance_check.csv"
echo "-------------------------------------------------"
echo $csvFile

#set query in variable
query="SELECT DISTINCT s.instance_name, s.instance_creation_date, s.instance_last_actvity_date, y.db_name, y.date AS dump_date, s.version AS sync_server_version, x.dump_version
FROM dblink('host=127.0.0.1 port=5432 dbname=prod_SYNC_SERVER_LOCAL user=production-dbs', 'SELECT e.name AS instance_name, e.create_date AS instance_creation_date, e.state AS instance_state, max(a.datetime) AS instance_last_actvity_date, 
               CASE WHEN strpos(e.name, ''OCA'') > 0 THEN ''OCA'' WHEN strpos(e.name, ''OCB'') > 0 THEN ''OCB'' WHEN strpos(e.name, ''OCG'') > 0 THEN ''OCG'' END AS instance_oc,
               v.name AS version
               FROM sync_server_entity e
               INNER JOIN sync_server_entity_activity a ON e.id = a.entity_id
               LEFT JOIN sync_server_version v ON e.version_id = v.id
               GROUP BY e.name, e.create_date, e.state, v.name
               ORDER BY CASE WHEN strpos(e.name, ''OCA'') > 0 THEN 1 WHEN strpos(e.name, ''OCB'') > 0 THEN 2 WHEN strpos(e.name, ''OCG'') > 0 THEN 3 ELSE 9 END, e.name')
AS s(instance_name varchar, instance_creation_date date, instance_state varchar, instance_last_actvity_date date, instance_oc varchar, version varchar)

LEFT JOIN (SELECT instance, value1 as dump_version from public.f_query_all_db('SELECT name FROM sync_client_version ORDER BY applied DESC LIMIT 1')) x ON x.instance LIKE s.instance_name || '%'
LEFT JOIN (SELECT name as instance, db_name, date from ufdb.f_get_instances(null)) y ON y.instance LIKE s.instance_name || '%'

WHERE s.instance_state = 'validated'

and (y.date is null OR y.date <= now() - interval '1 week')
order by y.date desc"

#execute query in CSV file
psql --pset footer -P format=unaligned -P fieldsep=\, -c "$query" ufdb > $csvFilePath/$csvFile

######################################################################################

csvFile="uf_deployment_progress.csv"
echo "-------------------------------------------------"
echo $csvFile

#set query in variable
query="SELECT * FROM public.f_get_uf_deployment_progress(null);"

#execute query in CSV file
psql --pset footer -P format=unaligned -P fieldsep=\, -c "$query" ufdb > $csvFilePath/$csvFile

######################################################################################

echo "Send all files to Sharepoint"
for f in $csvFilePath/*.csv
do  
    echo "Send $(basename $f) to Sharepoint"
    python /home/djg/jasper/send_file_to_sharepoint/send_file_to_sharepoint.py -s $f -d /sites/msfintlcommunities/Unifield/sup_team/PowerBI -n $(basename $f)
done

