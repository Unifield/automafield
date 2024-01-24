#!/bin/sh

last_sunday_date_seconds=$(date +"%s" -d "last sunday")
last_friday_date_seconds=$(date +"%s" -d "last friday")
last_saturday_date_seconds=$(date +"%s" -d "last saturday")
yesterday_date_seconds=$(date +"%s" -d "yesterday")
color_green="#b7edb4"
color_red="#edbfb4"

# ---------------------------------------------------------------- ufdb

html_ufdb_refresh="<th>ufdb</th>"

# Check if ufdb has been refreshed on last sunday by getting the last inserted PO per OC
result=`psql -qtAX -F, -d ufdb -c \
"SELECT oc, max(insert_date)::date AS last_insert_date
FROM ufdb.t_purchase_order
GROUP BY oc
/*HAVING max(insert_date)::date >= (current_date - cast(extract(dow from current_date) as int))*/
ORDER BY oc;"`

while IFS=',' read -r oc last_insert_date
do

    last_insert_date_seconds=$(date +"%s" -d "$last_insert_date")

    #if [[ ( "$oc" == "OCA" || "$oc" == "OCG" ) && "$last_insert_date_seconds" -ge "$last_friday_date_seconds" ]]; then
    #    color=$color_green
    #elif [[ "$last_insert_date_seconds" -ge "$last_sunday_date_seconds" ]]; then
    #    color=$color_green
    if [[ "$last_insert_date_seconds" -ge "$last_saturday_date_seconds" ]]; then
	    color=$color_green
    else
        color=$color_red
    fi

    html_ufdb_refresh="${html_ufdb_refresh}<td style='background-color: $color;'>$last_insert_date</td>"


done <<< "$result"

# ---------------------------------------------------------------- ufdb stock_move

html_ufdb_stock_move_refresh="<th>ufdb stock_move</th>"

# Check if ufdb stock_move as been refreshed on last sunday
result=`psql -qtAX -F, -d ufdb -c \
"SELECT oc, max(insert_date)::date AS last_insert_date
FROM ufdb.t_stock_move
GROUP BY oc
/*HAVING max(insert_date)::date >= (current_date - cast(extract(dow from current_date) as int))*/
ORDER BY oc;"`

while IFS=',' read -r oc last_insert_date
do

    last_insert_date_seconds=$(date +"%s" -d "$last_insert_date")

    if [[ "$last_insert_date_seconds" -ge "$last_saturday_date_seconds" ]]; then
        color=$color_green
    else
        color=$color_red
    fi

    html_ufdb_stock_move_refresh="${html_ufdb_stock_move_refresh}<td style='background-color: $color;'>$last_insert_date</td>"


done <<< "$result"


# ---------------------------------------------------------------- ocX-dbs

# get in last stderr if "ufload is done working" in the file

html_ocx_dbs="<th>ocX-dbs</th>"

for oc in oca ocb ocg ocp
do

    last_log_folder_name=$(ssh uf6@uf9.unifield.org "cd /home/$oc-dbs/logs/; ls -td */ | head -1")			#most recent folder name
    last_log_folder_date=$(date -d "$(echo $last_log_folder_name | sed -r 's/[-/]+/ /g')" +"%Y-%m-%d %H:%M")            #convert folder name to date
    last_log_folder_date_seconds=$(date -d "$last_log_folder_date" +"%s")						#convert date in seconds
    comment_ocx_dbs=$(ssh uf6@uf9.unifield.org "grep 'ufload is done working' /home/$oc-dbs/logs/$last_log_folder_name/stderr.txt") #execute grep and get exit code

    color=$color_red
    if [ -n "$comment_ocx_dbs" ] && [ "$last_log_folder_date_seconds" -ge "$last_sunday_date_seconds" ]; then 
        color=$color_green;
    elif  [ -z "$comment_ocx_dbs" ]; then
        comment_ocx_dbs="(not terminated)"
    fi

    html_ocx_dbs="${html_ocx_dbs}<td style='background-color: $color;'>$last_log_folder_date</font><br />$comment_ocx_dbs</td>"

