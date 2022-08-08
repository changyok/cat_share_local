from libfromage.data import Data
import numpy as np
import pandas as pd
pd.set_option('display.max_rows', 500)
pd.set_option('display.max_columns', 500)
pd.set_option('display.width', 1000)

measure_list = ["stage_delay", "stage_energy", "ileak", "trise", "tfall"]

def Process(data, **extras):
    results = extras['results']
    circuit = extras['cid']

    dbi = results._dbi
    Data.set_dburl(dbi.engine_url)
    ds=dbi.get_dataset(id=results._set_id)
    df = pd.DataFrame()

    for l in data.split("\n"):
        if len(l) > 0:
            if "esup" in  l.lower():
                esup = float(l.replace('=',' ').split()[3])

            for measure in measure_list:
                if measure.lower() in l.lower():
                    try:
                        val=float(l.replace('=',' ').split()[1])
                    except:
                        val="fail"
                        print("Failed to read frequency value from line: {0}".format(l))

                    df.loc[esup, measure] = val


    df=df.reset_index()
    print(df)
    dbi.create_data(ds, df)

    return data

