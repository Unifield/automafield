#!/bin/bash
. $HOME/automafield/script.sh


for i in $1
do
    echo " $i "

    for instance in $(pct_all_instances $i)
    do  
        echo $instance
        printf    "%-20s | %-20s | %-20s | %-20s\n"  User_name User_login User_email Last_user_connection
       pct $i $instance -c "select name, login, email, date from res_users" -t; 

    done

done

        


