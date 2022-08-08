#setdep @node|RowData:all@

from scipy.interpolate import interp1d

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

# find VddMin for each cell
cells = list(set("@gds:all@".split()))

for cell in cells:
   cell_data = final_df[final_df["gds"] == cell]
   cell_data = cell_data.convert_objects(convert_numeric=True).dropna()  # drop "failed" lines
   write_far = cell_data["write_far"].tolist()
   vdd = cell_data["Vdd"].tolist()

   #print(cell, write_far, vdd)
   interp  = interp1d(write_far,vdd)
   print(f"Failure voltage for cell {cell} is {interp(50e-12)}")


