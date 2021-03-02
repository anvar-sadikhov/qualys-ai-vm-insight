import xmltodict
import json

with open("temp/vulnkb.xml", "r") as xml_file:
    xml_data = xmltodict.parse(xml_file.read())
    xml_file.close()
    json_data = json.dumps(xml_data)

with open("temp/vuln.json", "w") as json_file:
    json_file.write(json_data)
    json_file.close()

data = []

with open("temp/vuln.json", "r") as f:
    json_file = json.load(f)
    vuln = json_file['KNOWLEDGE_BASE_VULN_LIST_OUTPUT']['RESPONSE']['VULN_LIST']['VULN']

    for objects in vuln:

        data.append([
            objects['QID'],
            objects['TITLE'],
            objects['CATEGORY'],
            objects['SEVERITY_LEVEL']
        ])

data.insert(0, ['QID_KB', 'Vulnerability', 'Category', 'SeverityLevel'])

print('\n'.join(','.join('"{}"'.format(e) for e in d) for d in data))