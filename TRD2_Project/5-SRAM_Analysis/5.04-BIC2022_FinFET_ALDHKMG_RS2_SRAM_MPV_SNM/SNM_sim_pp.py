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


    # push CV data
    Data({"vcored":list(new_result.outputs[0]["sweep_voltage"].values), "vncored":list(new_result.outputs[0]["xsram.__NQ__ voltage".lower()].values)}, ivar="vcored", metadata={"Type":"iv0",    "circuit":circuit}).to_db(ds)
    Data({"vncored":list(new_result.outputs[1]["sweep_voltage"].values), "vcored":list(new_result.outputs[1]["xsram.__Q__ voltage".lower()].values)}, ivar="vcored", metadata={"Type":"iv1",    "circuit":circuit}).to_db(ds)

    return data

