"""
Script created by RSG @ali.etezady August 2024

This script is used to update the input file names to ActivitySim in settings.yaml and network_los.yaml based on the input file names provided by the user in the transcad addin.

"""

from ruamel.yaml import YAML
import sys
 
hh_name = sys.argv[1]
person_name = sys.argv[2]
landuse_name = sys.argv[3]
 
settings_dir = '../configs/settings.yaml'
settings_mp_dir = '../configs_mp/settings_mp.yaml'
network_los_dir = '../configs/network_los.yaml'
 
yaml = YAML(typ='rt')
#update settings.yaml
with open(settings_dir, 'r') as f:
    doc = yaml.load(f)
 
for i in range(len(doc['input_table_list'])):
    if doc['input_table_list'][i]['tablename'] == 'households':
        doc['input_table_list'][i]['filename'] = hh_name
 
    elif doc['input_table_list'][i]['tablename'] == 'persons':
        doc['input_table_list'][i]['filename'] = person_name
 
    elif doc['input_table_list'][i]['tablename'] == 'land_use':
        doc['input_table_list'][i]['filename'] = landuse_name
 
with open(settings_dir, 'w') as f:
    yaml.dump(doc, f)