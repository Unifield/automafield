#!/bin/sh

csvFilePath=/home/djg/bi

######################################################################################

csvFile="instance_check.csv"
echo "-------------------------------------------------"
echo $csvFile

#set query in variable
query="SELECT DISTINCT s.instance_name, s.instance_creation_date, s.instance_last_actvity_date, y.db_name, y.date AS dump_date, s.version AS sync_server_version, x.dump_version
FROM dblink('host=uf7.unifield.org port=5432 requiressl=1 sslcert=/etc/postgresql/9.5/main/clientcert/uf5-hw@unifield.org.cer sslkey=/etc/postgresql/9.5/main/clientcert/uf5-hw@unifield.org.key dbname=prod_SYNC_SERVER_LOCAL user=production-dbs', 'SELECT e.name AS instance_name, e.create_date AS instance_creation_date, e.state AS instance_state, max(a.datetime) AS instance_last_actvity_date, 
               CASE WHEN strpos(e.name, ''OCA'') > 0 THEN ''OCA'' WHEN strpos(e.name, ''OCB'') > 0 THEN ''OCB'' WHEN strpos(e.name, ''OCG'') > 0 THEN ''OCG'' WHEN strpos(e.name, ''OCP'') > 0 THEN ''OCP'' END AS instance_oc,
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

/*and (y.date is null OR y.date <= now() - interval '1 week')*/
order by y.date desc"

#execute query in CSV file
psql --pset footer -P format=unaligned -P fieldsep=\, -c "$query" ufdb > $csvFilePath/$csvFile

######################################################################################

csvFile="uf_deployment_progress.csv"
echo "-------------------------------------------------"
echo $csvFile

#set query in variable
query="SELECT * FROM public.f_get_uf_deployment_progress(null) ORDER BY version, date;"

#execute query in CSV file
psql --pset footer -P format=unaligned -P fieldsep=\, -c "$query" ufdb > $csvFilePath/$csvFile

######################################################################################

csvFile="instance_coordo.csv"
echo "-------------------------------------------------"
echo $csvFile

#set query in variable
query="SELECT DISTINCT s.oc, s.instance_name, s.parent_instance_name, s.last_activity, s.state, s.version, s.pgversion, s.mission, s.city, s.country, s.latitude, s.longitude
FROM dblink('host=uf7.unifield.org port=5432 requiressl=1 sslcert=/etc/postgresql/9.5/main/clientcert/uf5-hw@unifield.org.cer sslkey=/etc/postgresql/9.5/main/clientcert/uf5-hw@unifield.org.key dbname=prod_SYNC_SERVER_LOCAL user=production-dbs', 'SELECT CASE WHEN strpos(e.name, ''OCA'') > 0 THEN ''OCA'' WHEN strpos(e.name, ''OCB'') > 0 THEN ''OCB'' WHEN strpos(e.name, ''OCG'') > 0 THEN ''OCG'' WHEN strpos(e.name, ''OCP'') > 0 THEN ''OCP'' END AS oc, e.name AS instance_name, p.name AS parent_instance_name, e.last_activity, e.state, v.name AS version, e.pgversion, e.mission, e.city, c.name AS country, e.latitude, e.longitude
FROM sync_server_entity e
LEFT JOIN sync_server_entity p ON e.parent_id = p.id
LEFT JOIN sync_server_version v ON e.version_id = v.id
LEFT JOIN res_country c ON e.country_id = c.id')
AS s(oc varchar, instance_name varchar, parent_instance_name varchar, last_activity date, state varchar, version varchar, pgversion varchar, mission varchar, city varchar, country varchar, latitude numeric, longitude numeric)"

#execute query in CSV file
psql --pset footer -P format=unaligned -P fieldsep=\, -c "$query" ufdb > $csvFilePath/$csvFile


######################################################################################

csvFile="instance_with_no_cc_target_for_fx_gain_loss.csv"
echo "-------------------------------------------------"
echo $csvFile

#set query in variable
query="SELECT DISTINCT aa.oc, aa.instance, i.state, aa.for_fx_gain_loss as has_one_CC_for_fx_gain_loss
FROM ufdb.t_analytic_account aa
INNER JOIN ufdb.t_instance i ON i.name = aa.instance
WHERE NOT EXISTS (SELECT 1 FROM ufdb.t_analytic_account WHERE instance = aa.instance AND for_fx_gain_loss = true AND category = 'Cost Center')
AND aa.category = 'Cost Center';"

#execute query in CSV file
psql --pset footer -P format=unaligned -P fieldsep=\, -c "$query" ufdb > $csvFilePath/$csvFile


######################################################################################

csvFile="jira_ticket_count_by_version.csv"
echo "-------------------------------------------------"
echo $csvFile

#set query in variable
query="SELECT projectversion.vname AS unifield_version,
projectversion.releasedate AS release_date,
projectversion.released,
       SUM (CASE WHEN issuetype.pname='Bug' THEN 1 ELSE 0 END) AS bug,
       SUM (CASE WHEN issuetype.pname='Improvement' THEN 1 ELSE 0 END) AS improvement
       
FROM jiraissue 

INNER JOIN issuetype ON issuetype.id = jiraissue.issuetype AND issuetype.pname in ('Bug','Improvement')
INNER JOIN nodeassociation ON nodeassociation.source_node_id = jiraissue.id AND nodeassociation.source_node_entity = 'Issue' AND nodeassociation.sink_node_entity = 'Version' AND nodeassociation.association_type = 'IssueFixVersion'
INNER JOIN projectversion ON projectversion.id = nodeassociation.sink_node_id
INNER JOIN project ON project.id = jiraissue.project AND project.pkey = 'US'

GROUP BY projectversion.vname, projectversion.sequence, projectversion.releasedate, projectversion.released

ORDER BY projectversion.sequence DESC;"

#execute query in CSV file
psql --pset footer -P format=unaligned -P fieldsep=\, -c "$query" jiraprod > $csvFilePath/$csvFile


######################################################################################

echo "Send all files to Sharepoint"
for f in $csvFilePath/*.csv
do  
    echo "Send $(basename $f) to Sharepoint"
    python /home/djg/jasper/send_file_to_sharepoint/send_file_to_sharepoint.py -s $f -d /sites/msfintlcommunities/Unifield/sup_team/PowerBI -n $(basename $f)
done

