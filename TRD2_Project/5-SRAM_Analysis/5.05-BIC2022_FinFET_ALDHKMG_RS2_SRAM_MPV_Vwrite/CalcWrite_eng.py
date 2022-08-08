#setdep @node|write_sim@

# pull out write data for all corners
# and determine worst
write_dic = {}
for corner in ["tt","ss","ff","fs","sf"]:
    data=dbi.get_data(dataset=f"@node|write_sim@_write_{corner}-1", strip=True, Type="measures").data
    write_dic.update({corner:data['vwrite'][0]})

write_data = pd.DataFrame.from_dict(write_dic, orient='index', columns=['write'])
write_data.index.name = 'corner'
print(write_data)
#set write tbc
print(f"DOE: {write_data.idxmin()}")
write_data.to_csv('n@node@_write.csv')
