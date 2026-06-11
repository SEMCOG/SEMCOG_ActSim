# %%
import pandas as pd
import numpy as np
import openmatrix as omx
import sys

# %%
output_dir = sys.argv[1]
ee_dir = sys.argv[2]

hh_dir = output_dir + '/ActivitySim/final_households.csv'
per_dir = output_dir + '/ActivitySim/final_persons.csv'
lu_dir = output_dir + '/ActivitySim/final_land_use.csv'
tours_dir = output_dir + '/ActivitySim/final_tours.csv'
trips_dir = output_dir + '/ActivitySim/final_trips.csv'

abm_viz = output_dir + '/ActivitySim/visualizer'

# Placeholder for second scenario comparison — uncomment when ready
# open(abm_viz + '/empty.md', 'w').close()

# %%
hh = pd.read_csv(hh_dir, engine='pyarrow')
per = pd.read_csv(per_dir, engine='pyarrow')
land_use = pd.read_csv(lu_dir, engine='pyarrow')
tours = pd.read_csv(tours_dir, engine='pyarrow')
trips = pd.read_csv(trips_dir, engine='pyarrow')

land_use = land_use[land_use.county!=0]
per = pd.merge(per, land_use[['zone_id', 'TAZ']], left_on='home_zone_id', right_on='zone_id')
# %%
transcad_report = pd.DataFrame(columns=["Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"])
transcad_report.columns = ["Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"]

# %%
total_hh = hh.groupby('home_county').size().reset_index()
total_hh.rename(columns={0:'freq'}, inplace=True)
total_hh.loc['All',:] = total_hh['freq'].sum()

total_pop = per.groupby('home_county').size().reset_index()
total_pop.rename(columns={0:'freq'}, inplace=True)
total_pop.loc['All',:] = total_pop['freq'].sum()

# %%
income_county = pd.crosstab(hh.income_segment, hh.home_county, margins=True)

# %%
ftime_county = hh.groupby('home_county')['num_fullTime_workers'].sum().reset_index()
ftime_county.loc['All',:] = ftime_county['num_fullTime_workers'].sum()
ptime_county = per.groupby('home_county')['is_parttime_worker'].sum().reset_index()
ptime_county.loc['All',:] = ptime_county['is_parttime_worker'].sum()

# %%
colstud_county = per[per.ptype==3].groupby('home_county').size().reset_index()
colstud_county.rename(columns={0:'freq'}, inplace=True)
colstud_county.loc['All',:] = colstud_county['freq'].sum()

drivstud_county = per[per.ptype==6].groupby('home_county').size().reset_index()
drivstud_county.rename(columns={0:'freq'}, inplace=True)
drivstud_county.loc['All',:] = drivstud_county['freq'].sum()

nondrivstud_county = per[per.ptype==7].groupby('home_county').size().reset_index()
nondrivstud_county.rename(columns={0:'freq'}, inplace=True)
nondrivstud_county.loc['All',:] = nondrivstud_county['freq'].sum()

# %%
children_county = per[per.age<=17].groupby('home_county').size().reset_index()
children_county.rename(columns={0:'freq'}, inplace=True)
children_county.loc['All',:] = children_county['freq'].sum()

seniors_county = per[per.age>=65].groupby('home_county').size().reset_index()
seniors_county.rename(columns={0:'freq'}, inplace=True)
seniors_county.loc['All',:] = seniors_county['freq'].sum()

# %%
zeroautohh_county = hh[hh.auto_ownership==0].groupby('home_county').size().reset_index()
zeroautohh_county.rename(columns={0:'freq'}, inplace=True)
zeroautohh_county.loc['All',:] = zeroautohh_county['freq'].sum()

autodefhh_county = hh[hh.auto_ownership<hh.num_drivers].groupby('home_county').size().reset_index()
autodefhh_county.rename(columns={0:'freq'}, inplace=True)
autodefhh_county.loc['All',:] = autodefhh_county['freq'].sum()