done

# ---------------------------------------------------------------- ocX-uf-dbs

html_ocxuf_dbs="<th>ocX-uf-dbs</th>"

for oc in oca ocb ocg ocp
do

        instances=$(ssh uf6@uf9.unifield.org "psql -qtAX -F, -d postgres -c \"SELECT array_to_string(array_agg( prod.datname), '<br />') 
FROM pg_database prod 
LEFT JOIN pg_database ocxuf ON RIGHT(ocxuf.datname, LENGTH(ocxuf.datname) - 7) = RIGHT(prod.datname, LENGTH(prod.datname) - 5) AND ocxuf.datname LIKE 'oc_-uf\_%' 
WHERE prod.datistemplate = false 
AND prod.datname LIKE 'prod\_%' 
AND prod.datname NOT LIKE '%SYNC_SERVER%' 
AND prod.datname NOT LIKE 'prod\_CM_COO1_MALI_%' 
AND ocxuf.datname IS NULL 
AND prod.datname LIKE 'prod\_%${oc^^}%'
GROUP BY CASE WHEN prod.datname LIKE 'prod\_%\_OCA%' THEN 'OCA' 
              WHEN prod.datname LIKE 'prod\_OCB%' THEN 'OCB' 
              WHEN prod.datname LIKE 'prod\_OCG\_%' THEN 'OCG' 
              WHEN prod.datname LIKE 'prod\_OCP\_%' THEN 'OCP' END 
ORDER BY 1\"")

        color=$color_red
        if [ -z "$instances" ]; then
            color=$color_green;
        fi

    html_ocxuf_dbs="${html_ocxuf_dbs}<td style='background-color: $color;'>$instances</font></td>"

done


# ---------------------------------------------------------------- production-dbs

# get in last stderr if "ufload is done working" in the file

html_prod_dbs="<th>prod-dbs</th>"

for oc in oca ocb ocg ocp
do
    last_log_file_name=$(ssh uf6@uf9.unifield.org "cd /home/production-dbs/logs/; ls -td *-$oc | head -1")               #most recent file name
    last_log_file_date=$(date -d "$(echo $last_log_file_name | sed -r 's/[-/]+/ /g' | head -c-4)" +"%Y-%m-%d %H:%M")      #convert file name to date
    last_log_file_date_seconds=$(date -d "$last_log_file_date" +"%s")                                                     #convert date in seconds
    comment_production_dbs=$(ssh uf6@uf9.unifield.org "grep 'ufload is done working' /home/production-dbs/logs/$last_log_file_name") #execute grep and get exit code

    color=$color_red
    if [ -n "$comment_production_dbs" ] && [ "$last_log_file_date_seconds" -ge "$yesterday_date_seconds" ]; then
        color=$color_green;
    elif  [ -z "$comment_production_dbs" ]; then
        comment_production_dbs="(not terminated)"
    fi

    html_prod_dbs="${html_prod_dbs}<td style='background-color: $color;'>$last_log_file_date</font><br />$comment_production_dbs</td>"
done


# ---------------------------------------------------------------- send email

mail -s "Daily Alerts UF9" -a 'Content-Type: text/html; charset=UTF-8' jfb@tempo-consulting.fr <<< \
"<table style='border: 1px solid black; padding: 5px;'>
    <tr>
        <th style='width: 200px;'></th><th style='width: 200px;'>OCA</th><th style='width: 200px;'>OCB</th><th style='width: 200px;'>OCG</th><th style='width: 200px;'>OCP</th>
    </tr>
    <tr>$html_ufdb_refresh</tr>
    <tr>$html_ufdb_stock_move_refresh</tr>
    <tr>$html_ocx_dbs</tr>
    <tr>$html_ocxuf_dbs</tr>
    <tr>$html_ocg_db</tr>
    <tr>$html_prod_dbs</tr>
</table>
"

