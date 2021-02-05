#!/bin/bash

# cd /opt/qualys     # Uncomment before add to server and crontab

echo "Vulnerability Management CSV Download Finished at:" "$(date)"

function auth_func() {
  uName=$(cat auth.txt | awk '{print $1}')
  pWord=$(cat auth.txt | awk '{print $2}')
  region_url=$(cat auth.txt | awk '{print $3}')  
}

auth_func

vm_post="curl -H 'X-Requested-With: Curl Sample' -u '"$uName':'$pWord"' 'https://qualysapi."$region_url"/api/2.0/fo/asset/host/vm/detection/?action=list&output_format=CSV_NO_METADATA'"

eval "$vm_post" >output/vm.csv

echo "Vulnerability Management CSV Download Finished at:" "$(date)"