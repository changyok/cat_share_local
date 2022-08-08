#setdep @node|BuildLibrary@

from enigma.commands import startdb,stopdb

# parent project paths
CornerPath_TX  = "@pwd@/../4.02-BIC2022_FinFET_ALDHKMG_RS2_Corners_TX"
CornerPath_PEX = "@pwd@/../4.03-BIC2022_FinFET_ALDHKMG_RS2_Corners_PEX"


if @Corners_TX@ == True:


    # switch db connection
    startdb(CornerPath_TX)
    dburl = open(f"{CornerPath_TX}/enigma/mongodb.conf").read()
    dbi.connect(dburl) 

    # get corner information from FE projet
    corner_project = dbi.get_project(swb__tool_label="ExtractCorners", swb__sim_temp=@sim_temp@, swb__gv="True", swb__lv="False").name
    corner_data = dbi.get_data(project=corner_project).data
    print(corner_data)

    # switch db connection
    #stopdb(CornerPath_TX)
    dburl = open(f"@pwd@/enigma/mongodb.conf").read()
    dbi.connect(dburl)

    # save the DF for future use
    ds   = dbi.create_dataset(node_prj.name, "@node@-Corners", clean=True)
    dbi.create_data(ds, corner_data)


if @Corners_PEX@ == True:

    # switch db connection
    startdb(CornerPath_PEX)
    dburl = open(f"{CornerPath_PEX}/enigma/mongodb.conf").read()
    dbi.connect(dburl) 

    # get fast/slow PEX path
    corner_project = dbi.get_project(swb__tool_label="GetCircuitSimData_RSM")
    slow_corner_index = corner_project.metadata["pex_slow"]
    fast_corner_index = corner_project.metadata["pex_fast"]

    # switch db connection
    #stopdb(CornerPath_PEX)
    dburl = open(f"@pwd@/enigma/mongodb.conf").read()
    dbi.connect(dburl)

    node_prj=dbi.get_project("@node@")
    node_prj.metadata["fast_pex_isplit"]=slow_corner_index
    node_prj.metadata["slow_pex_isplit"]=fast_corner_index
    node_prj.save()

