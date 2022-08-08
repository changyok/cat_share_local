#setdep @node|Mystic_Response_Surface@

#if "@Type@" == "tbc" 
#noexec

#else

# Mystic plot node labels
set gate_label @gate_con@
set drain_label @drain_con@
set source_label @drain_con@
set cap_label c(@acgate_con@,@acgate_con@)

set DEVNAME n@node|Mystic_Response_Surface@

### load garand target
#if "@Type@" == "nMOS"
set vdlin @Vdd_lin@
set vdd @Vdd_nom@
set zero 0.0
set idvds {0.5 0.65}
#else
set vdlin @Vdd_lin@
set vdd @Vdd_nom@
set zero 0.0
set bodylist {0.0}
set idvds {-0.5 -0.65}
#endif

set temps {-40 27 125}
set cols  {blue green red}

set PLOTNAME IdVg
create_plot -1d -name $PLOTNAME

foreach t $temps c $cols} {

  set idvgld idvg_temp${t}-@drain_con@$vdlin\_@source_con@$zero\_@bulk_con@$zero
  set idvghd idvg_temp${t}-@drain_con@$vdd\_@source_con@$zero\_@bulk_con@$zero

  load_file @pwd@/@nodedir|Mystic_Response_Surface@/${DEVNAME}_$idvgld.plt
  load_file @pwd@/@nodedir|Mystic_Response_Surface@/${DEVNAME}_$idvghd.plt

  ################### IdVg plot ###################

  create_curve -name ld_target_log$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent target}"
  set_curve_prop ld_target_log$t -label ld_target_log -color black -show_markers -markers_size 9 -markers_type circle -line_width 3

  create_curve -name hd_target_log$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent target}"
  set_curve_prop hd_target_log$t -label hd_target_log -color black -show_markers -markers_size 9 -markers_type circle -line_width 3

  create_curve -name ld_fit_log$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent fitted}"
  set_curve_prop ld_fit_log$t -label ld_fit_log -color $c -line_style dash -line_width 3

  create_curve -name hd_fit_log$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent fitted}"
  set_curve_prop hd_fit_log$t -label hd_fit_log -color $c -line_style dash -line_width 3


  create_curve -name ld_target$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent target}"
  set_curve_prop ld_target$t -label ld_target -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend

  create_curve -name hd_target$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent target}"
  set_curve_prop hd_target$t -label hd_target -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend

  create_curve -name ld_fit$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent fitted}"
  set_curve_prop ld_fit$t -label ld_fit -color $c -line_style dash -line_width 3 -hide_legend

  create_curve -name hd_fit$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent fitted}"
  set_curve_prop hd_fit$t -label hd_fit -color $c -line_style dash -line_width 3 -hide_legend

}

set_axis_prop -plot $PLOTNAME -axis y2 -title Id(A) -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 
set_axis_prop -plot $PLOTNAME -axis y -type log -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 
set_axis_prop -plot $PLOTNAME -axis x -title Vg -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -manual_spacing -spacing 0.1
set_axis_prop -plot $PLOTNAME -axis y -title log(Id(A)) -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 

export_view n@node@_Temp_IdVg.png -plots $PLOTNAME -format png -overwrite

#windows_style -style max
#endif
