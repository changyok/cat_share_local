set WB_binaries(tool,sprocess) "sprocess -rel R-2020.09"
set WB_binaries(tool,snmesh) "snmesh -rel R-2020.09"
set WB_binaries(tool,sband) "sband -rel R-2020.09"
set WB_binaries(tool,sdevice) "sdevice -rel R-2020.09"
set WB_binaries(tool,svisual) "svisual -rel R-2020.09"
set WB_binaries(tool,genopt) "genopt -rel R-2020.09"

set WB_binaries(tool,garandmc) "@binary@ -rel R-2020.09"
set WB_binaries(tool,enigma) "gpythonsh -rel R-2020.09"

set WB_viewer(png,files)  "*.png"
set WB_viewer(png,label)  "PNG file (Select PNG File...)"
set WB_viewer(png,nbfiles)  1
set WB_viewer(png,cmd_line)  @files@
set WB_viewer(png,exec_dir)  @pwd@
set WB_binaries(viewer,png)  eog
lappend WB_viewer(all) png
