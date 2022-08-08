from enigma.commands import startdb,stopdb

from randomspice.rslibrary.builder import BuildLibrary

builder=BuildLibrary(dbi=None, lib_type="SUBCKT")

remap_names={"nMOS":"nfet","pMOS":"pfet"}
node_prj.metadata.update({"remap_names":remap_names})
node_prj.save()

# parent project paths
mysticProjectPaths = ["@pwd@/../../3-SpiceModel/3.02-BIC2022_FinFET_ALDHKMG_Mystic_Corners"]

# data containers used in RS2 simulations
midpoint_metadata = {}
axes_df = pd.DataFrame()
params={'nfet':[], 'pfet':[]}

for prj in mysticProjectPaths:

    startdb(prj)
    # switch db connection
    dburl = open(f"{prj}/enigma/mongodb.conf").read()
    dbi.connect(dburl) 
    builder.dbi=dbi


    ################################################################
    ### the following code is for the midpoint of the DoE only   ###
    ### these base modelcards will be the basis for the response ###
    ### surface model and the variability model                  ###
    ################################################################
    midpoint_projects=dbi.get_project(swb__midpoint="True", \
                                      swb__tool_label="Mystic_Uniform_Enigma", 
                                      strip=False)

    midpoint_metadata.update({p.metadata["swb"]["Type"]:p.metadata for p in dbi.get_project(swb__midpoint="True", swb__tool_label="Mystic_Uniform_Enigma", strip=False)})

    for proj in midpoint_projects:

        remap_name=remap_names[proj.metadata["swb"]["Type"]]

        # add base modelcard
        builder.add_device(remap_name, dev_type=proj.metadata["swb"]["Type"], dataset=list(proj.datasets)[-2], point_model=False)

    print(builder.base_modelcards)

    ###############################################################
    ### the following code is to add response surface models    ###
    ### corresponding to each DoE point                         ###
    ###############################################################
    rs_projects = dbi.get_project(swb__tool_label="Mystic_Response_Surface", strip=False)

    for proj in rs_projects:
               
        dev_midpoint = remap_names[proj.metadata["swb"]["Type"]]
        doe_pt={"l":proj.metadata["swb"]["lgate"],"tfin":proj.metadata["swb"]["tfin"], "nfin":1}
        axes_df=pd.concat([axes_df,pd.DataFrame(doe_pt, index=[0])])

        if proj.metadata["swb"]["midpoint"].lower() == "true":
             midpt=True
        else:
             midpt=False

        # add RSM model points
        builder.add_doe_point(dev_midpoint, doe_pt, dataset=list(proj.datasets)[-3], midpoint=midpt)
        fit_pars=builder.get_db_fit_parameters(dataset=list(proj.datasets)[-3], ensemble_id=0)
        fit_pars={k:v[0] for k,v in fit_pars.items()}
        params[dev_midpoint].append({**doe_pt, **fit_pars})

print(builder.resp_dict)
builder.resp_dict={"nfet":{}, "pfet":{}}

nparams = pd.DataFrame(params['nfet'])
pparams = pd.DataFrame(params['pfet'])
nparams.drop("nfin", axis=1, inplace=True)
pparams.drop("nfin", axis=1, inplace=True)
axes = ["l","tfin"]

from pre_resample import resample_df
nparams, n_resample_list = resample_df(nparams, axes, sampling=10)
pparams, p_resample_list = resample_df(pparams, axes, sampling=10)

for i in nparams.index.values:
    key = f"doe_point l {nparams.loc[i,'l']:.5} tfin {nparams.loc[i,'tfin']:.5} nfin 1"
    builder.resp_dict["nfet"][key]=nparams.loc[[i]]
    builder.resp_dict["nfet"][key].drop("l", inplace=True, axis=1)
    builder.resp_dict["nfet"][key].drop("tfin", inplace=True, axis=1)

for i in pparams.index.values:
    key = f"doe_point l {pparams.loc[i,'l']:.5} tfin {pparams.loc[i,'tfin']:.5} nfin 1"
    builder.resp_dict["pfet"][key]=pparams.loc[[i]]
    builder.resp_dict["pfet"][key].drop("l", inplace=True, axis=1)
    builder.resp_dict["pfet"][key].drop("tfin", inplace=True, axis=1)


print(builder.resp_dict)

################################################################
### Add the PHIG variation to the DoE			########
################################################################

import copy
phigdeltas=[-0.05, 0.0, 0.05] 
new_par="phigvar"
devs=builder.resp_dict.keys()

new_resp={}
new_doe={}
for d in devs:
    new_resp[d]={}
    new_doe[d]=[]
    doe_pts=builder.resp_dict[d].keys()
    dtype=builder.dev_types[d]
    modelpar="phigvar"

    #### only needs done once
    builder.midpoint_dict[d][new_par]=phigdeltas[1]
    ####

    for phigdelta in phigdeltas:
        for doe_pt in doe_pts:
            l1=doe_pt.split()[1:]
            l1_0=l1[::2]
            l1_0.append(new_par)
            l1_1=l1[1::2]
            l1_1.append(phigdelta)
            new_dict=dict(zip(l1_0,l1_1))
            new_dict={k:float(v) for k,v in new_dict.items()}
            new_doe[d].append(new_dict)
            new_doe_pt="doe_point {0}".format(" ".join(["{0} {1}".format(k,v) for k,v in list(new_dict.items())]))
            new_resp[d][new_doe_pt]=copy.deepcopy(builder.resp_dict[d][doe_pt])
            new_resp[d][new_doe_pt][modelpar]+=phigdelta

