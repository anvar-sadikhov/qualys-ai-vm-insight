#! /bin/bash

# cd /opt/qualys     # Uncomment before add to server and crontab

echo "Vulnerability Management CSV Download Finished at:" "$(date)"

function auth_func() {
  USERNAME=$(cat auth.conf | awk '{print $1}')
  PASSWORD=$(cat auth.conf | awk '{print $2}')
  REGION_URL=$(cat auth.conf | awk '{print $3}')
}

auth_func

vm_post="curl -H 'X-Requested-With: Curl Sample' -u '"${USERNAME}':'${PASSWORD}"' 'https://qualysapi."${REGION_URL}"/api/2.0/fo/asset/host/vm/detection/?action=list&show_results=0&output_format=CSV_NO_METADATA'"

eval "${vm_post}" >temp/vm-temp.csv

cut --complement -f 2-9,11-16,18-36 -d, temp/vm-temp.csv >output/vm.csv

echo "Vulnerability Management CSV Download Finished at:" "$(date)"