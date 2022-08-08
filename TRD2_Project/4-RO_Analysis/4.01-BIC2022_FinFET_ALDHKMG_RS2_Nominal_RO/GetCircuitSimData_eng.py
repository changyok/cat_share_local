#setdep @node|RO_Corner_Sim@

data=pd.DataFrame()

prj=dbi.get_project("@node|RO_Corner_Sim@")

full_data=[]

if @Corners_TX@ == True:
    corners  = ["ss", "fs", "tt", "sf", "ff"]
else:
    corners  = ["tt"]

for corner in corners:
    d=dbi.get_dataset(f"@node|RO_Corner_Sim@_RO_{corner}")

    print(corner)

    data=[d.data for d in dbi.get_data(project="@node|RO_Corner_Sim@", dataset=f"@node|RO_Corner_Sim@_RO_{corner}", strip=False)]

    data=pd.DataFrame(data[0])
    print(data)

    with open(f"n@node@_{corner}_@logic@X@strength@@height@.csv", 'w') as f:
        data.to_csv(f)

