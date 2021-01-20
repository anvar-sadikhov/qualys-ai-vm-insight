#!/bin/bash

timeStart=$(date)
echo "Started at:" "$timeStart"

count_parse=$(echo "count.json" | python3 -c "
import os, json

data = json.load(open('count.json'))
num = int(data['count'])

print(num)
")

json_nums=$((($count_parse / 100) + (100 % 3 > 0)))

# Output count of all assets in CLI
echo "Count of all assets for ""$timeStart"" is:" "$count_parse"
echo "Number of JSON files after generate:" $json_nums

function json_formatting() {
    jq -s 'def deepmerge(a;b):
  reduce b[] as $item (a;
    reduce ($item | keys_unsorted[]) as $key (.;
      $item[$key] as $val | ($val | type) as $type | .[$key] = if ($type == "object") then
        deepmerge({}; [if .[$key] == null then {} else .[$key] end, $val])
      elif ($type == "array") then
        (.[$key] + $val | unique)
      else
        $val
      end)
    );
  deepmerge({}; .)' content/content$num.json > output/content.json
  
  echo "Done"
}

for ((n = 1; n <= $json_nums; n++)); do
    echo "$n"
    num=$n
    json_formatting
    sleep 1m
done

timeEnd=$(date)
echo "Finished at:" "$timeEnd"