# %%
transcad_report.loc['Total Households',:] = list(total_hh.freq)
transcad_report.loc['Total Population',:] = list(total_pop.freq)
transcad_report.loc['Low-income Households',:] = list(income_county.loc[1,:])
transcad_report.loc['Full-time Workers',:] = list(ftime_county.num_fullTime_workers)
transcad_report.loc['Part-time Workers',:] = list(ptime_county.is_parttime_worker)
transcad_report.loc['College Students',:] = list(colstud_county.freq)
transcad_report.loc['Driving-age Students',:] = list(drivstud_county.freq)
transcad_report.loc['Non-Driving-age Students',:] = list(nondrivstud_county.freq)
transcad_report.loc['Children (Age 17 and under)',:] = list(children_county.freq)
transcad_report.loc['Seniors (65+)',:] = list(seniors_county.freq)
transcad_report.loc['Zero-Auto Households',:] = list(zeroautohh_county.freq)
transcad_report.loc['Auto-deficient Households',:] = list(autodefhh_county.freq)

transcad_report = transcad_report.reset_index()
transcad_report.rename(columns={'index':'variable'}, inplace=True)

transcad_report.to_csv(abm_viz + '/transcad_report_HH.csv', index=False)

# %%
emp_df = pd.DataFrame(index=['enrollment_k_8', 'enrollment_9_12', 'univ_enrollment', 'e01_nrm', 'e02_constr',
       'e03_manuf', 'e04_whole', 'e05_retail', 'e06_trans', 'e07_utility',
       'e08_infor', 'e09_finan', 'e10_pstsvc', 'e11_compmgt', 'e12_admsvc',
       'e13_edusvc', 'e14_medfac', 'e15_hospit', 'e16_leisure', 'e17_othsvc',
       'e18_pubadm', 'tot_emp', 'county'])

emp_df['emp'] = ['Grade K-8 Enrollment', 'Grade 9-12 Enrollment', 'University Enrollment','Natural_Resource_and_Mining', 'Construction', 'Manufacturing', 'Wholesale_Trade', 'Retail_Trade', 'Transportation_and_Warehousing', 'Utilities', 'Information',
'Financial_Service', 'Professional_Science_Tec', 'Management_of_CompEnt', 'Administrative_Support_and_WM', 'Education_Services', 'Health_Care_and_SocialSer',
'Hospitality', 'Leisure', 'Other_Services', 'Public_Administration', 'Total Employment', 'COUNTY']

for i in list(emp_df.index):
    land_use.rename(columns={i:emp_df.loc[i,'emp']}, inplace=True)

transcad_report_LU = land_use[list(emp_df['emp'])].groupby('COUNTY').sum().reset_index().transpose()
transcad_report_LU.columns = ["Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston"]
transcad_report_LU.drop('COUNTY', inplace=True)
transcad_report_LU['All'] = transcad_report_LU.sum(axis=1)

transcad_report_LU = transcad_report_LU.reset_index()
transcad_report_LU.rename(columns={'index':'variable'}, inplace=True)

transcad_report_LU.to_csv(abm_viz + '/transcad_report_LU.csv', index=False)

# %%
industry_code = {1: 'Natural Resources & Mining',
 2: 'Construction',
 3: 'Manufacturing',
 4: 'Wholesale Trade',
 5: 'Retail Trade',
 6: 'Transportation & Warehousing',
 7: 'Utilities',
 8: 'Information',
 9: 'Financial Activities',
 10: 'Professional, Scientific, & Technical Services',
 11: 'Management of Companies & Enterprises',
 12: 'Administrative, Support, & Waste Services',
 13: 'Education Services',
 14: 'Medical Facilities',
 15: 'Hospitals',
 16: 'Leisure & Hospitality',
 17: 'Other Services',
 18: 'Public Administration'}

