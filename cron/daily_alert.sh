#!/bin/sh

last_sunday_date_seconds=$(date +"%s" -d "last sunday")
color_green="#b7edb4"
color_red="#edbfb4"

# ---------------------------------------------------------------- ufdb

html_ufdb_refresh="<th>ufdb</th>"

# Check if ufdb has been refreshed on last sunday by getting the last inserted PO per OC
result=`psql -qtAX -F, -d ufdb -c \
"SELECT oc, max(insert_date)::date AS last_insert_date
FROM ufdb.t_purchase_order
GROUP BY oc
HAVING max(insert_date)::date <> (current_date - cast(extract(dow from current_date) as int))
ORDER BY oc;"`

while IFS=',' read -r oc last_insert_date
do

    last_insert_date_seconds=$(date +"%s" -d "$last_insert_date")

    if [[ "$last_insert_date_seconds" -ge "$last_sunday_date_seconds" ]]; then
        color=$color_green
    else
        color=$color_red
    fi

    html_ufdb_refresh="${html_ufdb_refresh}<td style='background-color: $color;'>$last_insert_date</td>"


done <<< "$result"

# ---------------------------------------------------------------- ocX-dbs

# get in last stderr if "ufload is done working" in the file

html_ocx_dbs="<th>ocX-dbs</th>"

for oc in oca ocb ocg ocp
do

    last_log_folder_name=$(ssh root@uf7.unifield.org "cd /home/$oc-dbs/logs/; ls -td */ | head -1")			#most recent folder name
    last_log_folder_date=$(date -d "$(echo $last_log_folder_name | sed -r 's/[-/]+/ /g')" +"%Y-%m-%d %H:%M")            #convert folder name to date
    last_log_folder_date_seconds=$(date -d "$last_log_folder_date" +"%s")						#convert date in seconds
    comment=$(ssh root@uf7.unifield.org "grep 'ufload is done working :)' /home/$oc-dbs/logs/$last_log_folder_name/stderr.txt") #execute grep and get exit code
    ufload_done=$(ssh root@uf7.unifield.org "echo $?")									#code 0 means OK

    color=$color_red
    if [ $ufload_done -eq 0 ] && [ "$last_log_folder_date_seconds" -ge "$last_sunday_date_seconds" ]; then 
        color=$color_green;
    elif  [ $ufload_done -ne 0 ]; then
        comment="(not terminated)"
    fi

    html_ocx_dbs="${html_ocx_dbs}<td style='background-color: $color;'>$last_log_folder_date</font><br />$comment</td>"

done

# ---------------------------------------------------------------- production-dbs

# get in last stderr if "ufload is done working" in the file

html_prod_dbs="<th>prod-dbs</th>"

for oc in oca ocb ocg ocp
do

    last_log_file_name=$(ssh root@uf7.unifield.org "cd /home/production-dbs/logs/; ls -td *-$oc | head -1")               #most recent file name
    last_log_file_date=$(date -d "$(echo $last_log_file_name | sed -r 's/[-/]+/ /g' | head -c-4)" +"%Y-%m-%d %H:%M")      #convert file name to date
    last_log_file_date_seconds=$(date -d "$last_log_file_date" +"%s")                                                     #convert date in seconds
    comment=$(ssh root@uf7.unifield.org "grep 'ufload is done working :)' /home/production-dbs/logs/$last_log_file_name") #execute grep and get exit code
    ufload_done=$(ssh root@uf7.unifield.org "echo $?")                                                                    #code 0 means OK

    color=$color_red
    if [ $ufload_done -eq 0 ] && [ "$last_log_file_date_seconds" -ge "$last_sunday_date_seconds" ]; then
        color=$color_green;
    elif  [ $ufload_done -ne 0 ]; then
        comment="(not terminated)"
    fi

    html_prod_dbs="${html_prod_dbs}<td style='background-color: $color;'>$last_log_file_date</font><br />$comment</td>"

done


# ---------------------------------------------------------------- send email

mail -s "Daily Alerts" -a 'Content-Type: text/html; charset=UTF-8' dan.joguet-laurent@geneva.msf.org <<< \
"<table style='border: 1px solid black; padding: 5px;'>
    <tr>
        <th style='width: 200px;'></th><th style='width: 200px;'>OCA</th><th style='width: 200px;'>OCB</th><th style='width: 200px;'>OCG</th><th style='width: 200px;'>OCP</th>
    </tr>
    <tr>$html_ufdb_refresh</tr>
    <tr>$html_ocx_dbs</tr>
    <tr>$html_prod_dbs</tr>
</table>
"

