from enigma.commands import startdb,stopdb
from netparse_helpers import RS2NetAdjust

PEX_path="@pwd@/../../2-RC_Extraction/2.01-BIC2022_FinFET_PEX_Nominal"

startdb(PEX_path)
# switch DB to harvest data
proj_conf = f"{PEX_path}/enigma/mongodb.conf"
dburl = open(proj_conf).read()
dbi.connect(dburl) 
Data.set_dburl(dburl)


nodes = dbi.get_project(swb__cell="@cell@", swb__bbox_layer="@bbox_layer@", swb__gds="@gds@", swb__selectivehighK=@selectivehighK@, swb__flow="recess_power_rail_gate_cut_late_r7")


# handle the RC extract
selected_cell=RS2NetAdjust(nodes.metadata['netpath'])
selected_cell.model_call_mapping={"nmos1":"mos3n", "pmos1":"mos3p"}
selected_cell.remove_instance_param("nmos1", "l")
selected_cell.remove_instance_param("pmos1", "l")
selected_cell.convert_models(add_subckt_rand=False)
selected_cell.save_net(filename="n@node@_cell.spf",outpath="@pwd@/@nodedir@", net=True)

#set incfile tbc
print(f"DOE: incfile @pwd@/@nodedir@/n@node@_cell.spf")
