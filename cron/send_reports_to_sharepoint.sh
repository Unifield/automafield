#!/bin/sh

cd /home/djg/jasper/send_file_to_sharepoint/

echo "Send unifield_deployments.pdf"
python send_file_to_sharepoint.py -s /var/jasper-server/unifield_deployments.pdf -d /sites/msfintlcommunities/Unifield/uf_doc/Reports -n unifield_deployments.pdf

echo "Send instance_info.xlsx"
python send_file_to_sharepoint.py -s /var/jasper-server/instance_info.xlsx -d /sites/msfintlcommunities/Unifield/uf_doc/Reports -n instance_info.xlsx

echo "Send ufdb_documentation.pdf"
python send_file_to_sharepoint.py -s /var/jasper-server/ufdb_documentation.pdf -d /sites/msfintlcommunities/Unifield/uf_doc/BI -n ufdb_documentation.pdf

echo "Send users_groups_ocg.xlsx"
python send_file_to_sharepoint.py -s /var/jasper-server/users_groups_ocg.xlsx -d /sites/msfintlcommunities/Unifield/uf_doc/Reports -n users_groups_ocg.xlsx

echo "Send users_groups_ocb.xlsx"
python send_file_to_sharepoint.py -s /var/jasper-server/users_groups_ocb.xlsx -d /sites/msfintlcommunities/Unifield/uf_doc/Reports -n users_groups_ocb.xlsx

echo "Send users_groups_oca.xlsx"
python send_file_to_sharepoint.py -s /var/jasper-server/users_groups_oca.xlsx -d /sites/msfintlcommunities/Unifield/uf_doc/Reports -n users_groups_oca.xlsx
