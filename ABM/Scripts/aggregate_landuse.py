# %%
import pandas as pd
import numpy as np
import sys
import geopandas as gpd
import os
_join = os.path.join

# %%
land_use_dir = sys.argv[1]
land_use_dir = land_use_dir.replace('\\', '/')
lu_output = sys.argv[2]
output_dir = sys.argv[3]

lu_maz = pd.read_csv(land_use_dir, low_memory=False)
taz_file = gpd.read_file(_join(output_dir, 'WorkingFiles/SEMCOG_TAZ.shp'))

# %%
taz_count = len(taz_file)
first_ext_station_id = taz_file[taz_file.EXTERNAL == 1].ID.min()

# %%
lu_taz = lu_maz[['taz_id', 'tot_acres', 'tot_hhs', 'hhs_pop', 'grppop',
       'tot_pop', 'enrollment_k_8', 'enrollment_9_12', 'e01_nrm', 'e02_constr', 'e03_manuf',
       'e04_whole', 'e05_retail', 'e06_trans', 'e07_utility', 'e08_infor',
       'e09_finan', 'e10_pstsvc', 'e11_compmgt', 'e12_admsvc', 'e13_edusvc',
       'e14_medfac', 'e15_hospit', 'e16_leisure', 'e17_othsvc', 'e18_pubadm',
       'tot_emp', 'univ_enrollment', 'External']].groupby('taz_id').sum().reset_index()

lu_taz.rename(columns={'taz_id':'zoneid'}, inplace=True)
lu_taz['ZONE'] = lu_taz['zoneid']

#add areatype and county variable
lu_taz_ = lu_maz[['taz_id', 'area_type', 'county']].groupby('taz_id').first().reset_index()
lu_taz = pd.merge(lu_taz, lu_taz_, left_on='zoneid', right_on='taz_id')
lu_taz = lu_taz.drop(columns=['taz_id'])

lu_taz.rename(columns={'area_type':'AreaType', 'county':'COUNTY'}, inplace=True)

lu_taz.to_csv(lu_output, index=False)