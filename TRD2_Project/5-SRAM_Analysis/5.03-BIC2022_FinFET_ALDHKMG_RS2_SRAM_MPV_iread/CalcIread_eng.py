#setdep @node|iread_sim@

# pull out iread data for all corners
# and determine worst
iread_dic = {}
for corner in ["tt","ss","ff","fs","sf"]:
    data=dbi.get_data(dataset=f"@node|iread_sim@_iread_{corner}-1", strip=True, Type="measures").data
    iread_dic.update({corner:data['iread'][0]})

iread_data = pd.DataFrame.from_dict(iread_dic, orient='index', columns=['iread'])
iread_data.index.name = 'corner'
print(iread_data)
#set iread tbc
print(f"DOE: {iread_data.idxmin()}")
iread_data.to_csv('n@node@_iread.csv')
