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
  parser_message=$(echo "$json_path" | python3 -c "
import os, json
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

### Count all assets and output

rm -rf logs/count.log

count_post="curl -X POST -H 'Accept: */*' -H 'Authorization: Bearer "$auth_token"' -H 'Content-Type: application/json'  'https://gateway.qg2.apps.qualys.eu/am/v1/assets/host/count'"

eval "$count_post" >count.json

json_path="count.json"
json_checker

while [ "$parser_message" == "False" ]; do
  eval "$count_post" >count.json
  json_checker
  if [ "$parser_message" != "False" ]; then
    break
  fi
done

count_parse=$(echo "count.json" | python3 -c "
import os, json

data = json.load(open('count.json'))
num = int(data['count'])

print(num)
    ")

json_nums=$((($count_parse / 100) + (100 % 3 > 0)))

# Output count of all assets in count.log and CLI
echo "Count of all assets for ""$timeStart"" is:" "$count_parse" >logs/count.log
echo "Number of JSON files after generate:" $json_nums >>logs/count.log
cat logs/count.log

### For generating and downloading of the First JSON file

firstFile_post="curl -X POST -H 'Accept: */*' -H 'Authorization: Bearer "$auth_token"' -H 'Content-Type: application/json'  'https://gateway.qg2.apps.qualys.eu/am/v1/assets/host/list'"

echo "1"
eval "$firstFile_post" >content/content1.json

json_path="content/content1.json"
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
  lastId_parser=$(echo "$json_file" | python3 -c "
import os, json

with open(input()) as f:

    data=f.read()
    cont_list=json.loads(data)

last_id = int(cont_list['lastSeenAssetId'])
print(last_id)
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
  json_file="content/content$prevNum.json"
  generate_nextJson

  eval "$nextFile_post" >content/content"$num".json

  json_path="content/content$num.json"
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

for ((n = 2; n <= $json_nums; n++)); do
  echo "$n"
  prevNum=$((n - 1))
  num=$n
  download_json
done

timeEnd=$(date)
echo "Finished at:" "$timeEnd"