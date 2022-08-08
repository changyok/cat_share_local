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
set idvds {@Vdd_nom@}
#define _maxCurrent_ 0.00018
#define _maxCap_ 8.5e-17
#else
set vdlin @Vdd_lin@
set vdd @Vdd_nom@
set zero 0.0
set bodylist {0.0}
set idvds {@Vdd_nom@}
#define _maxCurrent_ 0.00012
#define _maxCap_ 8.5e-17
#endif


set temps {@lowT@ @tnom@ @highT@}
set cols  {blue green red}

set idvgld idvg-@drain_con@$vdlin\_@source_con@$zero\_@bulk_con@$zero
set idvghd idvg-@drain_con@$vdd\_@source_con@$zero\_@bulk_con@$zero

load_file @pwd@/@nodedir|Mystic_Response_Surface@/${DEVNAME}_$idvgld.plt
load_file @pwd@/@nodedir|Mystic_Response_Surface@/${DEVNAME}_$idvghd.plt

#################### IdVg plot ###################


set PLOTNAME IdVg
create_plot -1d -name $PLOTNAME
create_curve -name ld_target_log -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent target}"
set_curve_prop ld_target_log -label ld_target_log -color black -show_markers -markers_size 9 -markers_type circle -line_width 3

create_curve -name hd_target_log -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent target}"
set_curve_prop hd_target_log -label hd_target_log -color black -show_markers -markers_size 9 -markers_type circle -line_width 3

create_curve -name ld_fit_log -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent fitted}"
set_curve_prop ld_fit_log -label ld_fit_log -color red -line_style dash -line_width 3 -show_line

create_curve -name hd_fit_log -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent fitted}"
set_curve_prop hd_fit_log -label hd_fit_log -color red -line_style dash -line_width 3 -show_line


set_axis_prop -plot $PLOTNAME -axis y -type log
set_axis_prop -plot $PLOTNAME -axis x -title Vg -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -manual_spacing -spacing 0.2
set_axis_prop -plot $PLOTNAME -axis y -title log(Id(A)) -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -range {1e-12 _maxCurrent_ }

create_curve -name ld_target -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent target}"
set_curve_prop ld_target -label ld_target -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -function abs

create_curve -name hd_target -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent target}"
set_curve_prop hd_target -label hd_target -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -function abs

create_curve -name ld_fit -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent fitted}"
set_curve_prop ld_fit -label ld_fit -color red -line_style dash -line_width 3 -hide_legend -function abs -show_line

create_curve -name hd_fit -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent fitted}"
set_curve_prop hd_fit -label hd_fit -color red -line_style dash -line_width 3 -hide_legend -function abs -show_line

set_axis_prop -plot $PLOTNAME -axis y2 -title Id(A) -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -range {0.0 _maxCurrent_ } -hide_title

#if "@Type@" == "pMOS"
set_legend_prop -plot $PLOTNAME -location top_right -font_size 14 -color_fg white
#else
set_legend_prop -plot $PLOTNAME -position {0.3 0.25} -font_size 14 -color_fg white
#endif
export_view n@node@_Mystic_Resp_IdVg.png -plots $PLOTNAME -format png -overwrite

#################### IdVd plot ###################
set col_list {black red green blue purple}
set PLOTNAME IdVd

create_plot -1d -name $PLOTNAME
foreach vg $idvds {
    set idvd idvd-@gate_con@$vg\_@source_con@$zero\_@bulk_con@$zero
    set idvd_filename @pwd@/@nodedir|Mystic_Response_Surface@/${DEVNAME}_$idvd.plt
    if { [file exists $idvd_filename] == 1} {
      load_file $idvd_filename

      create_curve -name vg_target_$vg -plot $PLOTNAME -dataset ${DEVNAME}_$idvd -axisX "{$drain_label OuterVoltage}" -axisY "{$source_label TotalCurrent target}"
      set_curve_prop vg_target_$vg -label vg_target_$vg -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -function abs
      create_curve -name vg_fit_$vg -plot $PLOTNAME -dataset ${DEVNAME}_$idvd -axisX "{$drain_label OuterVoltage}" -axisY "{$source_label TotalCurrent fitted}"
      set_curve_prop vg_fit_$vg -label vg_fit_$vg -color red -line_style dash -line_width 3 -function abs -show_line
    }
      
  }

set_axis_prop -plot $PLOTNAME -axis x -title Vd -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -manual_spacing -spacing 0.1
set_axis_prop -plot $PLOTNAME -axis y -title Id -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -range {0.0 _maxCurrent_}

