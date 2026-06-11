# %%
import pandas as pd, numpy as np, openmatrix as omx
import os as os
import sys
import geopandas as gpd
_join, _dir, _normpath = os.path.join, os.path.dirname, os.path.normpath

# %%
input_dir = sys.argv[1]
output_dir = sys.argv[2]
trn_output_dir = sys.argv[3]
scripts_dir = sys.argv[4]
asim_dir = sys.argv[5]
ee_file = sys.argv[6]
output_folder_dir = sys.argv[7]
# %%
#read in factors to divide special market trips among drivealone, shared2, shared3
air_occ_fac = pd.read_excel(os.path.join(scripts_dir,'airport_ext_factors.xlsx'),sheet_name='airport_occup_factors')
air_occ_fac = air_occ_fac.set_index('PER')
ext_occ_fac = pd.read_excel(os.path.join(scripts_dir,'airport_ext_factors.xlsx'),sheet_name='ext_occup_factors')
ext_tod_fac = pd.read_excel(os.path.join(scripts_dir,'airport_ext_factors.xlsx'),sheet_name='ext_tod_factors')
taz_file = gpd.read_file(_join(output_folder_dir, 'WorkingFiles/SEMCOG_TAZ.shp'))

OCC_SHARED2 = 2.0
OCC_SHARED3 = 3.33

# %%
periods = ['EA', 'AM', 'MD', 'PM', 'EV']
modes = ['DRIVEALONE', 'SHARED2', 'SHARED3', 'LIGHT_TRUCK', 'MEDIUM_TRUCK', 'HEAVY_TRUCK']

# %%
taz_count = len(taz_file)
skeleton = pd.DataFrame(zip(range(1,taz_count+1), range(1,taz_count+1)))
skeleton.columns = ['ORIG_TAZ', 'DEST_TAZ']
skeleton['TRIPS'] = 0
skeleton = pd.DataFrame(skeleton.pivot(index='ORIG_TAZ', columns='DEST_TAZ', values='TRIPS').reset_index().to_records()).fillna(0)
skeleton.set_index('ORIG_TAZ', inplace=True)
del skeleton['index']
skeleton = skeleton.stack().reset_index()
skeleton.columns = ['ORIG_TAZ', 'DEST_TAZ', 'TRIPS']
skeleton['DEST_TAZ'] = skeleton['DEST_TAZ'].astype('int64')

# %%
#seperate HWY and TRN ODs
for period in periods:
    asim_name = 'trips_'+period.lower()
    od_name = 'ASIM_'+period
    od_trn_name = 'OD_TRN_'+period

    with omx.open_file((_join(asim_dir, asim_name+'.omx')),'r') as asim_trips:  
        asim_cores = asim_trips.list_matrices()
        zoneid = asim_trips.mapping('TAZ')
        zones = list(zoneid.keys())
        zones_sorted = sorted(list(zoneid.keys()))
        pos = [zones.index(zone) for zone in zones_sorted]
    
        with omx.open_file((_join(output_dir, od_name+'.omx')),'w') as od_trips:
            for core in asim_cores:
                if core in ['DRIVEALONE', 'SHARED2', 'SHARED3']:
                    #add taxi and tnc to shared and convert to vehicle trips
                    if core == 'SHARED2':                                      
                        od_trips[core] = (np.array(asim_trips[core]) + np.array(asim_trips['TAXI']) + np.array(asim_trips['TNC_SINGLE']))/OCC_SHARED2
                    elif core == 'SHARED3':
                        od_trips[core] = (np.array(asim_trips[core]) + np.array(asim_trips['TNC_SHARED']))/OCC_SHARED3
                    else:
                        od_trips[core] = np.array(asim_trips[core])                                      

        with omx.open_file((_join(trn_output_dir, od_trn_name+'.omx')),'w') as od_trn_trips:
            for core in asim_cores:
                if core not in ['DRIVEALONE', 'SHARED2', 'SHARED3', 'WALK', 'BIKE', 'SCHOOLBUS', 'TAXI', 'TNC_SINGLE', 'TNC_SHARED']:
                    data = asim_trips[core]
                    data = data[:][pos,:][:,pos]
                    df = pd.DataFrame(np.array(data))
                    df = df.stack().reset_index()
                    df.columns = ['ORIG_TAZ', 'DEST_TAZ', 'TRIPS']
                    df['ORIG_TAZ'] = df['ORIG_TAZ']+1
                    df['DEST_TAZ'] = df['DEST_TAZ']+1
                    
                    df = pd.merge(df, skeleton, on = ['ORIG_TAZ', 'DEST_TAZ'], how = 'right')
                    df.fillna(0, inplace=True)
                    df['TRIPS'] = df['TRIPS_x'] + df['TRIPS_y']
                    df = df[['ORIG_TAZ', 'DEST_TAZ', 'TRIPS']]
                
                    df = pd.DataFrame(df.pivot(index='ORIG_TAZ', columns='DEST_TAZ', values='TRIPS').reset_index().to_records()).fillna(0)
                    df.set_index('ORIG_TAZ', inplace=True)
                    del df['index']
                    df.index.name = None

                    od_trn_trips[core] = np.array(df)

# %%
#set up the external-external trips to be added to the other external-airport trips
ee_trips = pd.read_csv(ee_file, usecols=['ORIG_TAZ', 'DEST_TAZ', 'SOV', 'HOV2', 'HOV3'])
ee_trips = ee_trips.rename(columns={'SOV':'DRIVEALONE', 'HOV2':'SHARED2', 'HOV3':'SHARED3'})

