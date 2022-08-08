#setdep @node|RO_Corner_Sim:all@

#if @node:index@ != 2
#noexec
#endif

import copy
from randomspice.Generators.DataStores import get_quadratic_rsm

data=pd.DataFrame()

full_data=[]

nodes = dbi.get_project(swb__tool_label="RO_Corner_Sim")

corner = "tt"
data=pd.DataFrame()
for node in nodes:

    isplit=node.metadata["swb"]["isplit"]
    data0=[d.data for d in dbi.get_data(project=node.name, dataset=f"{node.name}_RO_{corner}", strip=False)]
    data0[0]['isplit']=[isplit]
    data0=[{k:v[0] for k,v in data0[0].items()}]
    pex_doe = node.metadata["pex_doe"]
    data0[0].update(pex_doe)
    data0=pd.DataFrame(data0)
    data=pd.concat([data,data0])

data.reset_index(drop=True, inplace=True)

with open(f"n@node@_{corner}_@logic@X@strength@@height@.csv", 'w') as f:
    data.to_csv(f)

data.drop(["index", "ileak"], axis=1, inplace=True)
data=data[list(pex_doe.keys())+["stage_delay","stage_energy"]]
plotter._dist_data=[data]
plotter.plot_scatter_matrix()

############################################################################
#
############################################################################
# preprocess the data
refdata     = data

# quad rsm
f       = get_quadratic_rsm(refdata[["fin_width","gate_recess","poly_mandrel_bias","poly_sadp_spacer_thk","poly_spacer2_thk","sdc_recess"]].as_matrix(),
                            refdata[["stage_delay"]].as_matrix().ravel())
f2       = get_quadratic_rsm(refdata[["fin_width","gate_recess","poly_mandrel_bias","poly_sadp_spacer_thk","poly_spacer2_thk","sdc_recess"]].as_matrix(),
                            refdata[["stage_energy"]].as_matrix().ravel())

# random sampling
x_seq=list(np.around(np.random.normal(loc=np.median(refdata["fin_width"]), scale=0.00037, size=10000),4))
y_seq=list(np.around(np.random.normal(loc=np.median(refdata["gate_recess"]), scale=0.00037, size=10000),4))
z_seq=list(np.around(np.random.normal(loc=np.median(refdata["poly_mandrel_bias"]), scale=0.00037, size=10000),4))
a_seq=list(np.around(np.random.normal(loc=np.median(refdata["poly_sadp_spacer_thk"]), scale=0.00037, size=10000),4))
b_seq=list(np.around(np.random.normal(loc=np.median(refdata["poly_spacer2_thk"]), scale=0.00037, size=10000),4))
c_seq=list(np.around(np.random.normal(loc=np.median(refdata["sdc_recess"]), scale=0.001, size=10000),4))



final_df=pd.DataFrame()


for i in range(10000):
    final_df.loc[i,"fin_width"] = x_seq[i]
    final_df.loc[i,"gate_recess"] = y_seq[i]
    final_df.loc[i,"poly_mandrel_bias"] = z_seq[i]
    final_df.loc[i,"poly_sadp_spacer_thk"] =a_seq[i]
    final_df.loc[i,"poly_spacer2_thk"] = b_seq[i]
    final_df.loc[i,"sdc_recess"] = c_seq[i]
    final_df.loc[i,"stage_delay"]=f(np.array([x_seq[i],y_seq[i],z_seq[i],a_seq[i],b_seq[i],c_seq[i]]))
    final_df.loc[i,"stage_energy"]=f2(np.array([x_seq[i],y_seq[i],z_seq[i],a_seq[i],b_seq[i],c_seq[i]]))
    i=i+1

plotter._dist_data=[final_df, data]
plotter.plot_scatter_matrix(filename="rsm-combined", multiplot=True)

with open(f"n@node@_{corner}_@logic@X@strength@@height@_RSM_MC.csv", 'w') as f:
    final_df.to_csv(f)

mean_delay = np.mean(final_df["stage_delay"])
sd_delay   = np.std(final_df["stage_delay"])

mean_energy = np.mean(final_df["stage_energy"])
sd_energy   = np.std(final_df["stage_energy"])

slow_PEX_target = {"delay":mean_delay+3*sd_delay, "energy":mean_energy-3*sd_energy}
fast_PEX_target = {"delay":mean_delay-3*sd_delay, "energy":mean_energy+3*sd_energy}

slow_df = copy.deepcopy(data)
fast_df = copy.deepcopy(data)

#################################
# slow corner
#################################


slow_df["stage_delay"]=abs(slow_df["stage_delay"]-(mean_delay+3*sd_delay))
slow_df["stage_energy"]=abs(slow_df["stage_energy"]-(mean_energy-3*sd_energy))

slow_df.sort_values(["stage_delay","stage_energy"],axis=0, inplace=True)
slow_corner_index = slow_df.index.values[0]
slow_corner=data.loc[slow_corner_index,:]

print("slow pex corner definition")
print(slow_corner)
print(slow_corner_index)
slow_corner.to_csv("slow_corner.csv")


#################################
# fast corner
#################################

fast_df["stage_delay"]=abs(fast_df["stage_delay"]-(mean_delay-3*sd_delay))
fast_df["stage_energy"]=abs(fast_df["stage_energy"]-(mean_energy+3*sd_energy))

fast_df.sort_values(["stage_delay","stage_energy"],axis=0, inplace=True)
fast_corner_index = fast_df.index.values[0]
fast_corner=data.loc[fast_corner_index,:]

print("Fast pex corner definition")
print(fast_corner)
print(fast_corner_index)
fast_corner.to_csv("fast_corner.csv")


for d in plotter._dist_data:
    d["stage_delay"]=d["stage_delay"]*1e12
    d["stage_energy"]=d["stage_energy"]*1e15
plotter.plot_hist()

result = pd.concat([fast_corner,slow_corner], axis=1).transpose()
print(result)
result.to_csv("PEX_corners.csv")

############################################################################
#
############################################################################
node_prj=dbi.get_project("@node@")
node_prj.metadata["pex_slow"]=slow_corner_index
node_prj.metadata["pex_fast"]=fast_corner_index
node_prj.save()
