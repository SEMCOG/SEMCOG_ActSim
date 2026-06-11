# %%
import pandas as pd
import numpy as np
import geopandas as gpd
import openmatrix as omx
from sys import argv
import os
import datetime
import sys
import traceback

import warnings
from tables import NaturalNameWarning
warnings.filterwarnings('ignore', category=NaturalNameWarning)
warnings.filterwarnings("ignore", category=np.VisibleDeprecationWarning)

_join = os.path.join

input_dir = argv[1]
output_dir = argv[2]

# %%
class EJUtility:
    
    def __init__(self, engine: str):

        self.input_dir = input_dir
        self.output = output_dir

        #open a text file
        self.log = open(_join(self.output, 'EJ', 'EJ_Utility_Log.txt'), 'w')
        self.log.write('EJ Utility Log\n')
        self.log.write('Input Directory: ' + self.input_dir + '\n')
        self.log.write('Output Directory: ' + self.output + '\n')
        self.log.write('Date: ' + str(datetime.datetime.now()) + '\n')
        self.log.write('-- Initializing...\n')
        self.log.write('   Reading in data\n')

        print('\n')
        print('-- Initializing...')
        print('   Reading in data')

        try:
            self.persons_df = pd.read_csv(_join(self.output, 'ActivitySim', 'final_persons.csv'), engine = engine)
            self.households_df = pd.read_csv(_join(self.output, 'ActivitySim', 'final_households.csv'), engine = engine)
            self.maz_taz_mapping = pd.read_csv(_join(self.output, 'skims', 'maz_taz_mapping.csv'))
            self.land_use_taz = pd.read_csv(_join(self.output, 'WorkingFiles', 'land_use_taz.csv'))
            self.land_use_maz = pd.read_csv(_join(self.input_dir, 'SE_DATA', 'land_use_activitysim.csv'))
            self.land_use_maz.set_index('maz_id', inplace=True)
            self.maz_landuse_shapefile = gpd.read_file(_join(self.output, 'WorkingFiles', 'SEMCOG_MAZ.shp'))
            self.destination = pd.read_csv(_join(self.input_dir, 'EJ', 'destinations.csv'))
            self.trips = pd.read_csv(_join(self.output,'ActivitySim','final_trips.csv'), engine = engine)
            self.tours = pd.read_csv(_join(self.output,'ActivitySim','final_tours.csv'), engine = engine)
            self.taz_count = self.land_use_taz[self.land_use_taz['External'] == 0].shape[0]
            self.skim_periods = ['EA','AM','MD','PM','EV']

            self.maz_walk_skims = pd.read_csv(_join(self.output, 'skims', 'maz_to_maz_walk.csv'))
            self.maz_bike_skims = pd.read_csv(_join(self.output, 'skims', 'maz_to_maz_bike.csv'), engine = engine).rename(columns={'OMAZ':'origin', 'DMAZ':'destination'})

            self.configs = pd.read_csv(_join(self.input_dir, 'EJ', 'GroupDefinitions.csv'), comment='#')
            
            self.persons_df = pd.merge(self.persons_df, self.maz_taz_mapping, left_on='maz_id', right_on='MAZ', how='left').drop('MAZ', axis=1)
            self.households_df.rename(columns={'race_id':'hh_race_id'}, inplace=True)
            self.persons_df = pd.merge(self.persons_df, self.households_df[['household_id', 'auto_ownership', 'hh_race_id']], on='household_id', how='left')

            self.maz_level_destination = self.create_maz_level_destination_measures(self.maz_landuse_shapefile, self.destination)
            self.maz_access_times = self.transit_maz_level_access_times()
            self.tours_wSkims = self.attach_skims()

        except Exception as e:
            traceback.print_exc(file=self.log)
     

        self.EJ_Util_auto = pd.DataFrame()
        self.EJ_Util_transit = pd.DataFrame()
        self.EJ_Util_NM = pd.DataFrame()
        self.EJ_Util_autotime = pd.DataFrame()
        self.EJ_Util_transittime = pd.DataFrame()
        self.EJ_Util_NMtime = pd.DataFrame()
        self.EJ_Util_transitWalkshed = pd.DataFrame()

        self.skim_dfs_tours = dict()
        self.skim_dfs = dict()
        

    def reset_omx_zone_mapping(self, omx_file_dir: str) -> str:
        """
        reorder the index in an omx file to be in ascending order, since the original index might be out of order.

        Input: omx file directory
        Returns: omx file directory with the new index
        """

        omx_file = omx.open_file(omx_file_dir, 'r')
        reset_omx_file = omx.open_file(omx_file_dir.replace('.omx', '_mappingreset.omx'), 'w')

        mapping_name = omx_file.list_mappings()[1]
        zone_mapping = omx_file.mapping(mapping_name)
        zones = list(zone_mapping.keys())
        zones_sorted = sorted(zones)
        pos = [zones.index(zone) for zone in zones_sorted]

        for core in omx_file.list_matrices():
            data = omx_file[core]
            data = data[pos,:][:,pos]
            reset_omx_file[core] = data

        reset_omx_file.create_mapping('ZoneID', zones_sorted)

        omx_file.close()
        reset_omx_file.close()

        return omx_file_dir.replace('.omx', '_mappingreset.omx')
    
    def transit_maz_level_access_times(self) -> pd.DataFrame:

        print('   Creating dataframe of maz level access/egress times')
        self.log.write('   Creating dataframe of maz level access/egress times\n')

        origin = np.repeat(self.land_use_maz[self.land_use_maz.AE_LOCAL<0.85].index,self.land_use_maz[self.land_use_maz.AE_LOCAL<0.85].shape[0]) 
        dest = np.tile(self.land_use_maz[self.land_use_maz.AE_LOCAL<0.85].index,self.land_use_maz[self.land_use_maz.AE_LOCAL<0.85].shape[0])

        df = pd.DataFrame({'origin': origin, 'destination': dest})
        df = pd.merge(df, self.land_use_maz['taz_id'], left_on='origin', right_index=True, how='left')
        df = df.rename(columns={'taz_id':'origin_taz'})

        df = pd.merge(df, self.land_use_maz['taz_id'], left_on='destination', right_index=True, how='left')
        df = df.rename(columns={'taz_id':'destination_taz'})

        df = pd.merge(df, self.land_use_maz['AE_LOCAL'], left_on='origin', right_index=True, how='left')
        df = df.rename(columns={'AE_LOCAL':'origin_AE_LOCAL'})

        df = pd.merge(df, self.land_use_maz['AE_LOCAL'], left_on='destination', right_index=True, how='left')
        df = df.rename(columns={'AE_LOCAL':'destination_AE_LOCAL'})

        df['access_egress_time'] = (df.origin_AE_LOCAL + df.destination_AE_LOCAL)/3*60
        df.drop(['origin_AE_LOCAL', 'destination_AE_LOCAL'], axis=1, inplace=True)

        return df

    def filter_skim_by_less_than_threshold(self, skim_period: str, mode: str, threshold: float) -> pd.DataFrame:
        """
        Filter skim data by a threshold value. 
        
        Input: skim table as numpy array, threshold value
        Returns: a dataframe with two columns: origin, and destinations whose skim values are less than the threshold
        
        """
        print(f'Filtering skim data by {threshold} minutes for {mode} mode in the {skim_period} period')
        self.log.write(f'Filtering skim data by {threshold} minutes for {mode} mode in the {skim_period} period\n')

        assert mode in ['auto', 'transit', 'non-motorized'], "mode must be either auto or transit"
        assert skim_period in ['EA', 'AM', 'MD', 'PM', 'EV', None], "skim_period must be either EA, AM, MD, PM, EV"
        
        if mode == 'auto':
            #TODO use a "with" clause for opening files
            skims = omx.open_file(_join(self.output, 'skims', 'skims.omx'))
            skim_data = np.array(skims[f'SOV_TIME__{skim_period}'])
            skims.close()

            result = np.where((0 < skim_data) & (skim_data <= threshold))
            df = pd.DataFrame({'origin': result[0], 'destination': result[1]})
            #FIXME the below doesn't take advantage of the omx mapping objects
            df['origin'] = df['origin'] + 1
            df['destination'] = df['destination'] + 1

        elif mode == 'transit':
            if f'{mode}|{skim_period}' in self.skim_dfs:
                df = self.skim_dfs[f'{mode}|{skim_period}']
            else:
                #only run if we do not have the reset version of the file
                if ~os.path.exists(_join(self.output, 'skims', f'{skim_period}_WLK_All_Skim.omx')):
                    reset_skim_dir = self.reset_omx_zone_mapping(_join(self.output, 'skims', f'{skim_period}_WLK_All_Skim.omx'))
                else:
                    reset_skim_dir = _join(self.output, 'skims', f'{skim_period}_WLK_All_Skim_mappingreset.omx')

                skims = omx.open_file(reset_skim_dir)
                #access/egress times are maz_level: 1st step is to sum taz_level times. the maz transit time is the sum of the taz transit time and maz access/egress times
                skim_data = np.array(skims["Initial Wait Time"]) + np.array(skims["In-Vehicle Time"]) \
                    + np.array(skims["Transfer Wait Time"]) + np.array(skims["Transfer Walk Time"]) + np.array(skims["Dwelling Time"])
                
                skim_mapping = skims.mapping('ZoneID')
                skims.close()

                #construct a pd dataframe from skims array
                taz_level_skim_data = pd.DataFrame(skim_data, index=skim_mapping, columns=skim_mapping)
                taz_level_skim_data = taz_level_skim_data.stack().reset_index()
                taz_level_skim_data.columns = ['origin_taz', 'destination_taz', 'taz_transit_time']
                #bring in access/egress times at the maz level
                df = pd.merge(self.maz_access_times, taz_level_skim_data, on=['origin_taz', 'destination_taz'], how='left')
                df['total_transit_time'] = df['access_egress_time'] + df['taz_transit_time']
                self.skim_dfs[f'{mode}|{skim_period}'] = df

            df = df.loc[df.total_transit_time <= threshold, ['origin', 'destination']]

        else:
            df = self.maz_bike_skims[['origin', 'destination']]

        return df
    
    def join_taz_landuse_data_to_filtered_skim(self, df: pd.DataFrame, land_use_data: pd.DataFrame, col_to_join: str) -> pd.DataFrame:
        """
        Join land use data (usually a column of interest in there) to skim data. 
        
        Input: filtered skim data by threshold as dataframe, land use data as dataframe, land use column name to join 
        Returns: a dataframe with skim data and land use data variable (e.g. total_employment) joined on the key (destination zone)
        
        """
        print(f'Joining land use data to skim data for {col_to_join}')
        self.log.write(f'Joining land use data to skim data for {col_to_join}\n')

        df = df.merge(land_use_data[['zoneid', col_to_join]], left_on='destination', right_on='zoneid', how='left').drop('zoneid', axis=1)
        
        return df
    
    def join_maz_landuse_data_to_filtered_skim(self, df: pd.DataFrame, maz_land_use_data: pd.DataFrame, col_to_join: str) -> pd.DataFrame:

        print(f'Joining maz level land use data to skim data for {col_to_join}')
        self.log.write(f'Joining maz level land use data to skim data for {col_to_join}\n')

        df = df.merge(maz_land_use_data[col_to_join], left_on='destination', right_index=True, how='left')
        
        return df
    
    def create_maz_level_destination_measures(self, maz_level_landuse_shapefile: pd.DataFrame, taz_level_destination: pd.DataFrame) -> pd.DataFrame:

        print('   Creating maz level destination measures')
        self.log.write('   Creating maz level destination measures\n')


        maz_level_landuse_shapefile['maz_area'] = maz_level_landuse_shapefile['geometry'].area
        taz_area = maz_level_landuse_shapefile.groupby('TAZ_ID')['maz_area'].sum().reset_index().rename(columns={'maz_area':'TAZ_area'})

        MAZ_shap = pd.merge(maz_level_landuse_shapefile, taz_area, on='TAZ_ID', how='left')
        MAZ_shap['maz_area_share'] = MAZ_shap['maz_area']/MAZ_shap['TAZ_area']
        maz_area_share_of_taz = MAZ_shap[['MAZ_SEQID','TAZ_ID', 'maz_area_share']].rename(columns={'MAZ_SEQID':'maz_id', 'TAZ_ID':'taz_id'})

        maz_level_destination = pd.merge(maz_area_share_of_taz, taz_level_destination, left_on='taz_id', right_on='zoneid', how='left')

        for cols in taz_level_destination:
            if cols not in ['zoneid', 'County']:
                maz_level_destination[cols] = maz_level_destination[cols]*maz_level_destination['maz_area_share']

        return maz_level_destination
    
    def aggregate_data(self, df: pd.DataFrame, groupby_var: str, col_to_agg: str, agg_type: str) -> pd.DataFrame:
        """
        Aggregate data by origin. 
        
        Input: dataframe of skim data and land use data joined on the column name, column name to groupby, column name to aggregate, aggregate type e.g. sum
        Returns: a dataframe with skim data and land use data aggregated by groupby_var
        """
        print(f'Aggregating {col_to_agg} by {groupby_var}')
        self.log.write(f'Aggregating {col_to_agg} by {groupby_var}\n')

        df = df.groupby(groupby_var).agg({col_to_agg: agg_type}).reset_index().set_index(groupby_var)
        
        return df
    
    def find_group_count_by_taz(self, df: pd.DataFrame, condition: str, group_by_var: str) -> pd.DataFrame:
        """
        find the number of people in each group (e.g. minority) by TAZ or maz_id.

        Input: dataframe of persons, condition defining the group, group by variable (e.g. TAZ, maz_id)
        Returns: a dataframe with groupby variable (e.g. TAZ) and count of people in that group by TAZ
        """

        print(f'Finding group count defined as {condition} by {group_by_var}')
        self.log.write(f'Finding group count defined as {condition} by {group_by_var}\n')

        if condition is np.nan:
            condition = 'person_id > 0'
    
        group = df.query(condition).groupby(group_by_var).size().reset_index().sort_values(by=group_by_var).rename(columns={0: 'Count'})
        #add the missing TAZs
        missing_taz = [x for x in range(1,self.taz_count+1) if x not in group[group_by_var].to_list()]
        missing_taz_df = pd.DataFrame({group_by_var: missing_taz, 'Count': 0})
        group = pd.concat([group, missing_taz_df]).sort_values(group_by_var).set_index(group_by_var)

        return group
    
    def percent_population_witihin_threshold(self, skim_period: str, mode: str, group_definition: str, measure: str, threshold: float, group_name: str) -> pd.DataFrame:
        """
        Use previously defined function to find the percent of a population group living within a threshold of a measure (e.g. total employment)

        Input: skim period (e.g. AM), mode (e.g. auto), group definition (e.g. income <25000), measure (e.g. total employment), threshold (e.g. 30)
        Returns: a dataframe with group definition and percent of population of that group living within the threshold
        """
        print('\n')
        print(f'-- Computing {measure} for {group_definition} using {mode} mode in the {skim_period} period')
        self.log.write(f'-- Computing {measure} for {group_definition} using {mode} mode in the {skim_period} period\n')

        if pd.isnull(group_definition):
            group_definition = 'person_id > 0'

        if mode == 'auto':
            filtered_skim = self.filter_skim_by_less_than_threshold(skim_period, mode, threshold)

            filtered_skim_with_landuse = self.join_taz_landuse_data_to_filtered_skim(filtered_skim, self.destination, measure)
            agg_filtered_skim_with_landuse = self.aggregate_data(filtered_skim_with_landuse, 'origin', measure, 'sum')
            group_shares_by_taz = self.find_group_count_by_taz(self.persons_df, group_definition, 'TAZ')

            agg_filtered_skim_with_landuse[measure + '_'] =  np.where(agg_filtered_skim_with_landuse[measure] > 0, 1, 0)

            group_measure_stats = agg_filtered_skim_with_landuse[measure + '_'] * group_shares_by_taz['Count']
            percent_population = group_measure_stats.sum() / group_shares_by_taz['Count'].sum() * 100

            self.EJ_Util_auto.loc[group_name, f'Average {measure}'] = np.round(percent_population,1)
            return self.EJ_Util_auto
        
        elif mode == 'transit':
            filtered_skim = self.filter_skim_by_less_than_threshold(skim_period, mode, threshold)
            filtered_skim_with_landuse = self.join_maz_landuse_data_to_filtered_skim(filtered_skim, self.maz_level_destination, measure)
            agg_filtered_skim_with_landuse = self.aggregate_data(filtered_skim_with_landuse, 'origin', measure, 'sum')
            group_shares_by_maz = self.find_group_count_by_taz(self.persons_df, group_definition, 'maz_id')

            agg_filtered_skim_with_landuse[measure + '_'] =  np.where(agg_filtered_skim_with_landuse[measure] > 0, 1, 0)

            group_measure_stats = agg_filtered_skim_with_landuse[measure + '_'] * group_shares_by_maz['Count']
            percent_population = group_measure_stats.sum() / group_shares_by_maz['Count'].sum() * 100

            self.EJ_Util_transit.loc[group_name, f'Average {measure}'] = np.round(percent_population,1)
            return self.EJ_Util_transit
        
        else:
            filtered_skim = self.filter_skim_by_less_than_threshold(skim_period, mode, threshold)
            filtered_skim_with_landuse = self.join_maz_landuse_data_to_filtered_skim(filtered_skim, self.maz_level_destination, measure)
            agg_filtered_skim_with_landuse = self.aggregate_data(filtered_skim_with_landuse, 'origin', measure, 'sum')
            group_shares_by_maz = self.find_group_count_by_taz(self.persons_df, group_definition, 'maz_id')

            agg_filtered_skim_with_landuse[measure + '_'] =  np.where(agg_filtered_skim_with_landuse[measure] > 0, 1, 0)

            group_measure_stats = agg_filtered_skim_with_landuse[measure + '_'] * group_shares_by_maz['Count']
            percent_population = group_measure_stats.sum() / group_shares_by_maz['Count'].sum() * 100

            self.EJ_Util_NM.loc[group_name, f'Average {measure}'] = np.round(percent_population,1)
            return self.EJ_Util_NM
        
    def find_population_within_transit_walkshed(self, group_definition: str, group_name: str) -> pd.DataFrame:

        print('\n')
        print(f'-- Computing population within transit walkshed for {group_definition}')
        self.log.write(f'-- Computing population within transit walkshed for {group_definition}')

        if pd.isnull(group_definition):
            group_definition = 'person_id > 0'

        print(group_definition)

        mazs_withing_transit_walkshed = self.land_use_maz[(self.land_use_maz.AE_LOCAL<0.85) | (self.land_use_maz.AE_PRM<1.2)]

        persons_withn_transitWalkshed = self.persons_df[(self.persons_df.maz_id.isin(mazs_withing_transit_walkshed.index))]

        percent_group_living_within_transitWalkshed = persons_withn_transitWalkshed.query(group_definition).shape[0]/self.persons_df.query(group_definition).shape[0]*100

        self.EJ_Util_transitWalkshed.loc[group_name, 'Percent Population'] = np.round(percent_group_living_within_transitWalkshed,1)

        return self.EJ_Util_transitWalkshed

    def compute_accessibility(self, skim_period: str, mode: str, group_definition: str, measure: str, threshold: float, group_name: str) -> pd.DataFrame:
        """
        Use previously defined function to find the average of a measure (e.g. total employment) within a threshold of a measure

        Input: skim period (e.g. AM), mode (e.g. auto), group definition (e.g. income <25000), measure (e.g. total employment), threshold (e.g. 30)
        Returns: a dataframe with group definition and the avrage number of that measure accessible to a member of the group within the threshold

        """
        print('\n')
        print(f'-- Computing accessibility for {measure} for {group_definition} using {mode} mode in the {skim_period} period')
        self.log.write(f'-- Computing accessibility for {measure} for {group_definition} using {mode} mode in the {skim_period} period')

        if pd.isnull(group_definition):
            group_definition = 'person_id > 0'

        if mode == 'auto':
            filtered_skim = self.filter_skim_by_less_than_threshold(skim_period, mode, threshold)

            if measure == 'tot_emp':
                filtered_skim_with_landuse = self.join_taz_landuse_data_to_filtered_skim(filtered_skim, self.land_use_taz, measure)
            else:
                filtered_skim_with_landuse = self.join_taz_landuse_data_to_filtered_skim(filtered_skim, self.destination, measure)

            agg_filtered_skim_with_landuse = self.aggregate_data(filtered_skim_with_landuse, 'origin', measure, 'sum')
            group_shares_by_taz = self.find_group_count_by_taz(self.persons_df, group_definition, 'TAZ')
            
            group_measure_stats = agg_filtered_skim_with_landuse[measure] * group_shares_by_taz['Count']
            avg_opportunity = group_measure_stats.sum() / group_shares_by_taz['Count'].sum()

            self.EJ_Util_auto.loc[group_name, f'Average {measure}'] = int(avg_opportunity)
            return self.EJ_Util_auto
        
        elif mode == 'transit':
            filtered_skim = self.filter_skim_by_less_than_threshold(skim_period, mode, threshold)

            if measure == 'tot_emp':
                filtered_skim_with_landuse = self.join_maz_landuse_data_to_filtered_skim(filtered_skim, self.land_use_maz, measure)
            else:
                filtered_skim_with_landuse = self.join_maz_landuse_data_to_filtered_skim(filtered_skim, self.maz_level_destination, measure)

            agg_filtered_skim_with_landuse = self.aggregate_data(filtered_skim_with_landuse, 'origin', measure, 'sum')
            group_shares_by_maz = self.find_group_count_by_taz(self.persons_df, group_definition, 'maz_id')
            
            group_measure_stats = agg_filtered_skim_with_landuse[measure] * group_shares_by_maz['Count']
            avg_opportunity = group_measure_stats.sum() / group_shares_by_maz['Count'].sum()

            self.EJ_Util_transit.loc[group_name, f'Average {measure}'] = int(avg_opportunity)
            return self.EJ_Util_transit
        
        else:
            filtered_skim = self.filter_skim_by_less_than_threshold(skim_period, mode, threshold)

            if measure == 'tot_emp':
                filtered_skim_with_landuse = self.join_maz_landuse_data_to_filtered_skim(filtered_skim, self.land_use_maz, measure)
            else:
                filtered_skim_with_landuse = self.join_maz_landuse_data_to_filtered_skim(filtered_skim, self.maz_level_destination, measure)

            agg_filtered_skim_with_landuse = self.aggregate_data(filtered_skim_with_landuse, 'origin', measure, 'sum')
            group_shares_by_maz = self.find_group_count_by_taz(self.persons_df, group_definition, 'maz_id')
            
            group_measure_stats = agg_filtered_skim_with_landuse[measure] * group_shares_by_maz['Count']
            avg_opportunity = group_measure_stats.sum() / group_shares_by_maz['Count'].sum()

            
            self.EJ_Util_NM.loc[group_name, f'Average {measure}'] = int(avg_opportunity)
            return self.EJ_Util_NM
        
    def filter_trips_by_purpose(self,purposes:list) -> pd.DataFrame:
        """
        Filter the trip table by a specific set of purposes

        Inputs: A trip purpose list (e.g. work) for which trips must be taken to be included
        Output: The filtered trip dataframe, all of whose trips are for the given purpose(s)
        """
        return self.trips[((self.trips.purpose.isin(purposes)) if purposes else (self.trips.purpose != None))]
    
    def filter_tours_by_purpose(self,purposes:list) -> pd.DataFrame:
        """
        Filter the tour table by a specific set of trip purposes

        Inputs: A tour purpose list (e.g. work) for which trips must be taken to be included
        Output: The filtered tour dataframe, all of whose tours are for the given purpose(s)
        """
        return self.tours_wSkims[((self.tours_wSkims.primary_purpose.isin(purposes)) if purposes else (self.tours_wSkims.primary_purpose != None))]
    
        """
        Find the average trip duration for all trips for a specific demographic for a specific purpose

        Input: skim period (e.g. AM), mode (e.g. auto), group definition (e.g. income <25000), trip purpose (e.g. work)
        Output: a float value representing the mean trip length for all trips meeting the specified conditions
        """
        assert mode in ['auto', 'transit'], "mode must be either auto or transit"
        assert skim_period in ['EA', 'AM', 'MD', 'PM', 'EV'], "skim_period must be either EA, AM, MD, PM, EV"

        with omx.open_file(_join(self.output,'skims','skims.omx')) as skims:
            if mode == 'auto':
                skim_data = skims[f'SOV_TIME__{skim_period}']
                modes = ['DRIVEALONE','SHARED2','SHARED3']
            elif mode =='transit':
                raise NotImplementedError()
                
            tazs = skims.mapping('ZoneID')
            #TODO cut columns out to reduce memory footprint
            trips = self.filter_trips_by_purpose(purposes)
            trips = self.filter_trips_by_modes(trips,modes)
            trips = self.filter_by_traveler(trips,group_definition)
            trips = self.join_orig_dest_maz_taz_map(trips)

            #Summarize the number of trips between each O-D pair
            trips = trips.value_counts(subset=['orig','dest']).reset_index(name='trip_count')
            
            #Attach the correct skim data - FIXME this doesn't use the method that stores it in DataFrames
            trips['trip_length'] = trips.apply(lambda trip: skim_data[tazs[trip.orig]][tazs[trip.dest_taz]],axis=1)
            
            #Take the dot product of trip count and trip length, then divide by number of trips
            return trips.apply(lambda pair: pair['trip_count'] * pair['trip_length'],axis=1).sum()/trips['trip_count'].sum()
    
    def get_multi_mode_multi_period_skim_data(self,skim_periods: list, modes: list) -> pd.DataFrame:
        """
        Retrieve a DataFrame that contains the origin/destination data and travel time skims for
        a defined set of skim periods and modes. This method combines skims into a doubly-indexed
        DataFrame where the first column index level is the mode and the second is the time period.
        The origin and destination columns have an empty string as the second layer column label.
        
        Inputs: A list of skim period strings and a list of mode strings (in ActivitySim label format)
        Output: A doubly-column-indexed DataFrame containing all skim data for the given modes and times
        """

        print(f'   Retrieving {modes} skim data for {skim_periods} periods')
        skim_data = pd.concat({mode: self.get_multi_period_skim_data(skim_periods,mode).set_index(['orig','dest']) for mode in modes},axis=1)
        skim_data.reset_index(inplace=True)
        return skim_data

    def get_multi_period_skim_data(self, skim_periods: list, mode: str):
        """
        Retrieve, for a mode and list of skim periods, the associated travel time skim as a DataFrame

        Inputs: string representations of the skim periods (in a list, e.g. AM, MD) and the mode (e.g. auto, transit)
        Output: a DataFrame with correct TAZ indexing that provides travel time between each TAZ pair
                for the given mode. Note the auto mode provide the single-occupancy travel time and 
                transit mode gives the sum of the initial wait, in-vehicle, transfer wait, transfer walk,
                and dwelling times.
        """
        skim_data = pd.concat({skim_period:self.get_single_skim_data(skim_period,mode).set_index(['orig','dest']) for skim_period in skim_periods}, axis=1)
        skim_data.columns=skim_data.columns.droplevel(-1)
        skim_data.reset_index(inplace=True)
        return skim_data

    def get_single_skim_data(self, skim_period: str, mode: str) -> pd.DataFrame:
        """
        Retrieve, for a mode and skim period, the associated travel time skim as a DataFrame

        Inputs: string representations of the skim period (e.g. AM, MD) and the mode (e.g. auto, transit)
        Output: a DataFrame with correct TAZ indexing that provides travel time between each TAZ pair
                for the given mode. Note the auto mode provide the single-occupancy travel time and 
                transit mode gives the sum of the initial wait, in-vehicle, transfer wait, transfer walk,
                and dwelling times.
        """
        #get the correct skim based on tour mode
        skim_mode = self.skim_label(mode)

        if f"{skim_mode}|{skim_period}" in self.skim_dfs_tours:
            # print(f'   Retrieving skim {skim_mode}|{skim_period} data from memory')
            return self.skim_dfs_tours[f"{skim_mode}|{skim_period}"]

        with omx.open_file(_join(self.output,'skims','skims.omx')) as skims:
                #Only include driving time
                
                if skim_mode in ['SOV','HOV2','HOV3']:
                    df = pd.DataFrame(skims[f'{skim_mode}_TIME__{skim_period}'], index=skims.mapping('ZoneID'), columns=skims.mapping('ZoneID'))
                
                #Sum the components of kiss-/park-and-ride trips
                elif skim_mode in ['KNR_LOC','KNR_MIX','KNR_PRM','PNR_LOC','PNR_MIX','PNR_PRM']:
                    skim =  np.array(skims[f"{skim_mode}_DTIME__{skim_period}"]) +\
                            np.array(skims[f"{skim_mode}_DT__{skim_period}"]) +\
                            np.array(skims[f"{skim_mode}_IWAIT__{skim_period}"]) +\
                            np.array(skims[f"{skim_mode}_IVT__{skim_period}"]) +\
                            np.array(skims[f"{skim_mode}_WEGR__{skim_period}"]) +\
                            np.array(skims[f"{skim_mode}_WAUX__{skim_period}"]) +\
                            np.array(skims[f"{skim_mode}_XWAIT__{skim_period}"]) +\
                            np.array(skims[f"{skim_mode}_WACC__{skim_period}"])
                    
                    df = pd.DataFrame(skim, index=skims.mapping('ZoneID'), columns=skims.mapping('ZoneID'))
                    
                
                #Same as above for walking, but omits the driving time and adds maz level access/egress times later
                elif skim_mode in ['WLK_LOC','WLK_MIX','WLK_PRM']:
                    skim =  np.array(skims[f"{skim_mode}_DT__{skim_period}"]) +\
                            np.array(skims[f"{skim_mode}_IWAIT__{skim_period}"]) +\
                            np.array(skims[f"{skim_mode}_IVT__{skim_period}"]) +\
                            np.array(skims[f"{skim_mode}_WAUX__{skim_period}"]) +\
                            np.array(skims[f"{skim_mode}_XWAIT__{skim_period}"])
                    
                    df = pd.DataFrame(skim, index=skims.mapping('ZoneID'), columns=skims.mapping('ZoneID'))
                
                skim_data = df.stack().rename('travel_time')
                skim_data.index.rename(['orig','dest'],inplace=True)
                skim_data = skim_data.reset_index()
                skim_data.columns = ['orig','dest','travel_time']


        self.skim_dfs_tours[f"{skim_mode}|{skim_period}"] = skim_data
        return skim_data

    def join_orig_dest_maz_taz_map(self,df: pd.DataFrame) -> pd.DataFrame:
        """
        Attach the TAZ values for each trip or tour's origins and destinations

        Inputs: a dataframe with the columns 'origin' and 'destination' specifying the trips'/tours' respective start and end MAZs
        Outputs: the same dataframe with the added columns 'orig_taz' and 'dest_taz' specifying the TAZs of the trips
        """
        df = pd.merge(df,self.maz_taz_mapping,how='left',left_on='origin',right_on='MAZ').drop(columns='MAZ').rename(columns={'TAZ':'orig_taz'})
        df = pd.merge(df,self.maz_taz_mapping,how='left',left_on='destination',right_on='MAZ').drop(columns='MAZ').rename(columns={'TAZ':'dest_taz'})
        return df
    
    def filter_by_traveler(self, df:pd.DataFrame, condition:str) -> pd.DataFrame:
        """
        Filter persons table according to a provided condition and join to a table with person_id defined

        Inputs: a dataframe with a 'person_id' column, and a condition query by which to filter persons
        Output: the initial dataframe inner joined to the filtered persons table

        """

        person_df = self.persons_df.query(condition).drop(columns=['TAZ'])

        # x = df.join(person_df,on='person_id',how='inner',rsuffix='_pers')       

        return df[df.person_id.isin(person_df.person_id)]
    
    def filter_trips_by_modes(self, df: pd.DataFrame, included_modes:list) -> pd.DataFrame:
        """
        Filter a DataFrame of trips based on the trip mode, keeping only those in the
        provided list

        Inputs: a DataFrame of trips including the 'trip_mode' column, and a list of
                allowed modes
        Output: the DataFrame with all non-allowed trips removed
        """
        return df[df.trip_mode.isin(included_modes)]
    
    def filter_tours_by_modes(self, df: pd.DataFrame, included_modes:list) -> pd.DataFrame:
        """
        Filter a DataFrame of tour based on the tour mode, keeping only those in the
        provided list

        Inputs: a DataFrame of trips including the 'tour_mode' column, and a list of
                allowed modes
        Output: the DataFrame with all non-allowed tours removed
        """
        return df[df.tour_mode.isin(included_modes)]

    def map_departure_to_time_period(self, departure_time:float):
        """
        Map the departure time bin value into a time period string

        Inputs: a single departure time bin as a float
        Output: a string representation of the time period in which the trip occcurs
        """
        if departure_time < 0: return None
        return           'EA' if departure_time <= 6 \
                    else 'AM' if departure_time <= 12 \
                    else 'MD' if departure_time <= 24 \
                    else 'PM' if departure_time <= 32 \
                    else 'EV' if departure_time <= 48 \
                    else None
    
    def assign_periods(self, tours: pd.DataFrame) -> pd.DataFrame:
        tours['period'] = np.where(tours['start']<=6, 'EA', 0)
        tours['period'] = np.where((tours['start']>=7) & (tours['start']<=12), 'AM', tours['period'])
        tours['period'] = np.where((tours['start']>=13) & (tours['start']<=24), 'MD', tours['period'])
        tours['period'] = np.where((tours['start']>=25) & (tours['start']<=32), 'PM', tours['period'])
        tours['period'] = np.where((tours['start']>=33) & (tours['start']<=48), 'EV', tours['period'])
    
        return tours
    
    def skim_label(self, mode_label: str) -> str:
        """
        Map an ActivitySim mode label to the corresponding skim mode label

        Inputs: an ActivitySim-type mode label
        Output: the corresponding mode label used in skims' names
        """
        mapping = {
            'DRIVEALONE':'SOV',
            'SHARED2':'HOV2',
            'SHARED3':'HOV3',
            'TNC_SHARED':'HOV3',
            'TNC_SINGLE':'HOV2',
            'WALK_LOC':'WLK_LOC',
            'WALK_MIX':'WLK_MIX',
            'WALK_PRM':'WLK_PRM',
            'KNR_LOC':'KNR_LOC',
            'KNR_MIX':'KNR_MIX',
            'KNR_PRM':'KNR_PRM',
            'PNR_PRM':'PNR_PRM',
            'PNR_LOC':'PNR_LOC',
            'PNR_MIX':'PNR_MIX'
                   }
        return mapping[mode_label]

    def mean_tour_length(self, mode:str, group_definition:str, purposes: list, group_name: str) -> float:
        """
        Find the average tour duration for all tours for a specific demographic for a specific purpose

        Input: available skim periods as a list (e.g. AM), string representations of the mode (e.g. auto), 
                group definition (e.g. income <25000), and a list of trip purposes (e.g. work)
        Output: a float value representing the mean tour length for all tours meeting the specified conditions
        """
        print('\n')
        print(f'-- Computing tour length for {group_definition} using {mode} mode and for purposes {purposes}')
        self.log.write(f'-- Computing tour length for {group_definition} using {mode} mode and for purposes {purposes}\n')

        assert mode in ['auto', 'transit', 'non-motorized'], "mode must be either auto, transit, or non-motorized"

        if pd.isnull(group_definition):
            group_definition = 'person_id > 0'

        if mode == 'auto':
            included_modes = ['DRIVEALONE','SHARED2','SHARED3']
        elif mode == 'transit':
            included_modes = ['WALK_LOC', 'WALK_PRM','WALK_MIX', 
                              'PNR_LOC','PNR_PRM', 'PNR_MIX',
                              'KNR_LOC', 'KNR_PRM', 'KNR_MIX']
        else:
            included_modes = ['WALK', 'BIKE']

        print(f'   Filtering tours by purposes {purposes}, modes {included_modes}, and group definition {group_definition}')
        #Filter down to just the trips we're seeking based on purpose, mode of travel, and traveler demographics
        tours = self.filter_tours_by_purpose(purposes)[['person_id','tour_id','origin','destination','tour_mode','start','primary_purpose', 'AUTO_TIME', 'transit_time']]
        tours = self.filter_tours_by_modes(tours, included_modes)
        tours = self.filter_by_traveler(tours,group_definition)[['tour_id','origin','destination','start','tour_mode','primary_purpose','AUTO_TIME', 'transit_time']]

        if mode == 'non-motorized':
            # bike_skims = pd.DataFrame()
            bike_skims = self.maz_bike_skims.copy()
            bike_skims.columns = ['origin', 'destination', 'travel_dist_bike']
            bike_skims['travel_time_bike'] = bike_skims['travel_dist_bike']/12*60
            # walk_skims = pd.DataFrame()
            walk_skims = self.maz_walk_skims.copy()
            walk_skims.columns = ['origin', 'destination', 'travel_dist_walk']
            walk_skims['travel_time_walk'] = walk_skims['travel_dist_walk']/3*60

            tours = tours.merge(bike_skims, on=['origin', 'destination'], how='left').fillna(0)
            tours = tours.merge(walk_skims, on=['origin', 'destination'], how='left').fillna(0)

            tours['travel_time'] = np.where(tours.tour_mode == 'WALK', tours['travel_time_walk'], tours['travel_time_bike'])
            # tours.to_csv(_join(self.output, f'tours{group_name}.csv'))

            self.EJ_Util_NMtime.loc[group_name, str(purposes)] = np.round(tours.travel_time.mean(),1)

        else:
            if mode == 'transit':
                self.EJ_Util_transittime.loc[group_name, str(purposes)] = np.round(tours.transit_time.mean(),1)
            else:
                self.EJ_Util_autotime.loc[group_name, str(purposes)] = np.round(tours.AUTO_TIME.mean(),1)
                
        return None
    
    def attach_skims(self) -> pd.DataFrame:
        #Retrieve skims and attach travel time data to the tour table

        print('   Retrieving skims')
        self.log.write('   Retrieving skims\n')

        self.tours =pd.merge(self.tours, self.maz_taz_mapping, left_on='origin', right_on='MAZ').rename(columns={'TAZ':'origin_taz'}).drop(columns='MAZ')
        self.tours =pd.merge(self.tours, self.maz_taz_mapping, left_on='destination', right_on='MAZ').rename(columns={'TAZ':'dest_taz'}).drop(columns='MAZ')

        tours = self.assign_periods(self.tours)
        auto_tours = self.tours[self.tours['tour_mode'].isin(['DRIVEALONE', 'SHARED2', 'SHARED3', 'TAXI', 'TNC_SINGLE', 'TNC_SHARED'])]
        transit_tours = self.tours[self.tours['tour_mode'].isin(['WALK_LOC', 'WALK_PRM', 'WALK_MIX', 'PNR_LOC', 'PNR_PRM', 'PNR_MIX', 'KNR_LOC', 'KNR_PRM', 'KNR_MIX'])] #transit is not in these modes
        other_tours = self.tours[self.tours['tour_mode'].isin(['WALK', 'BIKE', 'SCHOOLBUS'])]

        #auto modes
        auto_modes = ['SOV', 'HOV2', 'HOV3']

        #transit modes
        linehaul = ['LOC', 'PRM', 'MIX']
        access = ['WLK', 'PNR', 'KNR']

        with omx.open_file(_join(self.output,'skims','skims.omx'),'r') as skims:
            for core in ['TIME']:
                auto_tours.loc[:,'AUTO_'+core] = 0
                for period in self.skim_periods:
                    for mode in auto_modes:
                        
                        core_name = np.array(skims[mode+'_'+core+'__'+period])

                        if mode=='SOV':
                            tmode = 'DRIVEALONE'
                        elif mode=='HOV2':
                            tmode = 'SHARED2'
                        else:
                            tmode = 'SHARED3'

                        auto_tours.loc[:,'AUTO_'+core] = np.where((auto_tours['period']==period) & (auto_tours['tour_mode']==tmode), 
                                                                    core_name[auto_tours['origin_taz']-1, auto_tours['dest_taz']-1], 
                                                                        auto_tours['AUTO_'+core])
                        

        transit_cores = ['WACC', 'DTIME', 'IWAIT', 'IVT', 'XWAIT', 'DT', 'WEGR', 'WAUX']

        with omx.open_file(_join(self.output,'skims','skims.omx'),'r') as skims:
            for core in transit_cores:
                transit_tours.loc[:,'TRANSIT_'+core] = 0
                for period in self.skim_periods:
                    for acc in access:
                        if (core == 'DTIME' or core == 'DDIST') and acc == 'WLK':
                            continue
                        for line in linehaul:
                            core_name = acc+'_'+line+'_'+core
                            
                            core_name = np.array(skims[core_name+'__'+period])
                            
                            if acc=='WLK':
                                tacc = 'WALK'
                            else:
                                tacc = acc
                            
                            mode_name = tacc+'_'+line

                            transit_tours.loc[:,'TRANSIT_'+core] = np.where((transit_tours['period']==period) & (transit_tours['tour_mode']==mode_name), 
                                                                    core_name[transit_tours['origin_taz']-1, transit_tours['dest_taz']-1], 
                                                                        transit_tours['TRANSIT_'+core])
                            
            transit_tours.loc[:,'transit_time'] = np.where(transit_tours.tour_mode.isin(['WALK_LOC', 'WALK_PRM', 'WALK_MIX']),
                                                      transit_tours.TRANSIT_IWAIT+transit_tours.TRANSIT_IVT+transit_tours.TRANSIT_XWAIT+transit_tours.TRANSIT_WAUX+transit_tours.TRANSIT_DT,
                                                     transit_tours.TRANSIT_DTIME+transit_tours.TRANSIT_IWAIT+transit_tours.TRANSIT_IVT+transit_tours.TRANSIT_XWAIT+transit_tours.TRANSIT_WAUX+transit_tours.TRANSIT_WEGR+transit_tours.TRANSIT_DT)
                            
        transit_tours = pd.merge(self.maz_access_times, transit_tours, on=['origin', 'destination'], how='right').fillna(0)
        #add maz level access egress for walk 
        transit_tours.loc[:,'transit_time'] = np.where(transit_tours.primary_purpose.isin(['WALK_LOC', 'WALK_PRM','WALK_MIX']), transit_tours['access_egress_time'] + transit_tours['transit_time'], transit_tours['transit_time'])        
        
        tours_with_skims = pd.concat([auto_tours,transit_tours, other_tours], axis=0, ignore_index=True)

        assert tours.shape[0] == tours_with_skims.shape[0], 'problem in concat'

        return tours_with_skims


