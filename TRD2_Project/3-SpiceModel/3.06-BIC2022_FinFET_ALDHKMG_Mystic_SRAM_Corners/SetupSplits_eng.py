#setdep @node|HarvestData@

from enigma.apps.swb import add_experiments
from swbpy.gtree import Gtree

project = "@pwd@"
tree    = Gtree(project)
init_nodes = list()

for leaf in tree.AllLeafNodes():
    experiment = tree.NodePath(leaf) + [leaf]
    if @node@ in experiment:
        init_nodes.append(leaf)

for devtype in ["nMOS","pMOS"]:
    data = Data.from_db(dtype=devtype, project="@node|HarvestData@")

    dev_lgs_tfin = list(set([(devtype, d.metadata["instances"]["l"],d.metadata["tfin"]) for d in data]))

    print(dev_lgs_tfin)


    for dev,lg,tfin in dev_lgs_tfin:
        print(dev, lg, tfin)
        add_experiments(tree, init_nodes, {"Type":dev,"lgate":lg, "tfin":tfin}, scenario="default")
 

tree.Save() 
