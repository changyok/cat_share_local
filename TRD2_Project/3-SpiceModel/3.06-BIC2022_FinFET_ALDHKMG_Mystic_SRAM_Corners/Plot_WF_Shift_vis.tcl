#setdep @node|Cal_WF_Shift@

#if "@Type@" != "nMOS" || "@midpoint@" != "True"
#noexec
#endif

set gate_label [string range [string tolower @gate_con@] 1 end]
set drain_label [string range [string tolower @drain_con@] 1 end]
set source_label [string range [string tolower @source_con@] 1 end]

puts $source_label

set DEVNAME n@node|Cal_WF_Shift@

set name_list {svt lvt ulvt}
set vdd @Vdd_nom@
set vddp -@Vdd_nom@
set bodylist {0.0}
set zero 0.0

#################### IdVg plot ###################
foreach name $name_list {
 set PLOTNAME IdVg-$name
 create_plot -1d -name $PLOTNAME
 set_plot_prop -plot $PLOTNAME 

 foreach vb $bodylist {
    set nmosidvg nmos-$name-n$drain_label$vdd\_n$source_label$zero\_@bulk_con@$vb
    set pmosidvg pmos-$name-p$drain_label$vddp\_p$source_label$zero\_@bulk_con@$vb

    load_file @pwd@/@nodedir|Cal_WF_Shift@/$DEVNAME-$nmosidvg.plt
    load_file @pwd@/@nodedir|Cal_WF_Shift@/$DEVNAME-$pmosidvg.plt


    create_curve -name nmos_target_log_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$nmosidvg -axisX "{n$gate_label OuterVoltage}" -axisY "{n$drain_label TotalCurrent target}"
    set_curve_prop nmos_target_log_vb$vb -label nmos_target_log_vb$vb -color black -markers_type circle -line_width 3 -function abs

    create_curve -name pmos_target_log_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$pmosidvg -axisX "{p$gate_label OuterVoltage}" -axisY "{p$drain_label TotalCurrent target}"
    set_curve_prop pmos_target_log_vb$vb -label pmos_target_log_vb$vb -color black -markers_type circle -line_width 3 -function abs

    create_curve -name nmos_fit_log_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$nmosidvg -axisX "{n$gate_label OuterVoltage}" -axisY "{n$drain_label TotalCurrent fitted}"
    set_curve_prop nmos_fit_log_vb$vb -label nmos_fit_log_vb$vb -color red -line_style dash -line_width 3 -function abs -hide_legend 

    create_curve -name pmos_fit_log_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$pmosidvg -axisX "{p$gate_label OuterVoltage}" -axisY "{p$drain_label TotalCurrent fitted}"
    set_curve_prop pmos_fit_log_vb$vb -label pmos_fit_log_vb$vb -color red -line_style dash -line_width 3 -function abs -hide_legend 


    set_axis_prop -plot $PLOTNAME -axis y -type log 
    set_axis_prop -plot $PLOTNAME -axis x -title Vg -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -manual_spacing -spacing 0.2
    set_axis_prop -plot $PLOTNAME -axis y -title log(Id(A)) -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 

    create_curve -name nmos_target_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$nmosidvg -axisX "{n$gate_label OuterVoltage}" -axisY2 "{n$drain_label TotalCurrent target}"
    set_curve_prop nmos_target_vb$vb -label nmos_target_vb$vb -color black -markers_type circle -line_width 3 -function abs

    create_curve -name pmos_target_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$pmosidvg -axisX "{p$gate_label OuterVoltage}" -axisY2 "{p$drain_label TotalCurrent target}"
    set_curve_prop pmos_target_vb$vb -label pmos_target_vb$vb -color black -markers_type circle -line_width 3 -function abs

    create_curve -name nmos_fit_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$nmosidvg -axisX "{n$gate_label OuterVoltage}" -axisY2 "{n$drain_label TotalCurrent fitted}"
    set_curve_prop nmos_fit_vb$vb -label nmos_fit_vb$vb -color red -line_style dash -line_width 3 -hide_legend -function abs

    create_curve -name pmos_fit_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$pmosidvg -axisX "{p$gate_label OuterVoltage}" -axisY2 "{p$drain_label TotalCurrent fitted}"
    set_curve_prop pmos_fit_vb$vb -label pmos_fit_vb$vb -color red -line_style dash -line_width 3 -hide_legend -function abs
 }

 set_axis_prop -plot $PLOTNAME -axis y2 -title Id(A) -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 
 export_view n@node@_WF_Shift_IdVg_HD_$name.png -plots $PLOTNAME -format png -overwrite
}
