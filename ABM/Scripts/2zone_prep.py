# %%
import sys
import os
import pandas as pd
import geopandas as gpd
import pandana as pdna
import numpy as np
import time
import tapper
import openmatrix as omx
import os
_join = os.path.join
# %%
print(time.ctime(), "Start")

output_dir = os.sys.argv[1]
landuse_dir = os.sys.argv[2]

cwd = os.getcwd()
os.chdir( cwd + "/ABM/Scripts")

stop_files = _join(output_dir,'WorkingFiles')
allstrt_link = _join(output_dir,'WorkingFiles','links_all.shp')
allstrt_node = _join(output_dir, 'WorkingFiles','nodes_all.shp')
mazfile_name = _join(output_dir, 'WorkingFiles','SEMCOG_MAZ.shp')
output_data = _join(output_dir,'skims')
transit_operator = _join(output_dir, 'WorkingFiles','transit_operator_list.csv')
# %%
print("--Read in Allstreet Network")
links = gpd.read_file(allstrt_link)
links = links.to_crs(epsg=26910)

links['ID'] = range(1,len(links)+1)

nodes = gpd.read_file(allstrt_node)
nodes = nodes.to_crs(epsg=26910)
nodes.set_index('ID', inplace= True)

nodes['X'], nodes['Y'] = nodes.geometry.x, nodes.geometry.y

# %%
print("--Construct pandanas network")
net = pdna.Network(nodes["X"], nodes["Y"], links["A_NODE"], links["B_NODE"], links[["LENGTH"]], twoway=True)
# %%
print("--Remove any disconnected nodes")
disconnected_nodes = net.low_connectivity_nodes(1600, 20)
print(f"List of disconnected nodes to be removed: {disconnected_nodes}")
nodex = nodes[~nodes.index.isin(disconnected_nodes)]
linkx = links[~((links.A_NODE.isin(disconnected_nodes)) | ((links.B_NODE.isin(disconnected_nodes))))]
netx = pdna.Network(nodex["X"], nodex["Y"], linkx["A_NODE"], linkx["B_NODE"], linkx[["LENGTH"]], twoway=True)

# %%
#read MAZ shapefile
print("--Read in MAZ Shapefile")
maz = gpd.read_file(mazfile_name)
reference_crs = maz.crs
maz = maz.to_crs(epsg=26910)

mazs=maz.copy()
mazs['geometry'] = mazs['geometry'].centroid

mazs['X'] = mazs['geometry'].x
mazs['Y'] = mazs['geometry'].y

# %%
#read in and process transit stops
print("--Read in Stops and Routes Data")
stops, routes = tapper.read_data(stop_files)

stops = tapper.merge_inputs(stops, routes)
stops = tapper.convert_coord(stops)

route_level = pd.read_csv(transit_operator)

# %%
#add route operator to determine local/premium status
routes['Route_ID'] = routes['Route_ID'].astype('int')
stops['Route_ID'] = stops['Route_ID'].astype('int')

stops = pd.merge(stops, route_level[['MODE_ID', 'IS_LOC']], how='left', on='MODE_ID')
stops['local'] = (stops['IS_LOC'] == 1).astype(int)

stops_gdf = gpd.GeoDataFrame(stops, geometry=gpd.points_from_xy(stops.Longitude, stops.Latitude), crs = {'init': 'epsg:4326'})
stops_gdf = stops_gdf.to_crs(epsg=26910)
stops_gdf['X'] = stops_gdf['geometry'].x
stops_gdf['Y'] = stops_gdf['geometry'].y

# %%
print("--Assign nearest network node to mazs and stops")

mazs["network_node_id"] = netx.get_node_ids(mazs["X"], mazs["Y"])
mazs["network_node_x"] = nodex["X"].loc[mazs["network_node_id"]].tolist()
mazs["network_node_y"] = nodex["Y"].loc[mazs["network_node_id"]].tolist()

stops_gdf["network_node_id"] = netx.get_node_ids(stops_gdf["X"], stops_gdf["Y"])
stops_gdf["network_node_x"] = nodex["X"].loc[stops_gdf["network_node_id"]].astype('float32').tolist()
stops_gdf["network_node_y"] = nodex["Y"].loc[stops_gdf["network_node_id"]].astype('float32').tolist()

# %%
#compute "connector distance" for mazs
mazs['connector_dist'] = (
    np.sqrt((mazs['X'] - mazs['network_node_x'])**2 + 
            (mazs['Y'] - mazs['network_node_y'])**2) / 1609.34
).astype('float16')

# %%
# MAZ-to-STOP Walk

print("--Build MAZ-stop Walk Table")

