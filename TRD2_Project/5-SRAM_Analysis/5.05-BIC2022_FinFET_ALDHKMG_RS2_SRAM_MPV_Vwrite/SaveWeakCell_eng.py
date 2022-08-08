#setdep @node|FinalSims@

import re

# the goal of this stage is to extract a weak cell
# from the "FinalSims" stage output which can be used in
# array level writability analysis

netfile = "@pwd@/@nodedir|FinalSims@/n@node|FinalSims@_/icrit_results/icrit-1.net"

mpv_params = ""
bitcell_pex = ""
corner_models = ""
with open(netfile, 'r') as f:
    # mvp params
    for res in re.findall("\*\*\sMPV\ params\ START(.*?)\*\*\sMPV\ params\ END", f.read(), re.S):
       mpv_params += res

with open(netfile, 'r') as f:    
    for res in re.findall(".subckt(.*?).ends", f.read(), re.S):
       corner_models += ".subckt " + res + "\n.ends\n"

with open(netfile, 'r') as f:
    for res in re.findall(".SUBCKT(.*?).ENDS", f.read(), re.S):
       bitcell_pex += ".SUBCKT " + res + "\n.ENDS\n"


with open("n@node@_weak_cell.sp", 'w') as f:
    f.write("** weak cell for write\n")
    f.write("** gds=@gds@, cell=@cell@, sigma=@targetSigma@\n\n")
    f.write(mpv_params)
    f.write(bitcell_pex)
    f.write(corner_models)


# save the path to the weak cell netlist
node_prj.metadata["weak_cell"]="@pwd@/@nodedir@/n@node@_weak_cell.sp"
node_prj.save()
