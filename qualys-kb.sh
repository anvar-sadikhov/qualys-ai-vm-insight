#! /bin/bash

# cd /opt/qualys     # Uncomment before add to server and crontab

echo "Vulnerability Knowledge Base Generation Started at:" "$(date)"

function export_xml() {
  USERNAME=$(cat auth.conf | awk '{print $1}')
  PASSWORD=$(cat auth.conf | awk '{print $2}')
  REGION_URL=$(cat auth.conf | awk '{print $3}')

  curl -n -H 'X-Requested-With: curl' -u ${USERNAME}:${PASSWORD} 'https://qualysapi.'"${REGION_URL}"'/api/2.0/fo/knowledge_base/vuln/?action=list&details=All'
} 

export_xml >temp/vulnkb.xml

export_csv=$(python3 xmldict.py)

echo "${export_csv}" >output/vulnkb.csv

xsltproc --maxdepth 5000 --path . vuln2csv.xsl		temp/vulnkb.xml >output/cve.csv

echo "Vulnerability Knowledge Base Generation Finished at:" "$(date)"