o_m = np.repeat(mazs['MAZ_SEQID'].tolist(), len(stops_gdf))
o_m_nn = np.repeat(mazs['network_node_id'].tolist(), len(stops_gdf))
d_t = np.tile(stops_gdf['ID'].tolist(), len(mazs))
d_level = np.tile(stops_gdf['local'].tolist(), len(mazs))
d_t_nn = np.tile(stops_gdf['network_node_id'].tolist(), len(mazs))

o_m_x = np.repeat(mazs['network_node_x'].tolist(), len(stops_gdf))
o_m_y = np.repeat(mazs['network_node_y'].tolist(), len(stops_gdf))
d_t_x = np.tile(stops_gdf['network_node_x'].tolist(), len(mazs))
d_t_y = np.tile(stops_gdf['network_node_y'].tolist(), len(mazs))

o_condist = np.repeat(mazs['connector_dist'].tolist(), len(stops_gdf))

# %%
maz_to_stop_cost = pd.DataFrame(
    {
    "MAZ":o_m, "stop":d_t, 
    "OMAZ_NODE":o_m_nn, "DTAP_NODE":d_t_nn, 
    "OMAZ_DISTCON": o_condist, "local": d_level,
    "OMAZ_NODE_X": o_m_x, "OMAZ_NODE_Y": o_m_y,
    "DTAP_NODE_X": d_t_x, "DTAP_NODE_Y": d_t_y
      }
      ) #"DTAP_CANPNR":d_t_canpnr

print("--Get shortest path length")

maz_to_stop_cost["DISTWALK"] = netx.shortest_path_lengths(maz_to_stop_cost["OMAZ_NODE"], maz_to_stop_cost["DTAP_NODE"])

maz_to_stop_cost["DISTWALK"] = maz_to_stop_cost["DISTWALK"] + maz_to_stop_cost["OMAZ_DISTCON"]

# %%
maz_local = maz_to_stop_cost[maz_to_stop_cost.local==1].groupby('MAZ')['DISTWALK'].min().reset_index()
maz_prm = maz_to_stop_cost[maz_to_stop_cost.local==0].groupby('MAZ')['DISTWALK'].min().reset_index()

maz_prm = maz_prm.rename(columns={'DISTWALK': 'AE_PRM'})
maz_local = maz_local.rename(columns={'DISTWALK': 'AE_LOCAL'})

# %%
#Attach the columns to the land use data
land_use_data = pd.read_csv(landuse_dir)

if all(item in land_use_data.columns for item in ['AE_LOCAL', 'AE_PRM', 'MAZ_x', 'MAZ_y']):
    land_use_data = land_use_data.drop(['AE_LOCAL', 'AE_PRM', 'MAZ_x', 'MAZ_y'] , axis=1)
    land_use_data = pd.merge(land_use_data, maz_local, how='left', left_on='maz_id', right_on='MAZ')
    land_use_data = pd.merge(land_use_data, maz_prm, how='left', left_on='maz_id', right_on='MAZ')
    
else:
    land_use_data = pd.merge(land_use_data, maz_local, how='left', left_on='maz_id', right_on='MAZ')
    land_use_data = pd.merge(land_use_data, maz_prm, how='left', left_on='maz_id', right_on='MAZ')

land_use_data.to_csv(landuse_dir, index=False)

# %%
o_m = np.repeat(mazs['MAZ_SEQID'].tolist(), len(mazs))
d_m = np.tile(mazs['MAZ_SEQID'].tolist(), len(mazs))
o_m_nn = np.repeat(mazs['network_node_id'].tolist(), len(mazs))
d_m_nn = np.tile(mazs['network_node_id'].tolist(), len(mazs))
o_m_x = np.repeat(mazs['network_node_x'].tolist(), len(mazs)).astype('float32')
o_m_y = np.repeat(mazs['network_node_y'].tolist(), len(mazs)).astype('float32')
d_m_x = np.tile(mazs['network_node_x'].tolist(), len(mazs)).astype('float32')
d_m_y = np.tile(mazs['network_node_y'].tolist(), len(mazs)).astype('float32')

o_condist = np.repeat(mazs['connector_dist'].tolist(), len(mazs)).astype('float32')
d_condist = np.tile(mazs['connector_dist'].tolist(), len(mazs)).astype('float32')
#%%
# MAZ-to-MAZ Walk
print("---Build MAZ-MAZ Walk Table")
maz_to_maz_cost = pd.DataFrame({"OMAZ":o_m, "DMAZ":d_m, "OMAZ_NODE":o_m_nn, "DMAZ_NODE":d_m_nn, "OMAZ_NODE_X":o_m_x, "OMAZ_NODE_Y":o_m_y, "DMAZ_NODE_X":d_m_x, "DMAZ_NODE_Y":d_m_y, "OMAZ_DISTCON": o_condist, "DMAZ_DISTCON": d_condist}, dtype='float32')
maz_to_maz_cost["DISTWALK"] = maz_to_maz_cost.eval("(((OMAZ_NODE_X-DMAZ_NODE_X)**2 + (OMAZ_NODE_Y-DMAZ_NODE_Y)**2)**0.5) / 1609.34")
#1mile max distance for walk
maz_to_maz_cost = maz_to_maz_cost[maz_to_maz_cost["DISTWALK"] <= 1].copy()

