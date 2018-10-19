#!/bin/sh

last_sunday_date_seconds=$(date +"%s" -d "last sunday")

# ---------------------------------------------------------------- ufdb

html_ufdb_refresh=""

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
        color="green"
    else
        color="red"
    fi

    html_ufdb_refresh="${html_ufdb_refresh}<tr><td>$oc</td><td><font color='$color'>$last_insert_date</font></td></tr>"


done <<< "$result"

# ---------------------------------------------------------------- ocX-dbs

# get in last stderr if "ufload is done working" in the file

for oc in oca ocb ocg ocp
do

    last_log_folder_name=$(ssh root@uf7.unifield.org "cd /home/$oc-dbs/logs/; ls -td */ | head -1")			#most recent folder name
    last_log_folder_date=$(date -d "$(echo $last_log_folder_name | sed -r 's/[-/]+/ /g')" +"%Y-%m-%d %H:%M")            #convert folder name to date
    last_log_folder_date_seconds=$(date -d "$last_log_folder_date" +"%s")						#convert date in seconds
    comment=$(ssh root@uf7.unifield.org "grep 'ufload is done working :)' /home/$oc-dbs/logs/$last_log_folder_name/stderr.txt") #execute grep and get exit code
    ufload_done=$(ssh root@uf7.unifield.org "echo $?")									#code 0 means OK

    color="red"
    if [ $ufload_done -eq 0 ] && [ "$last_log_folder_date_seconds" -ge "$last_sunday_date_seconds" ]; then 
        color="green";
    elif  [ $ufload_done -ne 0 ]; then
        comment="(not terminated)"
    fi

    html_ocx_dbs="${html_ocx_dbs}<tr><td>${oc^^}</td><td><font color='$color'>$last_log_folder_date</font></td><td>$comment</td></tr>"

done

# ---------------------------------------------------------------- send email

mail -s "Daily Alerts" -a 'Content-Type: text/html; charset=UTF-8' dan.joguet-laurent@geneva.msf.org <<< \
"<h1>ufdb tables</h1>
<table>$html_ufdb_refresh</table>
<h1>ocX-dbs</h1>
<table>$html_ocx_dbs</table>
</body>"

