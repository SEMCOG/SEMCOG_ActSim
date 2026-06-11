import os
import logging
from typing import Optional
from collections import defaultdict

import numpy as np
import pandas as pd
import pandera as pa
from pandera.typing import Series

import enums as e  # assumes this is available in your environment
import yaml
import warnings
from typing import Union

logger = logging.getLogger("input_checks")
logger.setLevel(logging.INFO)
stream_handler = logging.StreamHandler()
stream_handler.setFormatter(logging.Formatter('%(message)s'))
logger.addHandler(stream_handler)
logger.propagate = False

TABLE_STORE = {}
_log_infos = defaultdict(list)

cur_table = None


import argparse
parser = argparse.ArgumentParser(description="Run input checker with config")
parser.add_argument("config_path", help="Path to input_checker.yaml")
parser.add_argument("--data_root", help="Base path for data inputs", default=".")
parser.add_argument("--trace_label", help="Optional trace label", default="input_checker")
parser.add_argument("--hh_file", help="Path to household file (CSV)")
parser.add_argument("--person_file", help="Path to person file (CSV)")
parser.add_argument("--landuse_file", help="Path to land use file (CSV)")
parser.add_argument("--maz_to_tap_file", help="Path to maz_to_tap.csv (optional)", default=None)

# ----------------------------------------------------

def log_info(text: Union[str, pd.DataFrame], table_name: str):
    if isinstance(text, pd.DataFrame):
        # Format cleanly: move index into column, one row per line
        formatted = text.reset_index().to_string(index=False)
        _log_infos[table_name].append(formatted)
    else:
        _log_infos[table_name].append(text)

def check_integer_type(series: pd.Series) -> bool:
    return pd.api.types.is_integer_dtype(series)


def validate_with_pandera(input_checker, table_name, validation_settings, v_errors, v_warnings):
    validator_class = input_checker[validation_settings["class"]]
    with warnings.catch_warnings(record=True) as caught_warnings:
        warnings.simplefilter("always")
        try:
            validator_class.validate(TABLE_STORE[table_name], lazy=True)
        except pa.errors.SchemaErrors as e:
            v_errors[table_name].append(e)
        for warning in caught_warnings:
            v_warnings[table_name].append(warning)
    return v_errors, v_warnings


class Household(pa.DataFrameModel):
    household_id: Series[int] = pa.Field(nullable=False, coerce=True, unique=True, gt=0)
    age_of_head: int = pa.Field(ge=0)
    large_area_id: int = pa.Field(gt=0)
    cars: int = pa.Field(isin=([-9] + list(range(7))))
    workers: int = pa.Field(ge=0)
    persons: int = pa.Field(gt=0)
    race_id: int = pa.Field(gt=0, le=4)
    income: int = pa.Field(ge=0)
    building_id: int = pa.Field(gt=0)
    children: int = pa.Field(ge=0)
    type: int = pa.Field(gt=0)
    hincp: float
    adjinc: int = pa.Field(ge=0)
    hht: int = pa.Field(isin=e.HHT, raise_warning=True)
    school_id: int = pa.Field(gt=0)
    maz_id: int = pa.Field(ge=0)
    taz_id: int = pa.Field(gt=0)

    @pa.dataframe_check(name="Household size equals the number of persons?") # ', raise_warning=True'
    def check_persons_per_household(cls, df: pd.DataFrame):
        persons = TABLE_STORE["persons"]
        counts = persons.groupby("household_id").size().reindex(df.household_id).fillna(0)
        mismatched = df.set_index("household_id").loc[counts != df.set_index("household_id").persons]

        if not mismatched.empty:
            log_info("Household size does not equal the number of persons at", "households")
            log_info(mismatched, "households")
        return counts == df.set_index("household_id").persons

    @pa.dataframe_check(name="maz in landuse file?")
    def check_home_zone_in_landuse(cls, df: pd.DataFrame):
        landuse = TABLE_STORE["land_use"]
        missing = df[~df["taz_id"].isin(landuse["taz_id"])]
        if not missing.empty:
            log_info("Tazes are not in landuse file at", "households")
            log_info(missing, "households")
        return df["taz_id"].isin(landuse["taz_id"])

    @pa.dataframe_check(name="Household workers equals the number of workers in persons?")
    def check_workers_per_household(cls, df: pd.DataFrame):
        persons = TABLE_STORE["persons"]
        workers = persons[persons["worker"] == 1].groupby("household_id").size().reindex(df.household_id).fillna(0)
        mismatched = df.set_index("household_id").loc[workers != df.set_index("household_id").workers]
        if not mismatched.empty:
            log_info("Household workers dose not equal the number of workers in persons at", "households")
            log_info(mismatched, "households")
        return workers == df.set_index("household_id").workers

    @pa.dataframe_check(name="Household children equals the number of child (age<=17) in persons?")
    def check_children_per_household(cls, df: pd.DataFrame):
        persons = TABLE_STORE["persons"]
        children = persons[persons["age"] <= 17].groupby("household_id").size().reindex(df.household_id).fillna(0)
        mismatched = df.set_index("household_id").loc[children != df.set_index("household_id").children]
        if not mismatched.empty:
            log_info("Household children dose not equal the number of children in persons", "households")
            log_info(mismatched, "households")
        return children == df.set_index("household_id").children


