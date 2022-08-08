# gtree imports
from enigma.apps.swb import add_experiments
from swbpy.gtree import Gtree
# db command imports
from enigma.commands import startdb,stopdb

# harvest data from Mystic Uniform Enigma stages
Mystic_path = "@pwd@/../../3-SpiceModel/3.02-BIC2022_FinFET_ALDHKMG_Mystic_Corners"
startdb(Mystic_path)

# switch DB to harvest data
proj_conf = f"{Mystic_path}/enigma/mongodb.conf"
dburl = open(proj_conf).read()
dbi.connect(dburl) 
Data.set_dburl(dburl)

# setup the main splits
nodes = dbi.get_project(swb__tool_label="Mystic_Uniform_Enigma", swb__midpoint="True")
l_nom = nodes[0].metadata["swb"]["lgate"]
tfin_nom = nodes[0].metadata["swb"]["tfin"]
Vdd_lin = np.abs(nodes[0].metadata["swb"]["Vdd_lin"])
Vdd_nom = np.abs(nodes[0].metadata["swb"]["Vdd_nom"])
tnom = nodes[0].metadata["swb"]["tnom"]-273
lowT = nodes[0].metadata["swb"]["lowT"]-273
highT = nodes[0].metadata["swb"]["highT"]-273

# setup the VT mode splits
VTMODE_nodes = dbi.get_project(swb__tool_label="Cal_WF_Shift", swb__midpoint="True", swb__Type="nMOS")
vt_modes = dict(VTMODE_nodes.metadata["vtmode_adjust"])

# setup Gtree components
project = "@pwd@"
tree    = Gtree(project)
init_nodes = list()

for leaf in tree.AllLeafNodes():
    experiment = tree.NodePath(leaf) + [leaf]
    if @node@ in experiment:
        init_nodes.append(leaf)

for vt_mode in vt_modes:
    for t in [lowT, tnom, highT]:
        add_experiments(tree, init_nodes, {"axis1_midpoint":f"{l_nom:.5}","axis2_midpoint":f"{tfin_nom:.5}", 
                                        "Vdd_lin":f"{Vdd_lin:.5}","Vdd_nom":f"{Vdd_nom:.5}","sim_temp":t, "vt_mode":vt_mode}, scenario="default")
 

tree.Save() 


# switch DB local DB
proj_conf = f"@pwd@/enigma/mongodb.conf"
dburl = open(proj_conf).read()
dbi.connect(dburl) 
Data.set_dburl(dburl)

# attach the VT modes metdata
node_prj = dbi.get_project("@node@")
node_prj.metadata["vt_modes"]=vt_modes
node_prj.save()