per_ = per[(per.esr!=3) & (per.esr!=6)]
per_['industry_name'] = per_['industry'].map(industry_code)
land_use_taz = land_use.groupby('TAZ')['COUNTY'].first().reset_index()
per_ = pd.merge(per_, land_use_taz[['TAZ',  'COUNTY']], how='left', on='TAZ')
per_industry = pd.crosstab(per_['industry_name'], per_['COUNTY'], margins=True)
per_industry = per_industry.reindex(['Natural Resources & Mining', 'Construction', 'Manufacturing', 'Wholesale Trade', 'Retail Trade', 'Transportation & Warehousing', 'Utilities', 'Information',
                                     'Financial Activities', 'Professional, Scientific, & Technical Services', 'Management of Companies & Enterprises', 'Administrative, Support, & Waste Services', 
                                     'Education Services', 'Medical Facilities', 'Hospitals', 'Leisure & Hospitality', 'Other Services', 'Public Administration', 'All'])
per_industry.columns = ["Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"]
per_industry.to_csv(abm_viz + '/transcad_report_Personindustry.csv')
# %%
hh['hhsize_recode'] = np.where(hh.hhsize>4, 5, hh.hhsize)
transcad_report_hhsize_income = pd.crosstab(hh.hhsize_recode, hh.income_segment, margins=True)
transcad_report_hhsize_income.columns = ['one', 'two', 'three', 'four', 'All']
transcad_report_hhsize_income.to_csv(abm_viz + '/transcad_report_hhsize_income.csv')

# %%
hh['hhnumchild_recode'] = np.where(hh.num_children>2, 3, hh.num_children)
transcad_report_hhchild_income = pd.crosstab(hh.hhsize_recode, hh.hhnumchild_recode, margins=True)
transcad_report_hhchild_income.columns = ['zero', 'one', 'two', 'three', 'All']
transcad_report_hhchild_income.to_csv(abm_viz + '/transcad_report_hhsize_numchild.csv')

# %%
hh['auto_recode'] = np.where(hh.auto_ownership>3, 4, hh.auto_ownership)
transcad_report_hhsize_auto = pd.crosstab(hh.hhsize_recode, hh.auto_recode, margins=True)
transcad_report_hhsize_auto.columns = ['zero', 'one', 'two', 'three', 'four', 'All']
transcad_report_hhsize_auto.to_csv(abm_viz + '/transcad_report_hhsize_auto.csv')

# %%
hh['num_workers_recode'] = np.where(hh.num_workers>2, 3, hh.num_workers)
transcad_report_hhworker_auto = pd.crosstab(hh.num_workers_recode, hh.auto_recode, margins=True)
transcad_report_hhworker_auto.columns = ['zero', 'one', 'two', 'three', 'four', 'All']
transcad_report_hhworker_auto.to_csv(abm_viz + '/transcad_report_hhworker_auto.csv')

# %%
transcad_report_hhworker_income = pd.crosstab(hh.num_workers_recode, hh.income_segment, margins=True)
transcad_report_hhworker_income.columns = ['one', 'two', 'three', 'four', 'All']
transcad_report_hhworker_income.to_csv(abm_viz + '/transcad_report_hhworker_income.csv')

# %%
transcad_report_income_auto = pd.crosstab(hh.income_segment, hh.auto_recode, margins=True)
transcad_report_income_auto.columns = ['zero', 'one', 'two', 'three', 'four', 'All']
transcad_report_income_auto.to_csv(abm_viz + '/transcad_report_income_auto.csv')

# %%
tours = pd.merge(tours, land_use[['zone_id', 'COUNTY']], left_on='origin', right_on='zone_id')
tours_county = pd.crosstab(tours.primary_purpose, tours.COUNTY, values=tours.number_of_participants, aggfunc='sum', margins=True)
tours_county.columns = ["Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"]
tours_county.to_csv(abm_viz + '/tours_county.csv')

