from enigma.commands import startdb,stopdb
import re, os

nfin_re = re.compile("nfin\s*?=\s*?([1-9])")

PEX_path="@pwd@/../../2-RC_Extraction/2.01-BIC2022_FinFET_PEX_Nominal"

startdb(PEX_path)
# switch DB to harvest data
proj_conf = f"{PEX_path}/enigma/mongodb.conf"
dburl = open(proj_conf).read()
dbi.connect(dburl) 
Data.set_dburl(dburl)


nodes = dbi.get_project(swb__cell="@cell@", swb__bbox_layer="@bbox_layer@", swb__gds="@gds@", swb__selectivehighK=@selectivehighK@, swb__xp1s="vdd", swb__flow="recess_power_rail_gate_cut_standard_r7")

#set incfile tbc
print(f"DOE: incfile {nodes.metadata['netpath']}")

# some pre-processing of the net for usage later
# including pulling out the subdef and node order
# as well as creating a copy with placeholder delta Vts
finalnet=""
mosfets = {"nMOS":[], "pMOS":[]}
mpv_deltas = {"nMOS":{}, "pMOS":{}}

with open(nodes.metadata['netpath'],'r') as f:
    net = f.read()
    for line in net.split("\n"):
       line_adder = ""
       l=line.split()
       if len(l) > 0 and l[0].lower()[:4] == ".sub":
           # found subdef
           subname = l[1]
           print(f"sram cell subdef/nodes {line}.")
       if len(l) > 0 and l[0].lower()[0] == "x":
           # found xmos
           nfin = nfin_re.search(line).group(1)
           if l[5]=="nmos1":
               instance = mosfets["nMOS"].append(l[0])
               mpv_deltas["nMOS"][f'{l[0]}_delta']=0
               line_adder = f" delvtrand0='{l[0]}_delta/({nfin}**0.5)'"
           elif l[5]=="pmos1":
               instance = mosfets["pMOS"].append(l[0])
               mpv_deltas["pMOS"][f'{l[0]}_delta']=0
               line_adder = f" delvtrand0='{l[0]}_delta/({nfin}**0.5)'"
    
       finalnet += line+line_adder+"\n"

if not os.path.exists("@pwd@/BITCELLS"):
    os.makedirs("@pwd@/BITCELLS")

with open("@pwd@/BITCELLS/mpv_@gds@.sp",'w') as f:
    f.write(finalnet)


# switch DB to here
proj_conf = f"@pwd@/enigma/mongodb.conf"
dburl = open(proj_conf).read()
dbi.connect(dburl) 
Data.set_dburl(dburl)
print(subname)
print(mosfets)
print(mpv_deltas)
node_prj.metadata["mosfets"]=mosfets
node_prj.metadata["mpv_deltas"]=mpv_deltas
node_prj.save()

