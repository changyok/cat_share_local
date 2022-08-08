
#setdep @node|ArrayRead@

tba="fail"
full_data={"gds":"@gds@",
           "corner":"@corner@",
           "sim_temp":@sim_temp@,
           "nrows":@nrows@,
           "ncolumns":@ncolumns@,
           "activeWL":@activeWL@,
           "rise_delay":@rise_delay@,
           "fall_delay":@fall_delay@,
           "read_near":@read_near@,
           "read_far":@read_far@,
           "wl_far_pw":@wl_far_pw@,
           "vbump_near":@vbump_near@,
           "vbump_far":@vbump_far@,
           "Vdd":@Vdd@}

node_prj.metadata["array_data"]=full_data
node_prj.save()
