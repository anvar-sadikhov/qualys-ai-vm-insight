# Qulays-Jira Insight Integration 

## Qualys-Jira Server Files Structure

```bash

/opt/qualys                   #Operational folder


├── auth.conf                 #Authorization parameters. Contain Login/Password/REGION_URL


├── content                   #Temorary folder for Asset Inventory's JSON files.
│   ├── content**.json
│   ├── content1.json


├── logs                      #Contains logs. overwritten every time a new download occurs


├── output                    #Contains finally exported files for Jira-Insight importing
│   ├── assets.csv            #Asset Inventory Insight Import file
│   ├── cve.csv               #Vulnerabilities CVE list Insight Import file
│   ├── vm.csv                #VM Detection Insight Import file
│   └── vulnkb.csv            #Vulnerabilities Knowledge Base Insight Import file


├── qualys-ai.sh              #Generating files for Qualys Asset Inventory integration


├── qualys-kb.sh              #Generating files for Qualys Knowledge Base import and CVE list integration


├── qualys-vm.sh              #Generating files for Qualys Vulnerabilities integration


├── temp                      #Contains temporary files for next file exporting                                                              
│   ├── count.json
│   ├── vm-temp.csv
│   ├── vuln.json
│   └── vulnkb.xml


├── xmldict.py                              #Converts downloaded Knowledge Base XML file to CSV 

├── knowledge_base_vuln_list_output.dtd     #Formatting Knowledge Base structure for XSLT preprocessor

├── vuln2csv.xsl                            #XSLT structure for formatting xml CVE list from Knowledge Base in csv



└── xmltodict                 #Python PIP library. Contains files for XML to CSV

```

## Crontab

```bash

0 1 * * * timeout 50m /opt/qualys/qualys-ai.sh &> /opt/qualys/logs/qualys-ai.log   #Executes qualys-ai.sh at 01:00am and builds log
0 2 * * * timeout 50m /opt/qualys/qualys-kb.sh &> /opt/qualys/logs/qualys-kb.log   #Executes qualys-kb.sh at 02:00am and builds log
0 3 * * * timeout 50m /opt/qualys/qualys-vm.sh &> /opt/qualys/logs/qualys-vm.log   #Executes qualys-vm.sh at 03:00am and builds log

#Forced termination after 50m of inactivity to avoid infinity loops
```

## ~/.bashrc

```bash
export PYTHONPATH=$PYTHONPATH:/opt/qualys/xmltodict/
export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.6/site-packages

#Also /opt/qualys/xmltodict needs to be copied to /usr/local/lib/python3.6/site-packages
```

## Qualys Authentication Configuration
__auth.conf__ - Needed for authorization in the APIs, obtaining an authorization token, downloading and exporting assets, vulnerabilities and the knowledge base. When credentials change needs to reconfigure file with new credentials. 

```bash
auth.conf

LOGIN           PASSWORD      REGION_URL       
```

__REGION_URL__ -  (https://www.qualys.com/platform-identification/)

```bash
US1	qg1.apps.qualys.com
US2	qg2.apps.qualys.com
US3	qg3.apps.qualys.com
EU1	qg1.apps.qualys.eu
EU2	qg2.apps.qualys.eu
IN1	qg1.apps.qualys.in
CA1	qg1.apps.qualys.ca
AE1	qg1.apps.qualys.ae
```

## Qualys - Asset Inventory 

__qualys-ai.sh__ - Generates Authorization Token in a variable by using credentials from auth.conf and builds session. Downloading assets in JSON format to /opt/qualys/content directory. Each file is limited by API with 100 assets only. Number of files calculates by script automatically and generate files one by one with lastSeenAssetId parameter.

>After all JSON files generated and downloaded in /opt/qualys/content program generates assets.csv file for Jira-Insight importing in /opt/qualys/output folder.



+ Output file in /opt/qualys/output: assets.csv 

>Contains: 'AssetID', 'AssetUUID', 'Address', 'AssetName', 'NetBiosName', 'LastLoggedOnUser', 'BiosSerialNumber', 'BiosAssetTag', 'OperatingSystem', 'OS Category', 'OS SubCategory', 'Hardware', 'Hardware Category', 'Hardware SubCategory', 'LastModifiedDate', 'CreatedDate'.


## Qualys - Vulnerability Management
__qualys-vm.sh__ - Generates VM Detection csv file and format it to Jira-Insight Import.

+ Output file in /opt/qualys/output: vm.csv

>Contains: 'Host ID', 'QG HostID' and 'QIDs'.



## Qualys - Knowledge Base
__qualys-kb.sh__ - Generates Vulnerabilities Knowledge Base in XML file format. Then exports to proper CSV format for Jira-Insight Import.

+ Output files in /opt/qualys/output: vulnkb.csv, cve.csv

__vulnkb.csv__ contains: QID, Vulnerability title, Category, Severity Level.

__cve.csv__ contains: QID, CVE_ID(If exists in knowledge base).



__xmldict.py__ - Runs by qualys-kb.sh. Converts downloaded Knowledge Base temp/vulnkb.xml to output/vulnkb.csv.

>Using xmltodict library. Also needs to be copied in /usr/local/lib/python3.6/site-packages and add path to ~/.bashrc



__vuln2csv.xsl__ - XSLT format generator. Generates cve.csv

>Using knowledge_base_vuln_list_output.dtd structure file

## Insight NVD Integration


__Insight CVE Integration__ imports data from NIST (National Vulnerability Database) and all the collected data is automatically imported into the Insight CMDB and is available in Jira. It will import information like:

+ Vulnerability
+ Metric
+ Products & Versions
+ Vendors
+ etc..

To run Insight CVE Integration you need to have a license for Jira Insight.

(https://marketplace.atlassian.com/apps/1220353/insight-nvd-integration?hosting=server&tab=overview)



## System Requirements for importing most objects from CVE base.

There are more than 300000 objects when downloads all CVE bases by years. 

(https://documentation.mindville.com/insight/5.4/system-requirements)

```bash
~10000	    4Gb
~100000	    8Gb
~500000	    16Gb
~1000000    32Gb
~2000000    64Gb
```