from enigma.commands import startdb,stopdb
from netparse_helpers import RS2NetAdjust

# path to MPV project
PEX_path="@pwd@/../5.04-BIC2022_FinFET_ALDHKMG_RS2_SRAM_MPV_SNM"

startdb(PEX_path)
# switch DB to harvest data
proj_conf = f"{PEX_path}/enigma/mongodb.conf"
dburl = open(proj_conf).read()
dbi.connect(dburl) 
Data.set_dburl(dburl)


nodes = dbi.get_project(swb__cell="@cell@", swb__bbox_layer="@bbox_layer@", swb__gds="@gds@", swb__selectivehighK=@selectivehighK@, swb__tool_label="SaveWeakCell")

nodes.metadata["weak_cell"]

#set incfile tbc
print(f"DOE: incfile {nodes.metadata['weak_cell']}")
