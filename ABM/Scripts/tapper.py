import pandas as pd

import warnings
warnings.filterwarnings('ignore')


def read_data(input_path):

    '''
    Read transit stops, routes and modes data from the planning level network
    '''

    stops = pd.read_csv(input_path+'/route_stops.csv')
    routes = pd.read_csv(input_path+'/route_lines.csv')

    return stops, routes


def merge_inputs(stops, routes):

    '''
    Merge transit stops, routes and modes data from the planning level network
    '''

    stops = pd.merge(stops, routes[['Route_ID', 'MODE_ID']], on = 'Route_ID', how = 'left')
    #stops = pd.merge(stops, modes[['MODE_ID', 'IS_PRM']], on = 'MODE_ID', how = 'left')

    return stops

def convert_coord(stops):

    '''
    Convert lat long to decimal units
    '''

    stops['Longitude'] = stops['Longitude']/1000000
    stops['Latitude'] = stops['Latitude']/1000000

    return stops

