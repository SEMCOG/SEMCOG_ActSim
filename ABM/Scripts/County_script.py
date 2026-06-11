"""
Script created by RSG @ali.etezady May 2022

This script is used to create a matrix (similar to skims) with zones as the row and column index. The values in the matrix are the county (district) id for each zone. This matrix is used workplace location model calibration constants.

"""

# %%
import pandas as pd, numpy as np, openmatrix as omx, os
_join = os.path.join
# %%
input_dir = os.sys.argv[1]
output_dir = os.sys.argv[2]

land_use_taz = _join(output_dir, 'WorkingFiles/land_use_taz.csv')
skims_dir =  _join(output_dir,'skims')

land_use = pd.read_csv(land_use_taz)
land_use = land_use.set_index('ZONE')

rows = np.arange(1,len(land_use) + 1)
cols = np.arange(1,len(land_use) + 1)

data = np.empty([len(rows),len(rows)])

for i in range(len(rows)):
    data[:,i] = np.transpose(np.repeat(land_use.loc[i+1, 'COUNTY'], len(rows)))

skims = omx.open_file(_join(skims_dir,'COUNTY.omx'), 'w')
skims['COUNTY'] = data
skims.create_mapping('ZoneID', sorted(rows))
skims.close()