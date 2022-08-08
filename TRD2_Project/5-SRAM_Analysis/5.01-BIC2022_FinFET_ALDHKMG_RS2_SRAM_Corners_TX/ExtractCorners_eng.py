#setdep @node|Device_Sweep@ @node|Device_Pair_Simulation@

from corner_helpers import *

axes = ["@axis1@","@axis2@","@axis3@"]

#####################################################
###### Device Pair Data PCA analysis    #############
#####################################################

# load the data from the device-pair ad device sweep simulations
dev_pair=pd.DataFrame(dbi.get_data(project="@node|Device_Pair_Simulation@", dataset="DevPair").data)
dev_pair_n=dev_pair[dev_pair["devtype"]=="nMOS"].set_index("circuit_id")
dev_pair_p=dev_pair[dev_pair["devtype"]=="pMOS"].set_index("circuit_id")
dev_pair_n.columns=[c+"-n" for c in dev_pair_n.columns]
dev_pair_p.columns=[c+"-p" for c in dev_pair_p.columns]

print(dev_pair_n.std())
print(dev_pair_p.std())
# store FoM standard deviations
node_prj.metadata["std"]={}
node_prj.metadata["std"]["n"]=dev_pair_n.std().to_dict()
node_prj.metadata["std"]["p"]=dev_pair_p.std().to_dict()
node_prj.save()

# calculate corner points
cgg_off_cs	=DF_PCA(dev_pair_n, dev_pair_p, 'Cgg_off-n',  'Cgg_off-p',  '@pwd@/@nodedir@/n@node@_cgg_off_pca', sigma_extr=3)
cgg_on_cs	=DF_PCA(dev_pair_n, dev_pair_p, 'Cgg_on-n',   'Cgg_on-p',   '@pwd@/@nodedir@/n@node@_cgg_on_pca', sigma_extr=3)
vt_lin_cs	=DF_PCA(dev_pair_n, dev_pair_p, 'VT_lin-n',   'VT_lin-p',   '@pwd@/@nodedir@/n@node@_VT_lin_pca', sigma_extr=3)
vt_sat_cs	=DF_PCA(dev_pair_n, dev_pair_p, 'VT_sat-n',   'VT_sat-p',   '@pwd@/@nodedir@/n@node@_VT_sat_pca', sigma_extr=3)
ion_lin_cs	=DF_PCA(dev_pair_n, dev_pair_p, 'Ion_lin-n',  'Ion_lin-p',  '@pwd@/@nodedir@/n@node@_Ion_lin_pca', sigma_extr=3)
ion_sat_cs	=DF_PCA(dev_pair_n, dev_pair_p, 'Ion_sat-n',  'Ion_sat-p',  '@pwd@/@nodedir@/n@node@_Ion_sat_pca', sigma_extr=3)
ioff_lin_cs	=DF_PCA(dev_pair_n, dev_pair_p, 'Ioff_lin-n', 'Ioff_lin-p', '@pwd@/@nodedir@/n@node@_Ioff_lin_pca', sigma_extr=3)
ioff_sat_cs	=DF_PCA(dev_pair_n, dev_pair_p, 'Ioff_sat-n', 'Ioff_sat-p', '@pwd@/@nodedir@/n@node@_Ioff_sat_pca', sigma_extr=3)

# sort the PCA points into corners
cgg_off_cs	=corner_sort(cgg_off_cs, 'v')
cgg_on_cs	=corner_sort(cgg_on_cs, 'v')
vt_lin_cs	=corner_sort(vt_lin_cs, 'v')
vt_sat_cs	=corner_sort(vt_sat_cs, 'v')
ion_lin_cs	=corner_sort(ion_lin_cs, 'i')
ion_sat_cs	=corner_sort(ion_sat_cs, 'i')
ioff_lin_cs	=corner_sort(ioff_lin_cs, 'i')
ioff_sat_cs	=corner_sort(ioff_sat_cs, 'i')

corners = pd.concat([ion_lin_cs, ion_sat_cs, vt_lin_cs, vt_sat_cs, ioff_lin_cs, ioff_sat_cs, cgg_off_cs, cgg_on_cs], axis=1)
#scaling_list_n = {"Ion_lin-n":5.0, "Ion_sat-n":1, "VT_lin-n":1.0, "VT_sat-n":1.0, "Ioff_lin-n":1.0, "Ioff_sat-n":1.0, "Cgg_off-n":5.0, "Cgg_on-n":5.0}
#scaling_list_p = {"Ion_lin-p":5.0, "Ion_sat-p":1, "VT_lin-p":1.0, "VT_sat-p":1.0, "Ioff_lin-p":1.0, "Ioff_sat-p":1.0, "Cgg_off-p":5.0, "Cgg_on-p":5.0}
scaling_list_n = {"Ion_lin-n":1.0, "Ion_sat-n":1.0, "VT_lin-n":1.0, "VT_sat-n":1.0, "Ioff_lin-n":1.0, "Ioff_sat-n":1.0, "Cgg_off-n":0.1, "Cgg_on-n":0.1}
scaling_list_p = {"Ion_lin-p":1.0, "Ion_sat-p":1.0, "VT_lin-p":1.0, "VT_sat-p":1.0, "Ioff_lin-p":1.0, "Ioff_sat-p":1.0, "Cgg_off-p":0.1, "Cgg_on-p":0.1}

#####################################################
########### RSM data preparation ####################
#####################################################

# load the RSM data
dev_sweep=pd.DataFrame(dbi.get_data(project="@node|Device_Sweep@", dataset="RespSurf").data)
dev_sweep = dev_sweep[(dev_sweep["phigvar"]>-0.03) & (dev_sweep["phigvar"]<0.03)]