class Person(pa.DataFrameModel):
    person_id: Series[int] = pa.Field(nullable=False, coerce=True, unique=True, gt=0)
    relate: int = pa.Field(ge=0, le=17)
    age: int = pa.Field(ge=0, le=100)
    worker: int = pa.Field(isin=[-9.0, 0.0, 1.0])
    gender: int = pa.Field(ge=1, le=2)
    race_id: int = pa.Field(gt=0, le=4)
    member_id: int = pa.Field(gt=0)
    household_id: int = pa.Field(nullable=False)
    esr: float = pa.Field(isin=[-9.0] + list(map(float, range(1, 7))))
    wkhp: float = pa.Field(isin=[-9.0] + list(map(float, range(0, 9999))))
    wkw: float = pa.Field(isin=[-9.0] + list(map(float, range(0, 7))))
    schg: float = pa.Field(isin=[-9.0] + list(map(float, range(0, 17))))
    mil: float = pa.Field(isin=[-9.0] + list(map(float, range(0, 5))))
    naicsp: str
    industry: int = pa.Field(isin=[-9.0] + list(map(float, range(0, 19))))
    school_id: int = pa.Field(ge=10000, le=99999)
    maz_id: int = pa.Field(gt=0)

    @pa.dataframe_check(name="All persons in households table?")
    def check_persons_in_households(cls, df: pd.DataFrame):
        households = TABLE_STORE["households"]
        bad = df[~df["household_id"].isin(households["household_id"])]
        if not bad.empty:
            log_info("Person's household are not in households table", "persons")
            log_info(bad, "persons")
        else:
            log_info(f"All person's households are in households table.\n", "persons")         
        return df["household_id"].isin(households["household_id"])

    @pa.dataframe_check(name="Every household has a person?")
    def check_households_have_persons(cls, df: pd.DataFrame):
        households = TABLE_STORE["households"]
        missing = households[~households["household_id"].isin(df["household_id"])]
        if not missing.empty:
            log_info("Household does not have a person", "persons")
            log_info(missing, "persons")
        else:
            log_info(f"Every household has a person.\n", "persons")              
        return households["household_id"].isin(df["household_id"]).all()

    @pa.dataframe_check(name="Is worker and esr consistent?")
    def check_worker_esr(cls, df: pd.DataFrame):
        cond1 = (df["worker"] == 1) & (df["esr"].isin([1, 2, 4, 5]))
        cond2 = (df["worker"].isin([0, -9])) & (df["esr"].isin([-9, 3, 6]))
        bad = df[~(cond1 | cond2)]
        if not bad.empty:
            log_info("Worker and esr is not consistent", "persons")
            log_info(bad, "persons")
        else:
            log_info(f"Worker and esr is consistant.\n", "persons")               
        return cond1 | cond2