# %%
trips = pd.merge(trips, land_use[['zone_id', 'COUNTY']], left_on='origin', right_on='zone_id')
trips = pd.merge(trips, tours[['tour_id', 'number_of_participants']], on='tour_id')
trips_county = pd.crosstab(trips.primary_purpose, trips.COUNTY, values=trips.number_of_participants, aggfunc='sum', margins=True)
trips_county.columns = ["Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"]
trips_county.to_csv(abm_viz + '/trips_county.csv')

# %%
trips['tripmode_recode'] = trips.trip_mode
trips['tripmode_recode'] = np.where(trips.trip_mode.isin(['WALK_LOC','PNR_LOC','KNR_LOC']), 'Local Transit',trips['tripmode_recode'])
trips['tripmode_recode'] = np.where(trips.trip_mode.isin(['WALK_PRM','PNR_PRM','KNR_PRM']), 'PRM Transit', trips['tripmode_recode'])
trips['tripmode_recode'] = np.where(trips.trip_mode.isin(['WALK_MIX','PNR_MIX','KNR_MIX']), 'MIX Transit', trips['tripmode_recode'])
trips['tripmode_recode'] = np.where(trips.trip_mode.isin(['TAXI','TNC_SINGLE','TNC_SHARED']), 'TAXI/RIDEHAIL', trips['tripmode_recode'])

tripsmode_county = pd.crosstab(trips.tripmode_recode, trips.COUNTY, values=trips.number_of_participants, aggfunc='sum', margins=True)
tripsmode_county = tripsmode_county.loc[['DRIVEALONE','SHARED2', 'SHARED3', 'WALK', 'BIKE', 'Local Transit', 'PRM Transit', 'MIX Transit',
       'SCHOOLBUS', 'TAXI/RIDEHAIL', 'All'],:]
tripsmode_county.columns = ["Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston", "All"]
tripsmode_county.to_csv(abm_viz + '/tripmode_county.csv')

# %%
tours = pd.merge(tours, hh[['household_id', 'income_segment']], on='household_id')
tours['tourmode_recode'] = tours.tour_mode
tours['tourmode_recode'] = np.where(tours.tour_mode.isin(['WALK_LOC','PNR_LOC','KNR_LOC']), 'Local Transit',tours['tourmode_recode'])
tours['tourmode_recode'] = np.where(tours.tour_mode.isin(['WALK_PRM','PNR_PRM','KNR_PRM']), 'PRM Transit', tours['tourmode_recode'])
tours['tourmode_recode'] = np.where(tours.tour_mode.isin(['WALK_MIX','PNR_MIX','KNR_MIX']), 'MIX Transit', tours['tourmode_recode'])
tours['tourmode_recode'] = np.where(tours.tour_mode.isin(['TAXI','TNC_SINGLE','TNC_SHARED']), 'TAXI/RIDEHAIL', tours['tourmode_recode'])
toursmode_income = pd.crosstab(tours.income_segment, tours.tourmode_recode, values=tours.number_of_participants, aggfunc='sum', margins=True)
toursmode_income = toursmode_income.loc[:,['DRIVEALONE','SHARED2', 'SHARED3', 'WALK', 'BIKE', 'Local Transit', 'PRM Transit', 'MIX Transit',
       'SCHOOLBUS', 'TAXI/RIDEHAIL', 'All']]

toursmode_income.to_csv(abm_viz + '/toursmode_income.csv')

