# %%
import pandas as pd
import sys
import os
import geopandas as gpd
_join = os.path.join


# %%
land_use_dir = sys.argv[1]
other_zonal_data_dir = sys.argv[2]
merged_landuse_output_dir = sys.argv[3]
output_dir = sys.argv[4]

land_use = pd.read_csv(land_use_dir, low_memory=False)
other_zonal_data = pd.read_csv(other_zonal_data_dir, low_memory=False)
taz_file = gpd.read_file(_join(output_dir, 'WorkingFiles/SEMCOG_TAZ.shp'))
taz_count = len(taz_file)

# %%
#check to see if columns in other_zonal_data are not in land_use
other_zonal_data_cols = other_zonal_data.columns
land_use_cols = land_use.columns

for col in other_zonal_data_cols:
    if (col in land_use_cols) & (col != 'maz_id'):
        land_use.drop(columns=[col], inplace=True)

land_use_merged = pd.merge(land_use, other_zonal_data, on='maz_id')

# add external stations to land use data
start_taz_id = land_use_merged.taz_id.max() + 1
start_maz_id = land_use_merged.maz_id.max() + 1

externals_to_append = [{'taz_id': start_taz_id + i, 'maz_id': start_maz_id + i}
                  for i in range(taz_count - start_taz_id + 1)]
# convert list of dicts to a DataFrame and concat to avoid using deprecated DataFrame.append
if len(externals_to_append) > 0:
    externals_df = pd.DataFrame(externals_to_append)
    land_use_merged = pd.concat([land_use_merged, externals_df], ignore_index=True)

land_use_merged.loc[land_use_merged['taz_id'] >= start_taz_id , 'External'] = 1
land_use_merged.loc[land_use_merged['taz_id'] >= start_taz_id , 'area_type'] = 5

land_use_merged.fillna(0, inplace=True)

#sort by maz_id
land_use_merged.sort_values(by='maz_id', inplace=True)

land_use_merged.to_csv(merged_landuse_output_dir, index=False)

maz_taz = land_use_merged[['maz_id', 'taz_id']].rename(columns = {'maz_id': 'MAZ', 'taz_id': 'TAZ'})
maz_taz.to_csv(_join(output_dir, 'skims' ,'maz_taz_mapping.csv'), index=False)