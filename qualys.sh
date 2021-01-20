#!/bin/bash

# cd /opt/qualys

timeStart=$(date)
echo "Started at:" "$timeStart"

### Function for defining Qualys Authentication API to get the JWT Token as a Variable

function auth_func() {
  uName=$(cat auth | awk '{print $1}')
  pWord=$(cat auth | awk '{print $2}')

  auth_token=$(curl -X POST 'https://gateway.qg2.apps.qualys.eu/auth' -d 'username='"$uName"'&password='"$pWord"'&token=true' -H 'ContentType:application/x-www-form-urlencoded')

}

## Function for checking if JSON is correct. True/False/FileNotFoundError

function json_checker() {
  parser_message=$(echo "$jsonPath" | python3 -c "

import os
import json
from json import JSONDecodeError

try:
    a=json.load(open(input()))
    print("True")

except FileNotFoundError as e:
    print(e)

except JSONDecodeError as ex:
    print("False")

    ")
}

# Authorize to Qualys
auth_func

### Count all assets and output

rm -rf logs/count.log

count_post="curl -X POST -H 'Accept: */*' -H 'Authorization: Bearer "$auth_token"' -H 'Content-Type: application/json'  'https://gateway.qg2.apps.qualys.eu/am/v1/assets/host/count'"

eval "$count_post" >count.json

jsonPath="count.json"
json_checker

while [ "$parser_message" == "False" ]; do
  eval "$count_post" >count.json
  json_checker
  if [ "$parser_message" != "False" ]; then
    break
  fi
done

count_parse=$(echo "count.json" | python3 -c "

import os
import json

aLoad = json.load(open('count.json'))
b = int(aLoad['count'])
print(b)

")

json_files_num=$((($count_parse / 100) + (100 % 3 > 0)))

# Output count of all assets in count.log and CLI
echo "Count of all assets for ""$timeStart"" is:" "$count_parse" >logs/count.log
echo "Number of JSON files after generate:" $json_files_num >>logs/count.log
cat logs/count.log

### For generating and downloading of the First JSON file

firstFile_post="curl -X POST -H 'Accept: */*' -H 'Authorization: Bearer "$auth_token"' -H 'Content-Type: application/json'  'https://gateway.qg2.apps.qualys.eu/am/v1/assets/host/list'"

echo "1"
eval "$firstFile_post" >content/content1.json

jsonPath="content/content1.json"
json_checker

while [ "$parser_message" == "False" ]; do
  eval "$firstFile_post" >content/content1.json
  json_checker
  if [ "$parser_message" != "False" ]; then
    break
  fi
done

### Function for generating of the Next JSON file
# Check lastSeenAssetId if exists

function generate_nextJson() {
  lastId_parser=$(echo "$jsonFile" | python3 -c "

import os
import json

with open(input()) as f:

    data=f.read()
    cont_list=json.loads(data)

b = int(cont_list['lastSeenAssetId'])
print(b)

    ")

  echo "lastSeenAssetId is:" "$lastId_parser"

  if [ ! -z "$lastId_parser" ]; then

    nextFile_post="curl -X POST -H 'Accept: */*' -H 'Authorization: Bearer "$auth_token"' -H 'Content-Type: application/json'  'https://gateway.qg2.apps.qualys.eu/am/v1/assets/host/list?lastSeenAssetId="$lastId_parser"'"

  else
    echo "Request failed"
    exit
  fi
}

### Function for downloading of the Next JSON file

function download_json() {
  jsonFile="content/content$prevNum.json"
  generate_nextJson

  eval "$nextFile_post" >content/content"$num".json

  jsonPath="content/content$num.json"
  json_checker

  while [ "$parser_message" == "False" ]; do
    eval "$nextFile_post" >content/content"$num".json
    json_checker
    if [ "$parser_message" != "False" ]; then
      break
    fi
  done
}

### Generate JSON files in loop

for ((n = 2; n <= $json_files_num; n++)); do
  echo "$n"
  prevNum=$((n - 1))
  num=$n
  download_json
done

timeEnd=$(date)
echo "Finished at:" "$timeEnd"