# %%
hh['auto_recode'] = 'zero_auto'
hh['auto_recode'] = np.where((hh.auto_ownership<hh.num_workers) & (hh.auto_ownership>0), 'auto_less', hh['auto_recode'])
hh['auto_recode'] = np.where((hh.auto_ownership==hh.num_workers) & (hh.auto_ownership>0), 'auto_equal', hh['auto_recode'])
hh['auto_recode'] = np.where((hh.auto_ownership>hh.num_workers) & (hh.auto_ownership>0), 'auto_more', hh['auto_recode'])
tours = pd.merge(tours, hh[['household_id', 'auto_recode']], on='household_id')
tourmode_auto = pd.crosstab(tours.auto_recode, tours.tourmode_recode, values=tours.number_of_participants, aggfunc='sum', margins=True)
tourmode_auto = tourmode_auto.loc[['zero_auto', 'auto_less', 'auto_equal', 'auto_more', 'All'],['DRIVEALONE','SHARED2', 'SHARED3', 'WALK', 'BIKE', 'Local Transit', 'PRM Transit', 'MIX Transit',
       'SCHOOLBUS', 'TAXI/RIDEHAIL', 'All']]

tourmode_auto.to_csv(abm_viz + '/tourmode_auto.csv')

# %%
EI_EA = omx.open_file(output_dir + '/EXTAirport' + '/EI_OD_EA.omx')
EI_AM = omx.open_file(output_dir + '/EXTAirport'+ '/EI_OD_AM.omx')
EI_MD = omx.open_file(output_dir + '/EXTAirport'+ '/EI_OD_MD.omx')
EI_PM = omx.open_file(output_dir + '/EXTAirport'+ '/EI_OD_PM.omx')
EI_EV = omx.open_file(output_dir + '/EXTAirport'+ '/EI_OD_EV.omx')

IE_EA = omx.open_file(output_dir + '/EXTAirport'+ '/IE_OD_EA.omx')
IE_AM = omx.open_file(output_dir + '/EXTAirport'+ '/IE_OD_AM.omx')
IE_MD = omx.open_file(output_dir + '/EXTAirport'+ '/IE_OD_MD.omx')
IE_PM = omx.open_file(output_dir + '/EXTAirport'+ '/IE_OD_PM.omx')
IE_EV = omx.open_file(output_dir + '/EXTAirport'+ '/IE_OD_EV.omx')

airport_EA = omx.open_file(output_dir + '/EXTAirport'+ '/AIRPORT_EA.omx')
airport_AM = omx.open_file(output_dir + '/EXTAirport'+ '/AIRPORT_AM.omx')
airport_MD = omx.open_file(output_dir + '/EXTAirport'+ '/AIRPORT_MD.omx')
airport_PM = omx.open_file(output_dir + '/EXTAirport'+ '/AIRPORT_PM.omx')
airport_EV = omx.open_file(output_dir + '/EXTAirport'+ '/AIRPORT_EV.omx')

# %%
EI_total = np.array(EI_EA['Trips']) + np.array(EI_AM['Trips']) + np.array(EI_MD['Trips']) + np.array(EI_PM['Trips']) + np.array(EI_EV['Trips'])

df = pd.DataFrame(EI_total)
df = df.stack().reset_index()
df.columns = ['ORIG_TAZ', 'DEST_TAZ', 'TRIPS']
df['ORIG_TAZ'] = df['ORIG_TAZ']+1
df['DEST_TAZ'] = df['DEST_TAZ']+1

lu_taz = land_use[['TAZ', 'COUNTY']].groupby('TAZ').first()
df = pd.merge(df, lu_taz[['COUNTY']], left_on='DEST_TAZ', right_index=True, how = 'left')

EI_county = df.groupby('COUNTY').TRIPS.sum().reset_index()
EI_county['TRIPS'] *=2

# %%
IE_total = np.array(IE_EA['Trips']) + np.array(IE_AM['Trips']) + np.array(IE_MD['Trips']) + np.array(IE_PM['Trips']) + np.array(IE_EV['Trips'])

df = pd.DataFrame(IE_total)
df = df.stack().reset_index()
df.columns = ['ORIG_TAZ', 'DEST_TAZ', 'TRIPS']
df['ORIG_TAZ'] = df['ORIG_TAZ']+1
df['DEST_TAZ'] = df['DEST_TAZ']+1

