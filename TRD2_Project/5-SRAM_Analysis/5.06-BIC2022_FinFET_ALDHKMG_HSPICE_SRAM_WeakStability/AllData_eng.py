#setdep @node|RowData:all@

#if @node:index@ != 1
#noexec
#endif

nodes = "@node|RowData:all@".split()
final_df = pd.DataFrame()

for x,node in enumerate(nodes):
    try:
        node = dbi.get_project(node)
    except DBException:
        continue
    data = pd.DataFrame(node.metadata["array_data"], index=[x])
    final_df = pd.concat([final_df,data])

final_df.sort_values(["nrows","ncolumns"], inplace=True)
final_df.to_csv("n@node@_full_data.csv")