class Landuse(pa.DataFrameModel):
    """
    Land use data.
    Customize as needed for your application.

    maz_id: TAZ of the zone
    DISTRICT: District the zone relies in
    SD: Super District
    COUNTY: County of zone, see enums.County
    TOTHH: Total households
    TOTEMP: Total Employment
    RETEMPN: Retail trade employment
    FPSEMPN: Financial and processional services employment
    HEREMPN: Health, educational, and recreational service employment
    OTHEMPN: Other employment
    AGREMPN: Agricultural and natural resources employment
    MWTEMPN: Manufacturing, wholesale trade, and transporation employment
    """

    maz_id: int = pa.Field(ge=1, nullable=False, coerce=True)
    @pa.check("maz_id", name="maz_id does not contain 99999", raise_warning=True) 
    def maz_id_not_99999(cls, maz_id: pd.Series) -> pd.Series:
        return maz_id != 99999    
    tot_acres: float = pa.Field(ge=0)
    #tazce10_n: float = pa.Field(ge=0) 
    pa.Number = pa.Field(ge=0) 
    #MAZ: float = pa.Field(gt=0, nullable=False, coerce=True)
    tot_hhs: float = pa.Field(ge=0, nullable=False, coerce=True)
    hhs_pop: float = pa.Field(ge=0,coerce=True)
    grppop: float = pa.Field(ge=0,coerce=True)
    tot_pop: float = pa.Field(ge=0,coerce=True) 
    enrollment_k_8: float = pa.Field(ge=0,coerce=True)
    enrollment_9_12: float = pa.Field(ge=0,coerce=True)
    e01_nrm: float = pa.Field(ge=0,coerce=True)
    e02_constr: float = pa.Field(ge=0,coerce=True)
    e03_manuf: float = pa.Field(ge=0,coerce=True)
    e04_whole: float = pa.Field(ge=0,coerce=True)
    e05_retail: float = pa.Field(ge=0,coerce=True)
    e06_trans: float = pa.Field(ge=0,coerce=True)
    e07_utility: float = pa.Field(ge=0,coerce=True)
    e08_infor: float = pa.Field(ge=0,coerce=True)
    e09_finan: float = pa.Field(ge=0,coerce=True)
    e10_pstsvc: float = pa.Field(ge=0,coerce=True)
    e11_compmgt: float = pa.Field(ge=0,coerce=True)
    e12_admsvc: float = pa.Field(ge=0,coerce=True)
    e13_edusvc: float = pa.Field(ge=0,coerce=True)
    e14_medfac: float = pa.Field(ge=0,coerce=True)
    e15_hospit: float = pa.Field(ge=0,coerce=True)
    e16_leisure: float = pa.Field(ge=0,coerce=True)
    e17_othsvc: float = pa.Field(ge=0,coerce=True)
    e18_pubadm: float = pa.Field(ge=0,coerce=True)
    tot_emp: float = pa.Field(ge=0,coerce=True)
    resid_sf: float = pa.Field(ge=0,coerce=True)
    edu_sf: float = pa.Field(ge=0,coerce=True)
    othinst_sf: float = pa.Field(ge=0,coerce=True)
    retail_sf: float = pa.Field(ge=0,coerce=True)
    office_sf: float = pa.Field(ge=0,coerce=True)
    indust_sf: float = pa.Field(ge=0,coerce=True)
    tcu_sf: float = pa.Field(ge=0,coerce=True)
    medical_sf: float = pa.Field(ge=0,coerce=True)
    entmt_sf: float = pa.Field(ge=0,coerce=True)
    othcom_sf: float = pa.Field(ge=0,coerce=True)
    Dorm_sf: float = pa.Field(ge=0,coerce=True)
    parking_sf: float = pa.Field(ge=0,coerce=True)

    @pa.dataframe_check(name="Total employment is sum of employment categories?")
    def check_tot_employment(cls, land_use: pd.DataFrame):
        tot_emp = land_use[
            ["e01_nrm","e02_constr","e03_manuf","e04_whole","e05_retail","e06_trans",\
            "e07_utility","e08_infor","e09_finan","e10_pstsvc","e11_compmgt","e12_admsvc"\
            ,"e13_edusvc","e14_medfac","e15_hospit","e16_leisure","e17_othsvc","e18_pubadm"]
        ].sum(axis=1)
        result = (tot_emp == land_use.tot_emp).all()  
        output = land_use.loc[~(tot_emp == land_use.tot_emp), 'maz_id'].tolist()

        if len(output) > 0:
            log_info(
                f"Total employment is not sum of 18 employment categories at maz_id:\n{output.to_string(index=False)}",
                "land_use"
            )
        else:
            log_info("Total employment is sum of 18 employment categories.", "land_use")
            
        return tot_emp == land_use.tot_emp
    @pa.dataframe_check(name="Zonal households equals the number of households?")
    def check_hh_per_zone(cls, land_use: pd.DataFrame):
        land_use = land_use.sort_values(by='maz_id', ascending=True)
        households = TABLE_STORE["households"]     
        households = households[households['hht'] > 0]
        hh = (
            households.groupby("maz_id")["household_id"]
            .nunique()
            .reset_index(name="count")  # Rename the result column to "count"
        )    
        land_use_filtered = land_use[land_use['maz_id'] != 99999].copy()
        hh = pd.merge(hh, land_use_filtered[['maz_id']], on="maz_id", how="right").fillna(0)
        hh.set_index('maz_id', inplace=True)
        land_use_filtered.set_index('maz_id', inplace=True)        
        mismatched_indices = (hh["count"] != land_use_filtered["tot_hhs"])      
        mismatched_cases = hh.loc[mismatched_indices]  
        if len(mismatched_cases) > 0:
            log_info(
                f"Zonal households does not equal the number of households at:\n{mismatched_cases.to_string(index=True)}",
                "land_use"
            )
        else:
            log_info("Zonal households equals the number of households.", "land_use")         
                      
        return ~mismatched_indices  

    @pa.dataframe_check(name="Zonal grppop equals the number of households?")
    def check_grppop_per_zone(cls, land_use: pd.DataFrame):
        land_use = land_use.sort_values(by='maz_id', ascending=True)
        households = TABLE_STORE["households"]     
        households = households[households['hht'] == -9]
        hh = (
            households.groupby("maz_id")["household_id"]
            .nunique()
            .reset_index(name="count")  # Rename the result column to "count"
        )  
        land_use_filtered = land_use[land_use['maz_id'] != 99999].copy()
        hh = pd.merge(hh, land_use_filtered[['maz_id']], on="maz_id", how="right").fillna(0)  
        hh.set_index('maz_id', inplace=True)
        land_use_filtered.set_index('maz_id', inplace=True)        
        mismatched_indices = (hh["count"] != land_use_filtered["grppop"])
        mismatched_cases = hh.loc[mismatched_indices]
                
        if len(mismatched_cases) > 0:
            log_info(
                f"Zonal grppop does not equal the number of households at:\n{mismatched_cases.to_string(index=True)}",
                "land_use"
            )
        else:
            log_info("Zonal grppop equals the number of households.", "land_use") 

        return ~mismatched_indices  

    @pa.dataframe_check(name="Zonal pop equals the number of persons?")
    def check_pop_per_zone(cls, land_use: pd.DataFrame):
        land_use = land_use.sort_values(by='maz_id', ascending=True)
        persons = TABLE_STORE["persons"]   
        persons = (
            persons.groupby("maz_id")["person_id"]
            .nunique()
            .reset_index(name="count")  # Rename the result column to "count"
        )           
        land_use_filtered = land_use[land_use['maz_id'] != 99999].copy() 
        persons = pd.merge(persons, land_use_filtered[['maz_id']], on="maz_id", how="right").fillna(0) 
        persons.set_index('maz_id', inplace=True)
        land_use_filtered.set_index('maz_id', inplace=True)
        mismatched_indices = (persons["count"] != land_use_filtered["tot_pop"])
        mismatched_cases = persons.loc[mismatched_indices]
        if len(mismatched_cases) > 0:
            log_info(
                f"Zonal pop does not equal the number of persons at:\n{mismatched_cases.to_string(index=True)}",
                "land_use"
            )
        else:
            log_info("Zonal pop equals the number of persons.", "land_use")
        return persons['count'] == land_use_filtered['tot_pop']  

