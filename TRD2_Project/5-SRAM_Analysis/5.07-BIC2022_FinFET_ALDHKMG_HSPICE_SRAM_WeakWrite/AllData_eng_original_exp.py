#setdep @node|RowData:all@

#if @node:index@ != 1
#noexec
#endif

## additional code"
import numbers
import numpy as np

def coerce_to_numeric(value):
    if isinstance(value, numbers.Number):
        return value
    else:
        return np.NaN

##

nodes = dbi.get_project(swb__tool_label="RowData")
final_df = pd.DataFrame()

for x,node in enumerate(nodes):
   data = pd.DataFrame(node.metadata["array_data"], index=[x])
   final_df = pd.concat([final_df,data])

final_df.sort_values(["nrows","ncolumns"], inplace=True)
final_df.to_csv("n@node@_full_data.csv")


# find VddMin for each cell
from scipy.interpolate import interp1d

cells = list(set("@gds:all@".split()))

for cell in cells:
   cell_data = final_df[final_df["gds"] == cell]
## write_far = cell_data["write_far"].tolist()
## new clean write_far
## clean_write_far = cell_data["write_far"].tolist().apply(coerce_to_numeric)
## clean_write_far = cell_data["write_far"].apply(coerce_to_numeric)
   write_far = cell_data["write_far"].apply(coerce_to_numeric)

   vdd = cell_data["Vdd"].tolist()

   interp  = interp1d(write_far,vdd)
##   interp  = interp1d(clean_write_far,vdd)
##   print ("cell data is:" , cell_data)
##   print ("clean write far is:" , clean_write_far)
##   print ("clean write far is:" , write_far)
##   print ("vdd is:" , vdd)
   print(f"Failure voltage for cell {cell} is {interp(50e-12)}")


