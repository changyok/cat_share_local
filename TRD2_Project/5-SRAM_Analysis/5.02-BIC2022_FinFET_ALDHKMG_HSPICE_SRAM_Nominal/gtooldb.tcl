lappend WB_tool(file_types) python_netlist
set WB_tool(python_netlist,ext) sp

set WB_tool(enigma_hspice,category) utility
set WB_tool(enigma_hspice,visual_category) utility
set WB_tool(enigma_hspice,acronym) pyt
set WB_tool(enigma_hspice,after) all
set WB_tool(enigma_hspice,cmd_line) "--tcadtospice --nodb --project @pwd@ --node @node@ pp@node@_pyt.cmd"
set Icon(enigma_hspice) $app_data(icon_dir)/python.gif
set WB_tool(enigma_hspice,input) [list commands python_netlist python_vlg pref]

if { $app_data(code_branch) == "traditional" } { 
    set WB_tool(enigma_hspice,setup) { os_ln_rel @commands@ n@node@_pyt.py "@pwd@" }
    set WB_tool(enigma_hspice,epilogue) { extract_vars "$wdir" @stdout@ @node@ }
} else {
    set WB_tool(enigma_hspice,setup) { os_ln_rel @commands@ n@node@_pyt.py "@pwdout@/@nodedir@" }
    set WB_tool(enigma_hspice,epilogue) { extract_vars "$nodedir" @stdout@ @node@ }
}


set WB_tool(enigma_hspice,input,commands,label)  "Python Commands..."
set WB_tool(enigma_hspice,input,commands,editor)  text
set WB_tool(enigma_hspice,output) [list]
set WB_tool(enigma_hspice,output,files) "n@node@_* pp@node@_*"
##set WB_tool(enigma_hspice,epilogue) { extract_vars "$wdir" @stdout@ @node@ }
set WB_tool(enigma_hspice,input,commands,file)   @tool_label@_pyt.py
set WB_tool(enigma_hspice,input,pref,file)  @tool_label@_pyt.prf
set WB_tool(enigma_hspice,input,pref,label)  "Preferences..."
set WB_tool(enigma_hspice,input,pref,editor)  pref
set WB_tool(enigma_hspice,exec_dependency) strict ; # (strict | relaxed) 


set WB_tool(enigma_hspice,input,python_netlist,label)  "HSPICE netlist..."
set WB_tool(enigma_hspice,input,python_netlist,editor)  text
set WB_tool(enigma_hspice,input,python_netlist,file)   @tool_label@_pyt.sp
set WB_tool(enigma_hspice,input,python_netlist,parametrized)  1


set WB_tool(enigma_hspice,available) { check_binary_path enigma_hspice }
lappend WB_tool(all) enigma_hspice


# .tr* .sw* file viewer (waveview)
set WB_viewer(wv,files)    "*n@node@_*.\{tr,sw\}*"
set WB_viewer(wv,label)    "&Waveview (Select File...)"
set WB_viewer(wv,nbfiles)  1
set WB_viewer(wv,cmd_line) "@files@"
set WB_viewer(wv,exec_dir) @pwd@
set WB_binaries(viewer,wv) wv
lappend WB_viewer(all) wv

set WB_binaries(tool,enigma) "gpythonsh -rel R-2020.09-SP1"
set WB_binaries(tool,enigma_hspice) "gpythonsh -rel R-2020.09-SP1"