maz_to_maz_cost = maz_to_maz_cost[maz_to_maz_cost["OMAZ"] != maz_to_maz_cost["DMAZ"]]

print("--get shortest path length")

maz_to_maz_cost["DISTWALK"] = netx.shortest_path_lengths(maz_to_maz_cost["OMAZ_NODE"], maz_to_maz_cost["DMAZ_NODE"])
maz_to_maz_cost["DISTWALK"] = maz_to_maz_cost["DISTWALK"] + maz_to_maz_cost["OMAZ_DISTCON"] +  maz_to_maz_cost["DMAZ_DISTCON"]

maz_to_maz_cost_out = maz_to_maz_cost[maz_to_maz_cost["DISTWALK"] <= 1]
#take out rows with OMAZ or DMAZ equal 9999
maz_to_maz_cost_out = maz_to_maz_cost_out[(maz_to_maz_cost_out["OMAZ"] != 99999) & (maz_to_maz_cost_out["DMAZ"] != 99999)]

print(time.ctime(), "--write results")

maz_to_maz_cost_out[["OMAZ","DMAZ","DISTWALK"]].to_csv(output_data + '/maz_to_maz_walk.csv', index=False)
# %%
# MAZ-to-MAZ Bike
print("---Build MAZ-MAZ Bike Table")
maz_to_maz_cost = pd.DataFrame({"OMAZ":o_m, "DMAZ":d_m, "OMAZ_NODE":o_m_nn, "DMAZ_NODE":d_m_nn, "OMAZ_NODE_X":o_m_x, "OMAZ_NODE_Y":o_m_y, "DMAZ_NODE_X":d_m_x, "DMAZ_NODE_Y":d_m_y, "OMAZ_DISTCON": o_condist, "DMAZ_DISTCON": d_condist}, dtype='float32')
maz_to_maz_cost["DISTWALK"] = maz_to_maz_cost.eval("(((OMAZ_NODE_X-DMAZ_NODE_X)**2 + (OMAZ_NODE_Y-DMAZ_NODE_Y)**2)**0.5) / 1609.34")

#5mile max distance for bike
maz_to_maz_cost = maz_to_maz_cost[maz_to_maz_cost["DISTWALK"] <= 5].copy()

print("--get shortest path length")

maz_to_maz_cost["OMAZ_NODE"] = maz_to_maz_cost["OMAZ_NODE"].astype(int)
maz_to_maz_cost["DMAZ_NODE"] = maz_to_maz_cost["DMAZ_NODE"].astype(int)

maz_to_maz_cost["DISTBIKE"] = netx.shortest_path_lengths(
    maz_to_maz_cost["OMAZ_NODE"].values, 
    maz_to_maz_cost["DMAZ_NODE"].values
)
maz_to_maz_cost["DISTBIKE"] = maz_to_maz_cost["DISTBIKE"] + maz_to_maz_cost["OMAZ_DISTCON"] +  maz_to_maz_cost["DMAZ_DISTCON"]
maz_to_maz_bike_cost_out = maz_to_maz_cost[maz_to_maz_cost["DISTBIKE"] <= 5]
#take out rows with OMAZ or DMAZ equal 99999
maz_to_maz_bike_cost_out = maz_to_maz_bike_cost_out[(maz_to_maz_bike_cost_out["OMAZ"] != 99999) & (maz_to_maz_bike_cost_out["DMAZ"] != 99999)]

#missing_maz = pd.DataFrame(mazs[~mazs['MAZ_SEQID'].isin(maz_to_maz_bike_cost_out['OMAZ'])]['MAZ_SEQID']).rename(columns = {'MAZ_SEQID': 'OMAZ'}).merge(maz_to_maz_cost[maz_to_maz_cost['OMAZ'] != maz_to_maz_cost['DMAZ']].sort_values('DISTWALK').groupby('OMAZ').agg({'DMAZ': 'first', 'DISTWALK': 'first'}).reset_index().rename(columns = {'DISTWALK': 'DISTBIKE'}), on = 'OMAZ', how = 'left')

print(time.ctime(), "--write results")

maz_to_maz_bike_cost_out[["OMAZ","DMAZ","DISTBIKE"]].to_csv(output_data + '/maz_to_maz_bike.csv', index=False)