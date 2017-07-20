#!/bin/sh

cd /home/djg/jasper/

echo "Send unifield_deployments.pdf"
python send_file_to_sharepoint.py -s /var/jasper-server/unifield_deployments.pdf -d /sites/msfintlcommunities/Unifield/uf_doc/Reports -n unifield_deployments.pdf