# %%
if __name__ == '__main__':
    ejUtility = EJUtility(engine='pyarrow')

# %%
#TODO: construct a dict of period, mode, group definition, measure, threshold so we onlyhave one line of code after for loop
start_time = datetime.datetime.now()

for i in range(ejUtility.configs.shape[0]):
    try:
        group_def = ejUtility.configs.loc[i, 'GroupDef']
        group_name = ejUtility.configs.loc[i, 'GroupName']

        transitWalkshed = ejUtility.find_population_within_transit_walkshed(group_definition = group_def, group_name = group_name)

        jobs_auto = ejUtility.compute_accessibility(skim_period = 'AM', mode = 'auto', group_definition = group_def, measure = 'tot_emp', threshold = 25, group_name = group_name)
        jobs_transit = ejUtility.compute_accessibility(skim_period = 'AM', mode = 'transit', group_definition = group_def, measure = 'tot_emp', threshold = 50, group_name=group_name)
        jobs_nm = ejUtility.compute_accessibility(skim_period = None, mode = 'non-motorized', group_definition = group_def, measure = 'tot_emp', threshold = None, group_name = group_name)

        shopping_auto = ejUtility.compute_accessibility(skim_period = 'MD', mode = 'auto', group_definition = group_def, measure = 'N_ShopGrp1', threshold = 15, group_name = group_name)
        shopping_transit = ejUtility.compute_accessibility(skim_period = 'MD', mode = 'transit', group_definition = group_def, measure = 'N_ShopGrp1', threshold = 30, group_name = group_name)
        shopping_nm = ejUtility.compute_accessibility(skim_period = None, mode = 'non-motorized', group_definition = group_def, measure = 'N_ShopGrp1', threshold = None, group_name = group_name)
        
        non_shopping_auto = ejUtility.compute_accessibility(skim_period = 'MD', mode = 'auto', group_definition = group_def, measure = 'N_NonShopGrp1', threshold = 15, group_name = group_name)
        non_shopping_transit = ejUtility.compute_accessibility(skim_period = 'MD', mode = 'transit', group_definition = group_def, measure = 'N_NonShopGrp1', threshold = 30, group_name = group_name)
        non_shopping_nm = ejUtility.compute_accessibility(skim_period = None, mode = 'non-motorized', group_definition = group_def, measure = 'N_NonShopGrp1', threshold = None, group_name = group_name)

        school_auto = ejUtility.percent_population_witihin_threshold(skim_period = 'AM', mode = 'auto', group_definition = group_def, measure = 'N_CollegesGrp2', threshold = 25, group_name = group_name)
        school_transit = ejUtility.percent_population_witihin_threshold(skim_period = 'AM', mode = 'transit', group_definition = group_def, measure = 'N_CollegesGrp2', threshold = 50, group_name = group_name)
        school_nm = ejUtility.percent_population_witihin_threshold(skim_period = None, mode = 'non-motorized', group_definition = group_def, measure = 'N_CollegesGrp2', threshold = None, group_name = group_name)

        hospital_auto = ejUtility.percent_population_witihin_threshold(skim_period = 'MD', mode = 'auto', group_definition = group_def, measure = 'N_HospGrp2', threshold = 15, group_name = group_name)
        hospital_transit = ejUtility.percent_population_witihin_threshold(skim_period = 'MD', mode = 'transit', group_definition = group_def, measure = 'N_HospGrp2', threshold = 30, group_name = group_name)
        hospital_nm = ejUtility.percent_population_witihin_threshold(skim_period = None, mode = 'non-motorized', group_definition = group_def, measure = 'N_HospGrp2', threshold = None, group_name = group_name)

        MajRetail_auto = ejUtility.percent_population_witihin_threshold(skim_period = 'MD', mode = 'auto', group_definition = group_def, measure = 'N_MajRetailGrp2', threshold = 15, group_name = group_name)
        MajRetail_transit = ejUtility.percent_population_witihin_threshold(skim_period = 'MD', mode = 'transit', group_definition = group_def, measure = 'N_MajRetailGrp2', threshold = 30, group_name = group_name)
        MajRetail_nm = ejUtility.percent_population_witihin_threshold(skim_period = None, mode = 'non-motorized', group_definition = group_def, measure = 'N_MajRetailGrp2', threshold = None, group_name = group_name)
        

        mean_work_tour_auto = ejUtility.mean_tour_length(mode = 'auto', group_definition = group_def, purposes = ['work'], group_name = group_name)
        mean_work_tour_transit = ejUtility.mean_tour_length(mode = 'transit', group_definition = group_def, purposes = ['work'], group_name = group_name)
        mean_work_tour_nm = ejUtility.mean_tour_length(mode = 'non-motorized', group_definition = group_def, purposes = ['work'],group_name = group_name)

        mean_shop_tour_auto = ejUtility.mean_tour_length(mode = 'auto', group_definition = group_def, purposes = ['school', 'univ'],group_name = group_name)
        mean_shop_tour_transit = ejUtility.mean_tour_length(mode = 'transit', group_definition = group_def, purposes = ['school', 'univ'],group_name = group_name)
        mean_shop_tour_nm = ejUtility.mean_tour_length(mode = 'non-motorized', group_definition = group_def, purposes = ['school', 'univ'], group_name = group_name)

        mean_other_tour_auto = ejUtility.mean_tour_length(mode = 'auto', group_definition = group_def, purposes = ['shopping'],group_name = group_name)
        mean_other_tour_transit = ejUtility.mean_tour_length(mode = 'transit', group_definition = group_def, purposes = ['shopping'],group_name = group_name)
        mean_other_tour_nm = ejUtility.mean_tour_length(mode = 'non-motorized', group_definition = group_def, purposes = ['shopping'],group_name = group_name)

        mean_other_tour_auto = ejUtility.mean_tour_length(mode = 'auto', group_definition = group_def, purposes = ['escort','othmaint'],group_name = group_name)
        mean_other_tour_transit = ejUtility.mean_tour_length(mode = 'transit', group_definition = group_def, purposes = ['escort','othmaint'],group_name = group_name)
        mean_other_tour_nm = ejUtility.mean_tour_length(mode = 'non-motorized', group_definition = group_def, purposes = ['escort','othmaint'],group_name = group_name)

        mean_other_tour_auto = ejUtility.mean_tour_length(mode = 'auto', group_definition = group_def, purposes = ['social', 'eatout', 'othdiscr'],group_name = group_name)
        mean_other_tour_transit = ejUtility.mean_tour_length(mode = 'transit', group_definition = group_def, purposes = ['social', 'eatout', 'othdiscr'],group_name = group_name)
        mean_other_tour_nm = ejUtility.mean_tour_length(mode = 'non-motorized', group_definition = group_def, purposes = ['social', 'eatout', 'othdiscr'],group_name = group_name)

        mean_tour_auto = ejUtility.mean_tour_length(mode = 'auto', group_definition = group_def, purposes = None, group_name = group_name)
        mean_tour_transit = ejUtility.mean_tour_length(mode = 'transit', group_definition = group_def, purposes = None, group_name = group_name)
        mean_tour_nm = ejUtility.mean_tour_length(mode = 'non-motorized', group_definition = group_def, purposes = None, group_name = group_name)

        ejUtility.EJ_Util_auto.to_csv(_join(ejUtility.output, 'EJ', 'EJ_Util_auto.csv'), header=False)
        ejUtility.EJ_Util_transit.to_csv(_join(ejUtility.output, 'EJ', 'EJ_Util_transit.csv'), header=False)
        ejUtility.EJ_Util_NM.to_csv(_join(ejUtility.output, 'EJ', 'EJ_Util_NM.csv'), header=False)
        ejUtility.EJ_Util_NMtime.to_csv(_join(ejUtility.output, 'EJ', 'EJ_Util_NMtime.csv'), header=False)
        ejUtility.EJ_Util_autotime.to_csv(_join(ejUtility.output, 'EJ', 'EJ_Util_autotime.csv'), header=False)
        ejUtility.EJ_Util_transittime.to_csv(_join(ejUtility.output, 'EJ', 'EJ_Util_transittime.csv'), header=False)
        ejUtility.EJ_Util_transitWalkshed.to_csv(_join(ejUtility.output, 'EJ', 'EJ_Util_transitWalkshed.csv'), header=False)

    except Exception as e:
        traceback.print_exc(file=ejUtility.log)
        print('Error Encountered! Check log file for details.')
        # ejUtility.log.close()
        sys.exit(1)

end_time = datetime.datetime.now()
print('\n')
print(f'Time elapsed: {end_time - start_time}')
ejUtility.log.write(f'DONE! Time elapsed: {end_time - start_time}')
ejUtility.log.close()