builder.resp_dict=new_resp
print(builder.doe_dict)
print(new_doe)

builder.doe_dict=new_doe


# switch db connection
dburl = open("@pwd@/enigma/mongodb.conf").read()
dbi.connect(dburl) 
builder.dbi=dbi


axlist=[a.split()[1:] for a in list(builder.resp_dict['nfet'].keys())]
dictlist=[dict(zip(a[0::2],a[1::2])) for a in axlist]
axdf=pd.DataFrame(dictlist)
axdf=axdf.astype(float)
axdf.drop("nfin", axis=1, inplace=True)
print(axdf)

## this code is here so we can avoid doing DB metadata
## queries in the RandomSpice stages
node_prj.metadata.update({"axes_df":axdf})
node_prj.metadata.update({"midpoint_metadata":midpoint_metadata})
node_prj.save()

################################################################
####    the following code is to add Process generators     ####
####     In this case this is for (Lg and Tfin)             ####
################################################################
# setup the prototye of the DoE axes headers
# should look like: LG_N237_N
axis1_header = "@axis1@_{0}_{1}" # L
axis2_header = "@axis2@_{0}_{1}" # TFIN
axis3_header = "@axis3@_{0}_{1}" # PHIG

device1 = remap_names["nMOS"]
device2 = remap_names["pMOS"]
device1_type = "nmos"
device2_type = "pmos"

# ratio splitting for total variability
gv_ratio_lg = @gv_ratio_lg@
lv_ratio_lg = 1-gv_ratio_lg
gv_ratio_tfin = @gv_ratio_tfin@
lv_ratio_tfin = 1-gv_ratio_tfin
gv_ratio_phig = @gv_ratio_phig@
lv_ratio_phig = 1-gv_ratio_phig

# build the list of the headers
# the header should be 2*(No of DoE axes) length
headers = [axis1_header.format(device1,device1_type), axis1_header.format(device2,device2_type),\
           axis2_header.format(device1,device1_type), axis2_header.format(device2,device2_type),\
           axis3_header.format(device1,device1_type), axis3_header.format(device2,device2_type),\
          ]

# this is added manually for now
          # NLg,               PLg,                NTFIN,             PTFIN,             NPHIGVAR,                    PPHIGVAR
means   = [@axis1_midpoint@,    @axis1_midpoint@,    @axis2_midpoint@,       @axis2_midpoint@,      0.0,                      0.0] 
stdv	= [(gv_ratio_lg*(@lg_sigma@**2))**0.5,      (gv_ratio_lg*(@lg_sigma@**2))**0.5, 
           (gv_ratio_tfin*(@tfin_sigma@**2))**0.5,    (1.45*gv_ratio_tfin*(@tfin_sigma@**2))**0.5, 
           (gv_ratio_phig*(@phigvar_sigma@**2))**0.5, (gv_ratio_phig*(@phigvar_sigma@**2))**0.5] 

              # NLg,  PLg,  NTFIN, PTFIN,NWF,   PWF 
corr_matrix = [[1.0,  0.9,  0.05,  0.05, 0.05,  0.05],  #NLg	corr w/PLg = 0.9
               [0.9,  1.0,  0.05,  0.05, 0.05,  0.05],  #PLg	corr w/NLg = 0.9
               [0.05, 0.05, 1.0,   0.9,  0.05,  0.05],  #NTFIN  corr w/TFIN = 0.9
               [0.05, 0.05, 0.9,   1.0,  0.05,  0.05],  #PTFIN  corr w/TFIN = 0.9
               [0.05, 0.05, 0.05,  0.05, 1.0,   0.9 ],  #PWF    corr w/WF = 0.9
               [0.05, 0.05, 0.05,  0.05, 0.9,   1.0 ]]  #PWF    corr w/WF = 0.9



builder.add_gv_distributions(device1, device2, headers=headers, sigmas=stdv, means=means,corr_matrix=corr_matrix, all_parameters=None)


################################################################
####    Add new LVRSM parameters 			    ####
################################################################
headers1 = [axis1_header.format(device1,device1_type),
           axis2_header.format(device1,device1_type),
           axis3_header.format(device1,device1_type),
          ]
headers2 = [axis1_header.format(device2,device2_type),
           axis2_header.format(device2,device2_type),
           axis3_header.format(device2,device2_type),
          ]
stdv	= [(lv_ratio_lg*(@lg_sigma@**2))**0.5, (lv_ratio_tfin*(@tfin_sigma@**2))**0.5, (lv_ratio_phig*(@phigvar_sigma@**2))**0.5] 
stdvp	= [(lv_ratio_lg*(@lg_sigma@**2))**0.5, (1.45*lv_ratio_tfin*(@tfin_sigma@**2))**0.5, (lv_ratio_phig*(@phigvar_sigma@**2))**0.5] 
corr_matrix = np.identity(len(headers1))

builder.add_lvrsm_distributions(device1, headers=headers1, sigmas=stdv, corr_matrix=corr_matrix, all_parameters=None)
builder.add_lvrsm_distributions(device2, headers=headers2, sigmas=stdvp, corr_matrix=corr_matrix, all_parameters=None)

print("building")
# save the library
builder.build("@pwd@/@nodedir@", libname="{0}".format("n@node@_library"), doe=True, gv_dist=True, lv_dist=True, debug=True, non_unif_gv=False)