class NetworkLinks(pa.DataFrameModel):
    """
    Example Network data.
    Only including some columns here for illustrative purposes.

    ID: network link ID
    Dir: Direction
    Length: length of link in miles
    AB_LANES: number of lanes in the A-node to B-node direction
    BA_LANES: number of lanes in the B-node to A-node direction
    FENAME: street name
    """

    ID: int = pa.Field(unique=True, gt=0)
    Dir: int = pa.Field(isin=[-1, 0, 1])
    Length: float = pa.Field(ge=0)
    AB_LANES: int = pa.Field(ge=0, le=10)
    BA_LANES: int = pa.Field(ge=0, le=10)
    FENAME: str = pa.Field()

    @pa.dataframe_check(name="All skims in File?", raise_warning=True)
    def check_all_skims_exist(cls, land_use: pd.DataFrame):
        state = TABLE_STORE["state"]

        # code duplicated from skim_dict_factory.py but need to copy here to not load skim data
        los_settings = state.filesystem.read_settings_file("network_los.yaml")     
        omx_file_paths = state.filesystem.expand_input_file_list(
            los_settings["taz_skims"]
        )
        omx_manifest = dict()
        # FIXME getting numpy deprication warning from below omx read
        import warnings

        warnings.filterwarnings("ignore", category=DeprecationWarning)
        for omx_file_path in omx_file_paths:
            with omx.open_file(omx_file_path, mode="r") as omx_file:
                for skim_name in omx_file.listMatrices():
                    omx_manifest[skim_name] = omx_file_path
        omx_keys = []
        for skim_name in omx_manifest.keys():
            key1, sep, key2 = skim_name.partition("__")
            omx_keys.append(key1)

        tour_mode_choice_spec = state.filesystem.read_settings_file(
            "tour_mode_choice.yaml"
        )["SPEC"]

        def extract_skim_names(file_path):
            """
            Helper function to grab the names of the matrices from a given file_path.

            e.g. grabbing 'DRIVEALONE_TIME' from instance of skims['DRIVEALONE_TIME'] in tour_mode_choice.csv
            """
            skim_names = []

            with open(file_path) as csvfile:
                csv_reader = csv.reader(csvfile)
                for row in csv_reader:
                    row_string = ",".join(row)
                    matches = re.findall(r"skims\[['\"]([^'\"]+)['\"]\]", row_string)
                    skim_names.extend(matches)

            return skim_names

        skim_names = extract_skim_names(
            state.filesystem.get_config_file_path(tour_mode_choice_spec)
        )

        # Adding breaking change for testing!
        skim_names.append("break")

        missing_skims = [
            skim_name for skim_name in skim_names if skim_name not in omx_keys
        ]
        if len(missing_skims) > 0:
            log_info(
                f"Missing skims {missing_skims} found in {tour_mode_choice_spec}", "network_links"
            )
        result = (len(missing_skims) == 0) 
        return result 
		
