#setdep @node|CV@ @node|-1:all@

import glob

# IdVg data should be n@node|generatePLT@_*GarandMCnew_IdVg*.plt
# IdVd data should be n@node|generatePLT@_*GarandMC_IdVd*.plt
# CV data should be *n@node|CV@_ac_*.plt

## setup terminal names
if "@Type@".lower() == "nmos":
    terminal_dict = {"gate_con":"ngate", "source_con":"nsource", "drain_con":"ndrain", "bulk_con":"substrate"}
elif "@Type@".lower() == "pmos":
    terminal_dict = {"gate_con":"pgate", "source_con":"psource", "drain_con":"pdrain", "bulk_con":"substrate"}
terminal_dict.update({"acgate_con":"g", "acsource_con":"s", "acdrain_con":"d", "acbulk_con":"b"})

## setup terminal lists
dc_nodes_list=[terminal_dict["drain_con"],terminal_dict["gate_con"],terminal_dict["source_con"],terminal_dict["bulk_con"]]
ac_nodes_list=[terminal_dict["acdrain_con"],terminal_dict["acgate_con"],terminal_dict["acsource_con"],terminal_dict["acbulk_con"]]

temp	= int(@<Temperature+273>@)
lg 	= @Lg@*1e-9
tfin	= @W@*1e-9
hfin	= @H@*1e-9
tspacer = @Tspacer@*1e-9
eot     = (@Tiox@*3.9/@iOxide_perm@+@Thfo2@*3.9/@HfO2_perm@)*1e-9
WF      = @WF_init@
nsd	= @Nsde@*1e6
nch	= @Nch@*1e6
avgStrain = @Sl_GPa@

## setup metadata dicts
metadata_dict = {"tnom":300, "temperature":temp,
                 "instances":{"l":float(f"{lg:.5}"), "nfin":1, "avgStrain":avgStrain},
                 "tfin":float(f"{tfin:.5}"), "hfin":float(f"{hfin:.5}"), "tspacer":float(f"{tspacer:.5}"), 
                 "eot":float(f"{eot:.5}"), "workfn":float(f"{WF:.5}"),
                 "nsd":float(f"{nsd:.5}"), "nch":float(f"{nch:.5}"), "dtype":"@Type@", "TechType":"@TechType@", "terminals":terminal_dict}

# create DB storage location
ds = dbi.create_dataset(node_prj, "@node@-data", clean=True)

# handle IdVg files
idvg_files = glob.glob("@pwd@/n@node|generatePLT@_*GarandMCnew_IdVg*.plt")
Data.from_plt(idvg_files, ivar=f"v{terminal_dict['gate_con']}",
              metadata={**metadata_dict, "nodes":dc_nodes_list}, upload_ds=ds)


# handle IdVd files
idvd_files = glob.glob("@pwd@/n@node|generatePLT@_*GarandMC_IdVd*.plt")
d=Data.from_plt(idvd_files, ivar=f"v{terminal_dict['drain_con']}",
              metadata={**metadata_dict, "nodes":dc_nodes_list}, upload_ds=ds)
print(d)

## handle CV files (only once per device)
#if @Vg@ == 0.0 && abs(@Vd@) == 0.05
cv_files = glob.glob("@pwd@/*n@node|CV@_ac_*.plt")
Data.from_plt(cv_files, ivar=f"v{terminal_dict['acgate_con']}",
              metadata={**metadata_dict, "nodes":ac_nodes_list}, upload_ds=ds)

#endif