#if "@Type@" == "pMOS"
set_legend_prop -plot $PLOTNAME -font_size 10 -color_fg white -location top_right
#else
set_legend_prop -plot $PLOTNAME -font_size 10 -color_fg white -location bottom_left
#endif
export_view n@node@_Mystic_Resp_IdVd.png -plots $PLOTNAME -format png -overwrite

#################### CggVg plot ###################
set cvld cggvg-d$zero\_s$zero\_b$zero
load_file @pwd@/@nodedir|Mystic_Response_Surface@/${DEVNAME}_$cvld.plt
set PLOTNAME CggVg

create_plot -1d -name $PLOTNAME
create_curve -name CggVg_target -plot $PLOTNAME -dataset ${DEVNAME}_$cvld -axisX "{v(@acgate_con@)}" -axisY "{$cap_label target}"
set_curve_prop  CggVg_target -label  CggVg_target_vd0 -color black -show_markers -markers_size 9 -markers_type circle -line_width 3
create_curve -name CggVg_fit -plot $PLOTNAME -dataset ${DEVNAME}_$cvld -axisX "{v(@acgate_con@)}" -axisY "{$cap_label fitted}"
set_curve_prop CggVg_fit -label CggVg_fit -color red -line_style dash -line_width 3 -show_line
 
#if "@Type@" == "pMOS"
set_axis_prop -plot $PLOTNAME -axis x -title Vg -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -manual_spacing -spacing 0.2 -range {@Vdd_nom@ 0.0}
#else
set_axis_prop -plot $PLOTNAME -axis x -title Vg -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -manual_spacing -spacing 0.2 -range {0.0 @Vdd_nom@}
#endif
set_axis_prop -plot $PLOTNAME -axis y -title Cgg  -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -range {0.0 _maxCap_}
set_legend_prop -plot $PLOTNAME -font_size 14 -color_fg white -location bottom_right
export_view n@node@_Mystic_Resp_CV.png -plots $PLOTNAME -format png -overwrite


################### IdVg plot temperature dependence ###################
if {(@tnom@ != @highT@) && (@tnom@ != @lowT@)} {
  set PLOTNAME IdVg_temp
  create_plot -1d -name $PLOTNAME

  foreach t $temps c $cols {

   	set t [expr int([expr $t-273])]
    set idvgld idvg_temp${t}-@drain_con@$vdlin\_@source_con@$zero\_@bulk_con@$zero
    set idvghd idvg_temp${t}-@drain_con@$vdd\_@source_con@$zero\_@bulk_con@$zero

    load_file @pwd@/@nodedir|Mystic_Response_Surface@/${DEVNAME}_$idvgld.plt
    load_file @pwd@/@nodedir|Mystic_Response_Surface@/${DEVNAME}_$idvghd.plt

  

    create_curve -name ld_target_log$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent target}"
    set_curve_prop ld_target_log$t -label ld_target_log -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -function abs

    create_curve -name hd_target_log$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent target}"
    set_curve_prop hd_target_log$t -label hd_target_log -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -function abs

    create_curve -name ld_fit_log$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent fitted}"
    set_curve_prop ld_fit_log$t -label ld_fit_log -color $c -line_style dash -line_width 3 -function abs -show_line

    create_curve -name hd_fit_log$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$source_label TotalCurrent fitted}"
    set_curve_prop hd_fit_log$t -label hd_fit_log -color $c -line_style dash -line_width 3 -function abs -show_line


    create_curve -name ld_target$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent target}"
    set_curve_prop ld_target$t -label ld_target -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -function abs

    create_curve -name hd_target$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent target}"
    set_curve_prop hd_target$t -label hd_target -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -function abs

    create_curve -name ld_fit$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent fitted}"
    set_curve_prop ld_fit$t -label ld_fit -color $c -line_style dash -line_width 3 -hide_legend -function abs -show_line

    create_curve -name hd_fit$t -plot $PLOTNAME -dataset ${DEVNAME}_$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$source_label TotalCurrent fitted}"
    set_curve_prop hd_fit$t -label hd_fit -color $c -line_style dash -line_width 3 -hide_legend -function abs -show_line
  
  }


  set_axis_prop -plot $PLOTNAME -axis y2 -title Id(A) -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -range {0.0 _maxCurrent_} -hide_title
  set_axis_prop -plot $PLOTNAME -axis y -type log -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 
  set_axis_prop -plot $PLOTNAME -axis x -title Vg -title_font_family "Arial" -title_font_size 24 -scale_font_size 22 -manual_spacing -spacing 0.2
  set_axis_prop -plot $PLOTNAME -axis y -title log(Id(A)) -title_font_family "Arial" -title_font_size 24 -scale_font_size 22  -range {1e-12 _maxCurrent_}

  export_view n@node@_Temp_IdVg.png -plots $PLOTNAME -format png -overwrite
}

