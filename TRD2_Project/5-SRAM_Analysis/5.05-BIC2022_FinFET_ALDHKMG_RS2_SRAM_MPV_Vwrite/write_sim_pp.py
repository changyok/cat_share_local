## Example RandomSpice processing script.
from libfromage.frontend import DBInterface
from libfromage.data import Data
import pandas as pd

pd.set_option("mode.chained_assignment",None)

import re
rSN="[+/-]?(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+/-]?\d+)?"         		# general scientific notation
rCompound="^\s+({0})\s+({0})\s+({0})".format(rSN)	# 4 columns of scientific notation

def Process(data, **extras):
    results = extras['results']
    circuit = extras['cid']
    new_result = extras['new_result']

    dbi = results._dbi
    Data.set_dburl(dbi.engine_url)
    ds=dbi.get_dataset(id=results._set_id).name

    print(new_result.measures)

    meas_data=new_result.measures[0]

    metadata={"Type":"measures"}
    dbi.create_data(ds, meas_data, metadata=metadata)


    return data

