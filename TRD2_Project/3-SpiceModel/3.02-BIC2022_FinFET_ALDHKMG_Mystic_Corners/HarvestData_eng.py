from enigma.commands import startdb,stopdb

TCAD_ROOT_path="@pwd@/../../1-AdvancedTransport/"
TCAD_paths = [f"{TCAD_ROOT_path}/1.01-BIC2022_FinFET_ALDHKMG_TCAD_Nominal",
              f"{TCAD_ROOT_path}/1.03-BIC2022_FinFET_ALDHKMG_TCAD_Nominal_Temperature",
              f"{TCAD_ROOT_path}/1.04-BIC2022_FinFET_ALDHKMG_TCAD_ChannelLength",
              f"{TCAD_ROOT_path}/1.05-BIC2022_FinFET_ALDHKMG_TCAD_FinWidth"]

# create DB storage location
ds = dbi.create_dataset(node_prj, "@node@-data", clean=True)

for path in TCAD_paths:
    startdb(path)

    # switch DB to harvest data
    proj_conf = f"{path}/enigma/mongodb.conf"
    dburl = open(proj_conf).read()
    dbi.connect(dburl) 
    Data.set_dburl(dburl)

    data = Data.from_db()

    # switch back to this DB
    proj_conf = f"@pwd@/enigma/mongodb.conf"
    dburl = open(proj_conf).read()
    dbi.connect(dburl) 
    Data.set_dburl(dburl)

    for d in data: 
        d.to_db(ds)
    
    stopdb(path)

#set acbulk_con		tbc
#set acdrain_con	tbc
#set acgate_con		tbc
#set acsource_con	tbc
#set bulk_con		tbc
#set drain_con		tbc
#set gate_con		tbc
#set source_con		tbc
#set tnom		tbc
#set hfin		tbc
#set tspacer		tbc
#set eot		tbc
#set nsd		tbc
#set nch		tbc
#set workfn		tbc
#set midpoint		tbc
#set Vdd_lin		tbc
#set Vdd_nom		tbc
#set lowT		tbc
#set highT		tbc
#set avgStrains         tbc
#set avgStrainNom        tbc
#set stress_vt          tbc
#set stress_cur         tbc
#set layout_dep         0
#set layout_dep_result  tbc
#set StressInf          0