#################### IdVg plot (Stress dependence) ###################
set avgStrains {@avgStrains@}

if { [llength $avgStrains] > 1 } {
  set PLOTNAME IdVg_stress
  create_plot -1d -name $PLOTNAME
  set_plot_prop -plot $PLOTNAME -hide_title

  set colorlist {red purple blue green yellow cyan}

## add the additional strain values (just to plot)
  set NumAddStrain [expr [llength $avgStrains]-1]

  for { set i 0 } { $i < $NumAddStrain } {incr i} {
   puts $i
   set addstrain [expr 0.5*([lindex $avgStrains $i] + [lindex $avgStrains [expr $i+1]])]
   puts $addstrain
   lappend avgStrains $addstrain
  }


  set colorstrains {}
  for { set i 0} {$i < [llength $avgStrains]} {incr i} {
   lappend colorstrains [lindex $colorlist $i]
  }

  foreach st $avgStrains c $colorstrains {
    if { $st == 0 } {
              set idvgld idvg_hd_stress_${zero}-@drain_con@$vdlin\_@source_con@$zero\_@bulk_con@$zero
              set idvghd idvg_hd_stress_${zero}-@drain_con@$vdd\_@source_con@$zero\_@bulk_con@$zero
    } else {
       set idvgld idvg_hd_stress_${st}-@drain_con@$vdlin\_@source_con@$zero\_@bulk_con@$zero
       set idvghd idvg_hd_stress_${st}-@drain_con@$vdd\_@source_con@$zero\_@bulk_con@$zero
    }
    load_file @pwd@/@nodedir|Mystic_Response_Surface@/$DEVNAME-$idvgld.plt
    load_file @pwd@/@nodedir|Mystic_Response_Surface@/$DEVNAME-$idvghd.plt

    create_curve -name ld_target_log_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent target}"
    set_curve_prop ld_target_log_st$st -label ld_target_log_st$st -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line -function abs

    create_curve -name ld_fit_log_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent fitted}"
    set_curve_prop ld_fit_log_st$st -label ld_fit_log_st$st -color $c -line_style dash -line_width 3 -function abs -show_line

    create_curve -name hd_target_log_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent target}"
    set_curve_prop hd_target_log_st$st -label hd_target_log_st$st -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line -function abs

    create_curve -name hd_fit_log_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent fitted}"
    set_curve_prop hd_fit_log_st$st -label hd_fit_log_st$st -color $c -line_style dash -line_width 3 -function abs -show_line


    set_axis_prop -plot $PLOTNAME -axis y -type log 
    set_axis_prop -plot $PLOTNAME -axis x -title Vg -title_font_family "Arial" -title_font_size 16 -scale_font_size 14 -manual_spacing -spacing 0.2
    set_axis_prop -plot $PLOTNAME -axis y -title log(Id(A)) -title_font_family "Arial" -title_font_size 16 -scale_font_size 14 -range {1e-12 _maxCurrent_ }

    create_curve -name ld_target_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent target}"
    set_curve_prop ld_target_st$st -label ld_target_st$st -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -hide_line -function abs

    create_curve -name ld_fit_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent fitted}"
    set_curve_prop ld_fit_st$st -label ld_fit_st$st -color $c -line_style dash -line_width 3 -hide_legend -function abs -show_line

    create_curve -name hd_target_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent target}"
    set_curve_prop hd_target_st$st -label hd_target_st$st -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -hide_line -function abs

    create_curve -name hd_fit_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent fitted}"
    set_curve_prop hd_fit_st$st -label hd_fit_st$st -color $c -line_style dash -line_width 3 -hide_legend -function abs -show_line
  }

  set_axis_prop -plot $PLOTNAME -axis y2 -title Id(A) -title_font_family "Arial" -title_font_size 16 -scale_font_size 16 -range {0.0 _maxCurrent_ }
  export_view n@node@_Mystic_IdVg_stress.png -plots $PLOTNAME -format png -overwrite
}

#windows_style -style max
#endif
