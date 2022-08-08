
#setdep @node|ArrayWrite@

tba="fail"
full_data={"gds":"@gds@",
           "corner":"@corner@",
           "sim_temp":@sim_temp@,
           "nrows":@nrows@,
           "ncolumns":@ncolumns@,
           "activeWL":@activeWL@,
           "write_near":@write_near@,
           "write_far":@write_far@,
           "Vdd":@Vdd_write@,
}

node_prj.metadata["array_data"]=full_data
node_prj.save()
