#! /bin/bash

#cd /opt/qualys     # Uncomment before add to server and crontab

echo "Asset Inventory JSON Generation Started at:" "$(date)"

### Function for defining Qualys Authentication API to get the JWT Token as a Variable

function auth_func() {
  USERNAME=$(cat auth.conf | awk '{print $1}')
  PASSWORD=$(cat auth.conf | awk '{print $2}')
  REGION_URL=$(cat auth.conf | awk '{print $3}')

  auth_token=$(curl -X POST 'https://gateway.'"${REGION_URL}"'/auth' -d 'username='"${USERNAME}"'&password='"${PASSWORD}"'&token=true' -H 'ContentType:application/x-www-form-urlencoded')
}

## Function for checking if JSON is correct. True/False/FileNotFoundError

function json_checker() {
  parser_message=$(echo "${json_path}" | python3 -c "
import json
from json import JSONDecodeError

try:
    json.load(open(input()))
    print("True")

except FileNotFoundError as e:
    print(e)

except JSONDecodeError as ex:
    print("False")
    ")
}

# Authorize to Qualys
auth_func

### Remove old files and logs

rm -rf content/*
rm -rf output/*
rm -rf logs/count.log
rm -rf temp/*

### Count all assets and output

count_post="curl -X POST -H 'Accept: */*' -H 'Authorization: Bearer "${auth_token}"' -H 'Content-Type: application/json'  'https://gateway."${REGION_URL}"/rest/2.0/count/am/asset'"

eval "${count_post}" >temp/count.json

json_path="temp/count.json"
json_checker

while [ "${parser_message}" == "False" ]; do
  eval "${count_post}" >temp/count.json
  json_checker
  if [ "${parser_message}" != "False" ]; then
    break
  fi
done

count_parse=$(echo "temp/count.json" | python3 -c "
import json

data = json.load(open('temp/count.json'))
num = int(data['count'])

print(num)
    ")

json_nums=$(((${count_parse} / 100) + (100 % 3 > 0)))

time_start=$(date)

# Output count of all assets in count.log and CLI
echo "Count of all assets for ""${time_start}"" is:" "${count_parse}" >logs/count.log
echo "Number of JSON files after generate:" ${json_nums} >>logs/count.log
cat logs/count.log

### For generating and downloading of the First JSON file

firstFile_post="curl -X POST -H 'Accept: */*' -H 'Authorization: Bearer "${auth_token}"' -H 'Content-Type: application/json'  'https://gateway."${REGION_URL}"/rest/2.0/search/am/asset'"

echo "1"
eval "${firstFile_post}" >content/content1.json

json_path="content/content1.json"
json_checker

while [ "${parser_message}" == "False" ]; do
  eval "${firstFile_post}" >content/content1.json
  json_checker
  if [ "${parser_message}" != "False" ]; then
    break
  fi
done

### Function for generating of the Next JSON file

function has_more {
  has_more_message=$(echo "${last_json}" | python3 -c "
import json

with open(input()) as f:
    data=f.read()
    cont_list=json.loads(data)

if((int(cont_list['hasMore'])) > 0):
    print('HasMore')
else:
    print('No more files to download')
   ")
  echo "${has_more_message}" 
}

function generate_nextJson() {
  lastId_parser=$(echo "${json_file}" | python3 -c "
import json

with open(input()) as f:
    data=f.read()
    cont_list=json.loads(data)

last_id = int(cont_list['lastSeenAssetId'])
print(last_id)
    ")

  echo "lastSeenAssetId is:" "${lastId_parser}"

  if [ ! -z "${lastId_parser}" ]; then
    nextFile_post="curl -X POST -H 'Accept: */*' -H 'Authorization: Bearer "${auth_token}"' -H 'Content-Type: application/json'  'https://gateway."${REGION_URL}"/rest/2.0/search/am/asset?lastSeenAssetId="${lastId_parser}"'"
  else
    echo "Request failed"
    exit
  fi
}

### Function for downloading of the Next JSON file

function download_json() {
  json_file="content/content${prevNum}.json"
  generate_nextJson

  eval "${nextFile_post}" >content/content"${num}".json

  json_path="content/content${num}.json"
  json_checker

  while [ "${parser_message}" == "False" ]; do
    eval "$nextFile_post" >content/content"${num}".json
    json_checker
    if [ "${parser_message}" != "False" ]; then
      break
    fi
  done
}

function export_csv() {
  csv_file=$(python3 -c "
import json, glob

files=glob.glob('content/*', recursive=True)

data = []

for single_file in files:
    with open(single_file, 'r') as f:
        json_file=json.load(f)
        asset=json_file['assetListData']['asset']

        for objects in asset:
            data.append([                
                objects['assetId'],
                objects['assetUUID'],
                objects['address'],
                objects['assetName'],
                objects['netbiosName'],
                objects['lastLoggedOnUser'],
                objects['biosSerialNumber'],
                objects['biosAssetTag'],
                objects['operatingSystem']['fullName'],
                objects['operatingSystem']['category1'],
                objects['operatingSystem']['category2'],
                objects['hardware']['fullName'],
                objects['hardware']['category1'],
                objects['hardware']['category2'],
                objects['lastModifiedDate'],
                objects['createdDate']
            ])

data.insert(0, ['AssetID', 'AssetUUID', 'Address', 'AssetName', 'NetBiosName', 'LastLoggedOnUser', 'BiosSerialNumber', 'BiosAssetTag', 'OperatingSystem', 'OS Category', 'OS SubCategory', 'Hardware', 'Hardware Category', 'Hardware SubCategory', 'LastModifiedDate', 'CreatedDate'])

print('\n'.join(','.join('"{}"'.format(e) for e in d) for d in data))
  ")

  echo "${csv_file}" >output/assets.csv
}

### Generate JSON files in loop

for ((n = 2; n <= ${json_nums}; n++)); do
  echo "${n}"
  prevNum=$((n - 1))
  num=${n}
  download_json
  last_json="content/content${json_nums}.json"
  has_more
  if [ "${has_more_message}" == "HasMore" ]; then
    json_nums=$((json_nums + 1))
  fi
done

echo "Asset Inventory JSON Generation Finished at:" "$(date)"

echo "Asset Inventory JSON Exporting to CSV Started at:" "$(date)"

export_csv

echo "Asset Inventory JSON Exporting to CSV Finished at:" "$(date)"