ext_ext = pd.DataFrame({'ORIG_TAZ': np.repeat(list(range(1,taz_count+1)), taz_count), 'DEST_TAZ': np.tile(list(range(1,taz_count+1)), taz_count), 'TRIPS':0})
ext_ext = pd.merge(ext_ext, ee_trips, on = ['ORIG_TAZ', 'DEST_TAZ'], how = 'left').fillna(0)

# %%
#add together all the external and airport trips
for period in periods:
    try:
        ei_trips = omx.open_file((_join('\\'.join(output_dir.split('\\')[:-1]) + '\\EXTAirport', 'EI_OD_'+period+'.omx')),'r')
        ie_trips = omx.open_file((_join('\\'.join(output_dir.split('\\')[:-1]) + '\\EXTAirport', 'IE_OD_'+period+'.omx')),'r')
        airport_trips = omx.open_file((_join('\\'.join(output_dir.split('\\')[:-1]) + '\\EXTAirport', 'Airport_'+period+'.omx')),'r')
        
        with omx.open_file((_join(output_dir, 'EXTAirport_'+period+'.omx')),'w') as ex_airport_trips:
        
            for mode in ['DRIVEALONE', 'SHARED2', 'SHARED3']:
                #airport
                airport_core = np.array(airport_trips['Trips']) * air_occ_fac.loc[period, mode]
                #ei/ie
                ei_core = np.array(ei_trips['Trips']) * ext_occ_fac[mode][0]
                ie_core = np.array(ie_trips['Trips']) * ext_occ_fac[mode][0]

                aux_core = airport_core + ei_core + ie_core
                #ee
                ext_copy = ext_ext.copy()
                ext_copy ['TRIPS'] = ext_copy ['TRIPS'] + ext_copy [mode]
                ext_copy = ext_copy [['ORIG_TAZ', 'DEST_TAZ', 'TRIPS']]
                ext_piv = ext_copy.pivot(index='ORIG_TAZ', columns='DEST_TAZ', values='TRIPS')
                ee_core =  np.array(ext_piv) * ext_tod_fac[period][0] 
#               ee_core =  np.array(ext_piv) * ext_tod_fac[period][0] * ext_occ_fac[mode][0]
                #add up
                aux_core = np.add(aux_core, ee_core)
                ex_airport_trips[mode] = np.array(aux_core)
    finally:
        ei_trips.close()
        ie_trips.close()
        airport_trips.close()

# %%
#add internal asim trips with the special market trips
for period in periods:
    try:
        as_trips = omx.open_file((_join(output_dir, 'ASIM_'+period+'.omx')),'r')
        ex_trips = omx.open_file((_join(output_dir, 'EXTAirport_'+period+'.omx')),'r')
        od_trips = omx.open_file((_join(output_dir, 'OD_'+period+'.omx')),'w')

        for mode in ['DRIVEALONE', 'SHARED2', 'SHARED3']:

                as_core = pd.DataFrame(np.array(as_trips[mode]))
                aux_core  = pd.DataFrame(np.array(ex_trips[mode]))
                #asim only has internal trips, so does not include TAZ indices for extneral zones
                as_core = as_core.stack().reset_index()
                as_core.columns = ['ORIG_TAZ', 'DEST_TAZ', 'TRIPS1']
                aux_core = aux_core.stack().reset_index()
                aux_core.columns = ['ORIG_TAZ', 'DEST_TAZ', 'TRIPS2']

                total_od = pd.merge(as_core, aux_core, on = ['ORIG_TAZ', 'DEST_TAZ'], how = 'right')
                total_od['TRIPS1'].fillna(0, inplace=True)
                total_od['TRIPS'] = total_od['TRIPS1']+total_od['TRIPS2']

                total_od = pd.DataFrame(total_od.pivot(index='ORIG_TAZ', columns='DEST_TAZ', values='TRIPS').reset_index().to_records()).fillna(0)
                total_od.set_index('ORIG_TAZ', inplace=True)
                del total_od['index']
                total_od.index.name = None
                

                od_trips[mode] = np.array(total_od)
    finally:
        as_trips.close()
        ex_trips.close()
        od_trips.close()
        
# %%
#create the daily OD matrix by adding up all the time periods
ea_od = omx.open_file((_join(output_dir, 'OD_EA'+'.omx')),'r')
am_od = omx.open_file((_join(output_dir, 'OD_AM'+'.omx')),'r')
md_od = omx.open_file((_join(output_dir, 'OD_MD'+'.omx')),'r')
pm_od = omx.open_file((_join(output_dir, 'OD_PM'+'.omx')),'r')
ev_od = omx.open_file((_join(output_dir, 'OD_EV'+'.omx')),'r')

with omx.open_file((_join(output_dir, 'OD_DY.omx')),'w') as od_dy:
    for mode in ['DRIVEALONE', 'SHARED2', 'SHARED3']:
        od_dy[mode] = np.array(ea_od[mode]) + np.array(am_od[mode]) + np.array(md_od[mode]) + np.array(pm_od[mode]) + np.array(ev_od[mode])

ea_od.close()
am_od.close()
md_od.close()
pm_od.close()
ev_od.close()

# %%
#find total number of transit trips for transcad report
#trips = pd.read_csv(_join(asim_dir, 'final_trips.csv'))
#df = pd.DataFrame({'Transit_total': [trips[~trips.trip_mode.isin(['DRIVEALONE', 'SHARED2', 'SHARED3', 'WALK', 'BIKE', 'SCHOOLBUS', 'TAXI', 'TNC_SINGLE', 'TNC_SHARED'])].shape[0]]})
#df.to_csv(trn_output_dir +'\\transit_total.csv', index=False)