# filter down to type
dev_sweep_n=dev_sweep[dev_sweep["devtype"]=="nMOS"]
dev_sweep_p=dev_sweep[dev_sweep["devtype"]=="pMOS"]
# make the FoM headers match the corner ones
dev_sweep_n.columns=[c.replace("-RespSurf","-n") for c in dev_sweep_n.columns]
dev_sweep_p.columns=[c.replace("-RespSurf","-p") for c in dev_sweep_p.columns]
# use the doe axes as multi-level indexes
dev_sweep_n.index=pd.MultiIndex.from_arrays(dev_sweep_n[axes].values.T)
dev_sweep_n.drop(axes+["DIBL-n", "devtype"], axis=1, inplace=True)
dev_sweep_p.index=pd.MultiIndex.from_arrays(dev_sweep_p[axes].values.T)
dev_sweep_p.drop(axes+["DIBL-p", "devtype"], axis=1, inplace=True)

#####################################################
############## Extract corners ######################
#####################################################

df = pd.DataFrame(index=['ff','ss','sf','fs','tt'], columns=corners.columns)
print(df)
print(dev_sweep_n)
coords = []

for cor in df.index:
    
    nsurf = DoESurface2(dev_sweep_n, corner=corners.ix[cor], err_scaling_list=scaling_list_n, sampling=21, target_err=0.001)
    nerr = nsurf.explicit_solve()
    locallist=['n', cor]
    locallist.extend(nerr)
    coords.append(tuple(locallist))
    n = nsurf.get_point(nerr)

    psurf = DoESurface2(dev_sweep_p, corner=corners.ix[cor], err_scaling_list=scaling_list_p, sampling=21, target_err=0.001)
    perr = psurf.explicit_solve()
    locallist=['p', cor]
    locallist.extend(perr)
    coords.append(tuple(locallist))
    p = psurf.get_point(perr)

    pn = pd.concat([n,p], axis = 1)
    df.ix[cor] = pn.ix[0] 

#####################################################
############### Show fittings #######################
#####################################################

# calculate corner points
cgg_off_pca	=DF_PCA(dev_pair_n, dev_pair_p, 'Cgg_off-n',  'Cgg_off-p',  '@pwd@/@nodedir@/n@node@_cgg_off_fit',  extra_points=df[['Cgg_off-n',  'Cgg_off-p']], output_csv=True)
cgg_on_pca	=DF_PCA(dev_pair_n, dev_pair_p, 'Cgg_on-n',   'Cgg_on-p',   '@pwd@/@nodedir@/n@node@_cgg_on_fit',  extra_points=df[['Cgg_on-n',   'Cgg_on-p']], output_csv=True)
vt_lin_pca	=DF_PCA(dev_pair_n, dev_pair_p, 'VT_lin-n',   'VT_lin-p',   '@pwd@/@nodedir@/n@node@_VT_lin_fit',   extra_points=df[['VT_lin-n',   'VT_lin-p']], output_csv=True)
vt_sat_pca	=DF_PCA(dev_pair_n, dev_pair_p, 'VT_sat-n',   'VT_sat-p',   '@pwd@/@nodedir@/n@node@_VT_sat_fit',   extra_points=df[['VT_sat-n',   'VT_sat-p']], output_csv=True)
ion_lin_pca	=DF_PCA(dev_pair_n, dev_pair_p, 'Ion_lin-n',  'Ion_lin-p',  '@pwd@/@nodedir@/n@node@_Ion_lin_fit',  extra_points=df[['Ion_lin-n',  'Ion_lin-p']], output_csv=True)
ion_sat_pca	=DF_PCA(dev_pair_n, dev_pair_p, 'Ion_sat-n',  'Ion_sat-p',  '@pwd@/@nodedir@/n@node@_Ion_sat_fit',  extra_points=df[['Ion_sat-n',  'Ion_sat-p']], output_csv=True)
ioff_lin_pca	=DF_PCA(dev_pair_n, dev_pair_p, 'Ioff_lin-n', 'Ioff_lin-p', '@pwd@/@nodedir@/n@node@_Ioff_lin_fit', extra_points=df[['Ioff_lin-n', 'Ioff_lin-p']], output_csv=True)
ioff_sat_pca	=DF_PCA(dev_pair_n, dev_pair_p, 'Ioff_sat-n', 'Ioff_sat-p', '@pwd@/@nodedir@/n@node@_Ioff_sat_fit', extra_points=df[['Ioff_sat-n', 'Ioff_sat-p']], output_csv=True)

# sort the PCA points into corners
cgg_off_pca	=corner_sort(cgg_off_pca, 'v')
cgg_on_pca	=corner_sort(cgg_on_pca, 'v')
vt_lin_pca	=corner_sort(vt_lin_pca, 'v')
vt_sat_pca	=corner_sort(vt_sat_pca, 'v')
ion_lin_pca	=corner_sort(ion_lin_pca, 'i')
ion_sat_pca	=corner_sort(ion_sat_pca, 'i')
ioff_lin_pca	=corner_sort(ioff_lin_pca, 'i')
ioff_sat_pca	=corner_sort(ioff_sat_pca, 'i')


coords = pd.DataFrame(coords)
columns_list = ["type","corner"]
columns_list.extend(axes)
coords.columns=columns_list
coords.set_index(['type','corner'],inplace=True)
print(coords)



# save the DF for future use
ds   = dbi.create_dataset(node_prj.name, "@node@-Corners", clean=True)
dbi.create_data(ds, coords.to_dict("index"))

