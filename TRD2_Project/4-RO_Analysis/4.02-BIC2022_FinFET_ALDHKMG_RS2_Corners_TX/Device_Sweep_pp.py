## Example RandomSpice processing script.
from libfromage.frontend import DBInterface
from libfromage.data import Data
import pandas as pd

pd.set_option("mode.chained_assignment",None)

import re
rSN="[+/-]?(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+/-]?\d+)?"         		# general scientific notation
rCompound="^\s+({0})\s+({0})\s+({0})\s+({0})\s+({0})".format(rSN)	# 4 columns of scientific notation

def Process(data, **extras):
    # pass through the circuit id and results container
    results = extras['results']
    circuit = extras['cid']

    dbi = results._dbi
    Data.set_dburl(dbi.engine_url)
    ds=dbi.get_dataset(id=results._set_id).name

    data_counter=0
    ld_vg=[]
    ld_cvg=[]
    ld_iv_n=[]
    ld_cgg_n=[]
    ld_iv_p=[]
    ld_cgg_p=[]
    hd_vg=[]
    hd_iv_n=[]
    hd_cgg_n=[]
    hd_iv_p=[]
    hd_cgg_p=[]
    
    for line in data.split("\n"):
        if len(line)<1:
            pass
        elif line[0]=='y':
            data_counter+=1
        elif re.search(rCompound, line) and data_counter==0:
            line=line.split()
            ld_cvg.append(float(line[0]))
            #ld_iv.append(float(line[2]))
            ld_cgg_n.append(float(line[3]))
            ld_cgg_p.append(float(line[4]))
        elif re.search(rCompound, line) and data_counter==1:
            line=line.split()
            ld_vg.append(float(line[0]))
            ld_iv_n.append(float(line[1]))
            ld_iv_p.append(float(line[2]))
        elif re.search(rCompound, line) and data_counter==2:
            line=line.split()
            hd_vg.append(float(line[0]))
            hd_iv_n.append(float(line[1]))
            hd_iv_p.append(float(line[2]))
            hd_cgg_n.append(float(line[3]))
            hd_cgg_p.append(float(line[4]))

    # push CV data
    Data({"vg":ld_cvg, "cgg":ld_cgg_n}, ivar="vg", metadata={"Type":"nMOS", "bias":{"drain":0.0}, "circuit":circuit}).to_db(ds)
    Data({"vg":ld_cvg, "cgg":ld_cgg_p}, ivar="vg", metadata={"Type":"pMOS", "bias":{"drain":0.0}, "circuit":circuit}).to_db(ds)

    # push LD data
    Data({"vg":ld_vg, "id":ld_iv_n}, ivar="vg", metadata={"Type":"nMOS", "bias":{"drain":abs(@Vdd_lin@)}, "circuit":circuit}).to_db(ds)
    Data({"vg":ld_vg, "id":ld_iv_p}, ivar="vg", metadata={"Type":"pMOS", "bias":{"drain":abs(@Vdd_lin@)}, "circuit":circuit}).to_db(ds)

    # push HD data
    Data({"vg":hd_vg, "id":hd_iv_n}, ivar="vg", metadata={"Type":"nMOS", "bias":{"drain":abs(@Vdd_nom@)}, "circuit":circuit}).to_db(ds)
    Data({"vg":hd_vg, "id":hd_iv_p}, ivar="vg", metadata={"Type":"pMOS", "bias":{"drain":abs(@Vdd_nom@)}, "circuit":circuit}).to_db(ds)


    return None
