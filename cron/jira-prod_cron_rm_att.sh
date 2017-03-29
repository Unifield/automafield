#!/bin/bash

jira=jira.unifield.org
user=
pw=

if [ -z "$pw" ]; then
	echo "Set password, please."
	exit 1
fi

mkdir -p /var/atlassian/jira-prod/data/attachments-rm/US/10000

psql -d jira_prod -c "\copy (
      SELECT fa.id, pr.pkey || '-' || ji.issuenum, fa.filename FROM fileattachment fa
      INNER JOIN jiraissue ji ON ji.id=fa.issueid
      INNER JOIN project pr ON pr.id=ji.project
      INNER JOIN issuestatus it ON it.id=ji.issuestatus
      WHERE fa.filename LIKE '%.dump' 
      AND it.pname IN ('Rejected','Fixed','Data Fixed','Released')
      AND ji.updated < (CURRENT_DATE - INTERVAL '7 day')
      ) to STDOUT with CSV DELIMITER '/' " | head -1 |\
while read line
do
        id=`echo "$line"      | cut -d/ -f1`
        ticket=`echo "$line"  | cut -d/ -f2`
        name=`echo "$line"    | cut -d/ -f3`
        # then use them...
        echo id $id ticket $ticket name $name 
        
        cp -r /var/atlassian/jira-prod/data/attachments/US/10000/$ticket /var/atlassian/jira-prod/data/attachments-rm/US/10000/$ticket && \
        curl -u $user:$pw -X DELETE https://$jira/rest/api/2/attachment/$id && \
        curl -u $user:$pw -X POST --data "{ \"body\": \"Attachment $name deleted.\" }" -H "Content-Type: application/json" https://$jira/rest/api/2/issue/$ticket/comment

done