df = pd.merge(df, lu_taz[['COUNTY']], left_on='DEST_TAZ', right_index=True, how = 'left')

IE_county = df.groupby('COUNTY').TRIPS.sum().reset_index()
IE_county['TRIPS'] *=2

# %%
airport_total = np.array(airport_EA['Trips']) + np.array(airport_AM['Trips']) + np.array(airport_MD['Trips']) + np.array(airport_PM['Trips']) + np.array(airport_EV['Trips'])

df = pd.DataFrame(airport_total)
df = df.stack().reset_index()
df.columns = ['ORIG_TAZ', 'DEST_TAZ', 'TRIPS']
df['ORIG_TAZ'] = df['ORIG_TAZ']+1
df['DEST_TAZ'] = df['DEST_TAZ']+1

df = pd.merge(df, lu_taz[['COUNTY']], left_on='DEST_TAZ', right_index=True, how = 'left')
df.rename(columns={'COUNTY': 'dest_county'}, inplace=True)
df = pd.merge(df, lu_taz[['COUNTY']], left_on='ORIG_TAZ', right_index=True, how = 'left')
df.rename(columns={'COUNTY': 'orig_county'}, inplace=True)

FromAirport_county = df[df.ORIG_TAZ.isin([682, 683])].groupby('dest_county').TRIPS.sum().reset_index()
ToAirport_county = df[df.DEST_TAZ.isin([682, 683])].groupby('orig_county').TRIPS.sum().reset_index()

# %%
ee = pd.read_csv(ee_dir, usecols=['SOV', 'HOV2', 'HOV3'])
x = ["", "", "", "", "", "", "", "",ee.sum().sum()]

