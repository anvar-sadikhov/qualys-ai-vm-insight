import os
import json
import csv

def get_list_of_json_files():
    list_of_files = os.listdir('content/')
    return list_of_files


print(get_list_of_json_files)