def report_results(table_name: str, v_errors: dict, v_warnings: dict):
    logger.info("")
    logger.info("##############")
    logger.info(f"  {table_name}")
    logger.info("##############")

    errors = v_errors.get(table_name, [])
    warnings = v_warnings.get(table_name, [])
    infos = _log_infos.get(table_name, [])

    if warnings:
        logger.info(f"\n{table_name} warnings:\n" + "-" * (10 + len(table_name)))
        for warn in warnings:
            msg = str(warn.message)
            if "element-wise validator" in msg and "failure cases:" in msg:
                parts = msg.split("failure cases:")
                header = parts[0].strip()
                failure = parts[1].strip()

                first_line = header.splitlines()[0]
                logger.info(f"Failed element-wise validator: <{first_line.split(' ')[1]}>")
                for line in header.splitlines()[1:]:
                    logger.info("    " + line)
                logger.info("    failure cases:")
                for line in failure.splitlines():
                    logger.info("    " + line)
            else:
                logger.info(msg)
        logger.info("")

    if errors:
        logger.info(f"\n{table_name} errors:\n" + "-" * (8 + len(table_name)))
        for err_group in errors:
            logger.info("Error Counts\n------------")
            for err_type, count in err_group.error_counts.items():
                logger.info(f"{err_type}\t{count}")

            for err in err_group.schema_errors:
                msg = str(err)
                if "element-wise validator" in msg and "failure cases:" in msg:
                    parts = msg.split("failure cases:")
                    header = parts[0].strip()
                    failure = parts[1].strip()

                    first_line = header.splitlines()[0]
                    logger.info(f"Failed element-wise validator: <{first_line.split(' ')[1]}>")
                    for line in header.splitlines()[1:]:
                        logger.info("    " + line)
                    logger.info("    failure cases:")
                    for line in failure.splitlines():
                        logger.info("    " + line)
                else:
                    logger.info(msg)
        logger.info("")

    if infos:
        logger.info(f"{table_name} additional messages:")
        for info in infos:
            for line in str(info).splitlines():
                logger.info("    " + line)
        logger.info("")