# %%
transcad_report_ex = pd.DataFrame(columns=["Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston"])
transcad_report_ex.columns = ["Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "StClair", "Livingston"]

transcad_report_ex.loc['Ex_to',:] = list(EI_county['TRIPS'])
transcad_report_ex.loc['Ex_from',:] = list(IE_county['TRIPS'])
transcad_report_ex.loc['dtw_to',:] = list(FromAirport_county['TRIPS'])
transcad_report_ex.loc['dtw_from',:] = list(ToAirport_county['TRIPS'])
transcad_report_ex['All'] = transcad_report_ex.sum(axis=1)
transcad_report_ex.loc['ee',:] = x
transcad_report_ex.index.name = 'variable'
transcad_report_ex = transcad_report_ex.reset_index()
transcad_report_ex.to_csv(abm_viz + '/extairport_county.csv', index=False)

# ── Transit rider profile: car ownership and income by person type (%) ─────────
TRANSIT_MODES = ["WALK_LOC","PNR_LOC","KNR_LOC","PNR_PRM",
                 "WALK_PRM","WALK_MIX","KNR_PRM","KNR_MIX","PNR_MIX"]
PTYPE_MAP   = {1:"FTW", 2:"PTW", 3:"COL", 4:"NWA", 5:"RET", 6:"DAS", 7:"NDS", 8:"NDS"}
PTYPE_ORDER = ["FTW","PTW","COL","NWA","RET","DAS","NDS"]

tr_df = trips[trips['trip_mode'].isin(TRANSIT_MODES)].copy()
tr_df = tr_df.merge(per[['household_id','person_id','ptype']], on=['household_id','person_id'], how='left')
tr_df = tr_df.merge(hh[['household_id','auto_ownership','income']], on='household_id', how='left')
tr_df['PersonType']   = tr_df['ptype'].map(PTYPE_MAP)
tr_df['CarOwnership'] = np.where(tr_df['auto_ownership'] == 0, 'Zero Car', 'Non-Zero Car')
tr_df['Income']       = pd.cut(tr_df['income'],
                                bins=[-np.inf, 30000, 60000, 100000, np.inf],
                                labels=['1.<$30k','2.$30k-$60k','3.$60k-$100k','4.>$100k'],
                                right=True).astype(str)

def make_pct_wide(df, cat_col):
    grp = df.groupby(['PersonType', cat_col])['number_of_participants'].sum().reset_index()
    grp['Pct'] = grp.groupby('PersonType')['number_of_participants']\
                    .transform(lambda x: round(x / x.sum() * 100, 2))
    wide = (grp.drop(columns='number_of_participants')
               .pivot(index='PersonType', columns=cat_col, values='Pct')
               .fillna(0).reset_index()
               .rename_axis(None, axis=1))
    wide['PersonType'] = pd.Categorical(wide['PersonType'], categories=PTYPE_ORDER, ordered=True)
    return wide.sort_values('PersonType').reset_index(drop=True)

abm_car_wide = make_pct_wide(tr_df, 'CarOwnership')
abm_inc_wide = make_pct_wide(tr_df, 'Income')

abm_car_wide.to_csv(abm_viz + '/abm_carownership_by_ptype_pct.csv', index=False)
abm_inc_wide.to_csv(abm_viz + '/abm_income_by_ptype_pct.csv', index=False)

ptype_share = (tr_df.groupby('PersonType')['number_of_participants'].sum().reset_index())
ptype_share['PersonType'] = pd.Categorical(ptype_share['PersonType'], categories=PTYPE_ORDER, ordered=True)
ptype_share = ptype_share.sort_values('PersonType').reset_index(drop=True)
ptype_share['number_of_participants'] = ptype_share['number_of_participants'].round(0).astype(int)
ptype_share_wide = ptype_share.set_index('PersonType')[['number_of_participants']].T.reset_index(drop=True)
ptype_share_wide.to_csv(abm_viz + '/abm_ptype_share.csv', index=False)
print("abm_carownership_by_ptype_pct.csv, abm_income_by_ptype_pct.csv, abm_ptype_share.csv written.")

# ── County-level OD for SimWrapper spider map ─────────────────────────────────
import os
import shutil
import geopandas as gpd

_script_dir = os.path.dirname(os.path.abspath(__file__))
_shp_dir  = os.path.normpath(os.path.join(_script_dir, '..', 'data', 'SHP'))
_viz_dir  = os.path.normpath(os.path.join(_script_dir, '..'))
_od_dir   = abm_viz + '/od'
os.makedirs(_od_dir, exist_ok=True)

# Copy static config files from ABM/Visualizer into visualizer/
for _f in ['simwrap_config.yaml', 'dashboard-transit-summary.yaml']:
    _src = os.path.join(_viz_dir, _f)
    if os.path.exists(_src):
        shutil.copy(_src, abm_viz)
    else:
        print(f"WARNING: {_src} not found — skipped")

# Append model run path to description in the deployed dashboard YAML only
import re
_run_dir = os.path.dirname(os.path.normpath(output_dir))
_dash_yaml = os.path.join(abm_viz, 'dashboard-transit-summary.yaml')
with open(_dash_yaml, 'r') as _fh:
    _dash_content = _fh.read()
_run_dir_fwd = _run_dir.replace('\\', '/')
_dash_content = re.sub(
    r'(  description: ")(.*?)(")',
    lambda m: f'{m.group(1)}{m.group(2).rstrip(". ")}. {_run_dir_fwd}{m.group(3)}',
    _dash_content, count=1
)
with open(_dash_yaml, 'w') as _fh:
    _fh.write(_dash_content)

# Copy static files from ABM/Visualizer into od/
shutil.copy(os.path.join(_viz_dir, 'viz-od-abm.yaml'), _od_dir)
for _ext in ['shp', 'dbf', 'prj', 'shx']:
    shutil.copy(os.path.join(_shp_dir, f'SEMCOG_County.{_ext}'),
                os.path.join(_od_dir, f'semcog_counties.{_ext}'))
print("Copied viz-od-abm.yaml and semcog_counties.* to od/.")

# TAZ → county lookup (from semcog_zones.shp)
_zones = gpd.read_file(os.path.join(_shp_dir, 'semcog_zones.shp'))
_tc = (_zones[(_zones['EXTERNAL'].astype(int) == 0) & (_zones['COUNTY'].astype(int) > 0)]
       [['ID', 'COUNTY']].copy())

# Read transit OMX files and sum across periods
_omx_dir = output_dir + '/TrnAssign/'
_od_mat = np.zeros((2811, 2811), dtype=np.float64)
for _per in ["EA", "AM", "MD", "PM", "EV"]:
    _f = omx.open_file(_omx_dir + f'OD_TRN_{_per}.omx')
    for _m in _f.list_matrices():
        _mat = np.array(_f[_m])
        _od_mat += _mat[:2811, :2811] if _mat.shape[0] > 2811 else _mat
    _f.close()

_ri, _ci = np.nonzero(_od_mat)
_taz_od = pd.DataFrame({'origin':      _ri + 1,
                         'destination': _ci + 1,
                         'flow':        np.round(_od_mat[_ri, _ci], 2)})
_taz_od = _taz_od[_taz_od['flow'] > 0]
_taz_od.to_csv(abm_viz + '/abm_od_matrix.csv', index=False, sep=';')
print(f"abm_od_matrix.csv: {len(_taz_od)} pairs, total flow {_taz_od['flow'].sum():,.0f}")

# Aggregate TAZ OD → county OD
_county_od = (_taz_od
              .merge(_tc.rename(columns={'ID': 'origin',      'COUNTY': 'orig_c'}),  on='origin',      how='inner')
              .merge(_tc.rename(columns={'ID': 'destination', 'COUNTY': 'dest_c'}),  on='destination', how='inner')
              .groupby(['orig_c', 'dest_c'])['flow'].sum()
              .reset_index()
              .rename(columns={'orig_c': 'origin', 'dest_c': 'destination'}))
_county_od['flow'] = _county_od['flow'].round(1)
_county_od = _county_od[_county_od['flow'] > 0]
_county_od.to_csv(_od_dir + '/abm_od_county.csv', index=False, sep=';')
print(f"abm_od_county.csv: {len(_county_od)} pairs, total flow {_county_od['flow'].sum():,.0f}")

# Wide-format 8x8 county OD matrix for dashboard table
# Source: enums.py County class (C:\cliu\GitHub\develop_SEMCOG\ABM\data_model\enums.py)
_COUNTY_NAME = {1: 'Detroit', 2: 'Wayne', 3: 'Oakland', 4: 'Macomb',
                5: 'Washtenaw', 6: 'Monroe', 7: 'St. Clair', 8: 'Livingston'}
_county_matrix = (_county_od[_county_od['origin'].isin(_COUNTY_NAME) &
                              _county_od['destination'].isin(_COUNTY_NAME)]
                  .assign(origin=lambda d: d['origin'].map(_COUNTY_NAME),
                          destination=lambda d: d['destination'].map(_COUNTY_NAME))
                  .pivot(index='origin', columns='destination', values='flow')
                  .reindex(index=list(_COUNTY_NAME.values()),
                           columns=list(_COUNTY_NAME.values()))
                  .fillna(0).round(0).astype(int)
                  .reset_index()
                  .rename(columns={'origin': 'O\\D'}))

# Markdown table for SimWrapper text component
_cols = list(_county_matrix.columns)
_md_lines = ['| ' + ' | '.join(_cols) + ' |']
_md_lines.append('| ' + ' | '.join(['---:' if i > 0 else '---' for i in range(len(_cols))]) + ' |')
for _, row in _county_matrix.iterrows():
    _md_lines.append('| ' + ' | '.join(str(row[c]) for c in _cols) + ' |')
with open(abm_viz + '/abm_od_county_matrix.md', 'w') as _f:
    _f.write('\n'.join(_md_lines) + '\n')
print("abm_od_county_matrix.md written.")
