#setdep @node|SNM_sim@
import copy
from SRAM_FoM import calcSNM

# for nominal SNM data we take advantage of the fact
# that the SRAM cell response is symmetrical, so we only need to
# simulate one side of the SNM curve
SNM_dic = {}
for corner in ["tt","ss","ff","fs","sf"]:
    vv0_data     = Data.from_db(dataset=f"@node|SNM_sim@_icrit_{corner}-1", Type="iv0")[0]
    vv1_data     = Data.from_db(dataset=f"@node|SNM_sim@_icrit_{corner}-1", Type="iv1")[0]
    print(f"{corner}: {calcSNM(vv0_data, vv1_data)[0]:4g}")
    SNM_dic.update({corner:calcSNM(vv0_data, vv1_data)[0]})

SNM_data = pd.DataFrame.from_dict(SNM_dic, orient='index', columns=['SNM'])
SNM_data.index.name = 'corner'
#set SNM tbc
print(f"DOE: {SNM_data.idxmin()}")
SNM_data.to_csv('n@node@_SNM.csv')