def main():
    global cur_table

    args = parser.parse_args()

    with open(args.config_path, "r") as f:
        input_checker_settings = yaml.safe_load(f)

    if args.hh_file:
        hh_path = os.path.abspath(args.hh_file)
        logger.info(f"Loading household file: {hh_path}")
        TABLE_STORE["households"] = pd.read_csv(hh_path)

    if args.person_file:
        person_path = os.path.abspath(args.person_file)
        logger.info(f"Loading person file: {person_path}")
        TABLE_STORE["persons"] = pd.read_csv(person_path)

    if args.landuse_file:
        landuse_path = os.path.abspath(args.landuse_file)
        logger.info(f"Loading land use file: {landuse_path}")
        TABLE_STORE["land_use"] = pd.read_csv(landuse_path)
    logger.info("")

    v_errors = {}
    v_warnings = {}

    for table_settings in input_checker_settings["table_list"]:
        table_name = table_settings["name"]
        validation_settings = table_settings["validation"]
        cur_table = table_name

        v_errors[table_name] = []
        v_warnings[table_name] = []

        if validation_settings["method"] == "pandera":

            v_errors, v_warnings = validate_with_pandera(
                globals(),  # uses test.py classes
                table_name,
                validation_settings,
                v_errors,
                v_warnings
            )
        else:
            logger.warning(f"Validation method {validation_settings['method']} not implemented.")

    for table in input_checker_settings["table_list"]:
        table_name = table["name"]
        n_errors = len(v_errors.get(table_name, []))
        n_warnings = len(v_warnings.get(table_name, []))
        logger.info(f"Encountered {n_errors} errors and {n_warnings} warnings in table {table_name}")
    logger.info("")
    
    for table in v_errors:
        report_results(table, v_errors, v_warnings)

    any_errors = any(len(v_errors.get(table["name"], [])) > 0 for table in input_checker_settings["table_list"])
    if any_errors:
        logger.info("Input checking is done with errors.")
    else:
        logger.info("Input checking completed.")



if __name__ == "__main__":
    main()