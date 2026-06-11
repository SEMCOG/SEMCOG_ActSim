# ActivitySim
# Copyright (C) 2016 RSG Inc
# See full license in LICENSE.txt.
# run from the mtc tm1 skims folder

import os, sys

import pandas as pd
import openmatrix as omx


def read_manifest(manifest_file_name):

    column_map = {
        'Token': 'skim_key1',
        'TimePeriod': 'skim_key2',
        'File': 'source_file_name',
        'Matrix': 'source_key',
    }
    converters = {
        col: str for col in column_map.keys()
    }

    manifest = pd.read_csv(manifest_file_name, header=0, comment='#', converters=converters)

    manifest.rename(columns=column_map, inplace=True)

    return manifest


def omx_getMatrix(omx_file_name, omx_key):

    with omx.open_file(omx_file_name, 'r') as omx_file:

        if omx_key not in omx_file.list_matrices():
            print ("Source matrix with key '%s' not found in file '%s" % (omx_key, omx_file,))
            print (omx_file.list_matrices())
            raise RuntimeError("Source matrix with key '%s' not found in file '%s"
                               % (omx_key, omx_file,))

        data = omx_file[omx_key]

    return data


manifest_dir = sys.argv[1]
source_data_dir = sys.argv[2]
dest_data_dir = sys.argv[2]

manifest_file_name = os.path.join(manifest_dir, 'skim_manifest.csv')
dest_file_name = os.path.join(dest_data_dir, 'skims.omx')
print(dest_data_dir)
with omx.open_file(dest_file_name, 'w') as dest_omx:

    manifest = read_manifest(manifest_file_name)

    for row in manifest.itertuples(index=True):

        source_file_name = os.path.join(source_data_dir, row.source_file_name)

        if row.skim_key2:
            dest_key = row.skim_key1 + '__' + row.skim_key2
        else:
            dest_key = row.skim_key1

        print ("Reading '%s' from '%s' in %s" % (dest_key, row.source_key, source_file_name))
        with omx.open_file(source_file_name, 'r') as source_omx:

            if row.source_key not in source_omx.list_matrices():
                print ("Source matrix with key '%s' not found in file '%s" \
                      % (row.source_key, source_file_name,))
                print (source_omx.list_matrices())
                raise RuntimeError("Source matrix with key '%s' not found in file '%s"
                                   % (row.source_key, dest_omx,))

            data = source_omx[row.source_key]
            zoneid = source_omx.mapping('ZoneID')
            zones = list(zoneid.keys())
            zones_sorted = sorted(list(zoneid.keys()))
            pos = [zones.index(zone) for zone in zones_sorted]
            data = data[:][pos,:][:,pos]
            
            if dest_key in dest_omx.list_matrices():
                print ("deleting existing dest key '%s'" % (dest_key,))
                dest_omx.removeNode(dest_omx.root.data, dest_key)

            dest_omx[dest_key] = data
            
    dest_omx.create_mapping('ZoneID', sorted(list(zoneid.keys())))