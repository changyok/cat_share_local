#setdep @node|SetupSplits:all@

#if "@Type@" == "tbc"
#noexec
#endif
import pandas as pd

## setup all the parametes we would usually need
## aside from Type, lgate, tfin which are pre-setup
## first get the terminals
data = Data.from_db(dtype="@Type@", instances__l=@lgate@, tfin=@tfin@, project="@node|HarvestData@")
for k,v in data[0].metadata["terminals"].items():
    print(f"DOE: {k} {v}")

# hfin, tspacer, eot, nsd, nch - assume this is constant
for x in ["tnom", "hfin", "tspacer", "eot", "nsd", "nch", "workfn"]:
    print(f"DOE: {x} {float(data[0].metadata[x]):.5}")

# check midpoint-ness
alldata = Data.from_db(dtype="@Type@", project="@node|HarvestData@")
all_lgs = [d.metadata["instances"]["l"]for d in alldata]
all_tfs = [d.metadata["tfin"]for d in alldata]
lgs = list(set(all_lgs))
tfs = list(set(all_tfs))
lgs.sort()
tfs.sort()

middle_index = int(len(lgs)/2)
lgs_mid = lgs[middle_index]
middle_index = int(len(tfs)/2)
tfs_mid = tfs[middle_index]

if data[0].metadata["instances"]["l"] == lgs_mid and data[0].metadata["tfin"] == tfs_mid:
    print("DOE: midpoint True")
else:
    print("DOE: midpoint False")

# check strain and temperature information 
allstrains = list()
alltemps = list()
for d in alldata:
   allstrains.append(d.metadata["instances"]["avgStrain"])
   alltemps.append(d.metadata['temperature'])

strains = list(set(allstrains))
print(f"DOE: avgStrains {' '.join(map(str,strains))}")

print(f"DOE: lowT {min(alltemps)}")
print(f"DOE: highT {max(alltemps)}")

# find the nominal strain
strainNom = None
countData = 0
for s in strains:
   if strainNom == None or allstrains.count(s) > countData :
       strainNom = s
       countData = allstrains.count(s)
print(f"DOE: avgStrainNom {strainNom}")


data = data[0]
# extract Vdd_lin and Vdd_nom
drain_con = data.metadata['terminals']['drain_con']
gate_con = data.metadata['terminals']['gate_con']
idvgs = Data.from_db(dtype="@Type@", instances__l=@lgate@, tfin=@tfin@, 
        ivar=f"v{gate_con}", dvar=f"i{drain_con}", project="@node|HarvestData@")

drain_biases = [d.metadata["bias"][drain_con] for d in idvgs]

if "@Type@".lower() == "nmos":
   print(f"DOE: Vdd_lin {np.min(drain_biases)}")
   print(f"DOE: Vdd_nom {np.max(drain_biases)}")
elif "@Type@".lower() == "pmos":
   print(f"DOE: Vdd_lin {np.max(drain_biases)}")
   print(f"DOE: Vdd_nom {np.min(drain_biases)}")

