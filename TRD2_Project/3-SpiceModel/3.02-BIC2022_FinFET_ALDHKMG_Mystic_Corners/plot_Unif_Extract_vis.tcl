#setdep @node|Mystic_Uniform_Enigma@

#if "@Type@" == "tbc" || "@midpoint@" != "True"
#noexec
#endif

# Mystic plot node labels
set gate_label [string tolower @gate_con@]
set drain_label [string tolower @drain_con@]
set source_label [string tolower @drain_con@]
set cap_gate_label [string tolower v(@acgate_con@)]
set cap_label [string tolower c(@acgate_con@,@acgate_con@)]

set DEVNAME n@node|Mystic_Uniform_Enigma@

### load garand target
#if "@Type@" == "nMOS"
set vdlin @Vdd_lin@
set vdd @Vdd_nom@
set bodylist {0.0}
set zero 0.0
set idvds {@Vdd_nom@}
#else
set vdlin @Vdd_lin@
set vdd @Vdd_nom@
set zero 0.0
set bodylist {0.0}
set idvds {@Vdd_nom@}
#endif
set templist {@tnom@ @lowT@ @highT@}
set tempcolor {black blue red}

#################### IdVg plot ###################
set PLOTNAME IdVg
create_plot -1d -name $PLOTNAME
set_plot_prop -plot $PLOTNAME -hide_title

foreach vb $bodylist {
    set idvgld idvg-hd-@drain_con@$vdlin\_@source_con@$zero\_@bulk_con@$vb
    set idvghd idvg-hd-@drain_con@$vdd\_@source_con@$zero\_@bulk_con@$vb

    load_file @pwd@/@nodedir|Mystic_Uniform_Enigma@/$DEVNAME-$idvgld.plt
    load_file @pwd@/@nodedir|Mystic_Uniform_Enigma@/$DEVNAME-$idvghd.plt

##    create_curve -name ld_target_log_vb -plot $PLOTNAME -dataset ld -axisX "{vgate OuterVoltage}" -axisY "{idrain TotalCurrent}"
##    set_curve_prop ld_target_log_vb -label ld_target_log_vb -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line

    create_curve -name ld_target_log_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent target}"
    set_curve_prop ld_target_log_vb$vb -label ld_target_log_vb$vb -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line -function abs

    create_curve -name hd_target_log_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent target}"
    set_curve_prop hd_target_log_vb$vb -label hd_target_log_vb$vb -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line -function abs

    create_curve -name ld_fit_log_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent fitted}"
    set_curve_prop ld_fit_log_vb$vb -label ld_fit_log_vb$vb -color red -line_style dash -line_width 3 -function abs -show_line

    create_curve -name hd_fit_log_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent fitted}"
    set_curve_prop hd_fit_log_vb$vb -label hd_fit_log_vb$vb -color red -line_style dash -line_width 3 -function abs -show_line


    set_axis_prop -plot $PLOTNAME -axis y -type log 
    set_axis_prop -plot $PLOTNAME -axis x -title Vg -title_font_family "Arial" -title_font_size 16 -scale_font_size 14 -manual_spacing -spacing 0.1
    set_axis_prop -plot $PLOTNAME -axis y -title log(Id(A)) -title_font_family "Arial" -title_font_size 16 -scale_font_size 14

    create_curve -name ld_target_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent target}"
    set_curve_prop ld_target_vb$vb -label ld_target_vb$vb -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -hide_line -function abs

    create_curve -name hd_target_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent target}"
    set_curve_prop hd_target_vb$vb -label hd_target_vb$vb -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -hide_line -function abs

    create_curve -name ld_fit_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent fitted}"
    set_curve_prop ld_fit_vb$vb -label ld_fit_vb$vb -color red -line_style dash -line_width 3 -hide_legend -function abs -show_line

    create_curve -name hd_fit_vb$vb -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent fitted}"
    set_curve_prop hd_fit_vb$vb -label hd_fit_vb$vb -color red -line_style dash -line_width 3 -hide_legend -function abs -show_line
}

set_axis_prop -plot $PLOTNAME -axis y2 -title Id(A) -title_font_family "Arial" -title_font_size 16 -scale_font_size 16
export_view n@node@_Mystic_Unif_IdVg.png -plots $PLOTNAME -format png -overwrite

#################### IdVd plot ###################
set col_list {black red green blue purple}
set PLOTNAME IdVd

create_plot -1d -name $PLOTNAME
set_plot_prop -plot $PLOTNAME -hide_title
foreach vg $idvds {
    set idvd idvd-hd-@gate_con@$vg\_@source_con@$zero\_@bulk_con@$zero

    load_file @pwd@/@nodedir|Mystic_Uniform_Enigma@/$DEVNAME-$idvd.plt

    create_curve -name vg_target_$vg -plot $PLOTNAME -dataset $DEVNAME-$idvd -axisX "{$drain_label OuterVoltage}" -axisY "{$drain_label TotalCurrent target}"
    set_curve_prop vg_target_$vg -label vg_target_$vg -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line -function abs
    create_curve -name vg_fit_$vg -plot $PLOTNAME -dataset $DEVNAME-$idvd -axisX "{$drain_label OuterVoltage}" -axisY "{$drain_label TotalCurrent fitted}"
    set_curve_prop vg_fit_$vg -label vg_fit_$vg -color red -line_style dash -line_width 3 -function abs -show_line

    incr i
      
  }

set_axis_prop -plot $PLOTNAME -axis x -title Vd -title_font_family "Arial" -title_font_size 16 -scale_font_size 14 -manual_spacing -spacing 0.1
set_axis_prop -plot $PLOTNAME -axis y -title Id -title_font_family "Arial" -title_font_size 16 -scale_font_size 14
set_legend_prop -plot $PLOTNAME -font_size 14 -color_fg white
export_view n@node@_Mystic_Unif_IdVd.png -plots $PLOTNAME -format png -overwrite

#################### CggVg plot ###################
set cvld cv-d$zero\_s$zero\_b$zero
load_file @pwd@/@nodedir|Mystic_Uniform_Enigma@/$DEVNAME-$cvld.plt
set PLOTNAME CggVg

create_plot -1d -name $PLOTNAME
set_plot_prop -plot $PLOTNAME -hide_title
create_curve -name CggVg_target -plot $PLOTNAME -dataset $DEVNAME-$cvld -axisX "{$cap_gate_label}" -axisY "{$cap_label target}"
set_curve_prop  CggVg_target -label  CggVg_target_vd0 -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line

create_curve -name CggVg_fit -plot $PLOTNAME -dataset $DEVNAME-$cvld -axisX "{$cap_gate_label}" -axisY "{$cap_label fitted}"
set_curve_prop CggVg_fit -label CggVg_fit -color red -line_style dash -line_width 3 -show_line


set_axis_prop -plot $PLOTNAME -axis x -title Vg -title_font_family "Arial" -title_font_size 16 -scale_font_size 14 -manual_spacing -spacing 0.1
set_axis_prop -plot $PLOTNAME -axis y -title Cgg -min 0 -min_fixed -title_font_family "Arial" -title_font_size 16 -scale_font_size 14
set_legend_prop -plot $PLOTNAME -font_size 14 -color_fg white
export_view n@node@_Mystic_Unif_CV.png -plots $PLOTNAME -format png -overwrite

#################### IdVg plot (temperature dependence) ###################

if {(@tnom@ != @highT@) && (@tnom@ != @lowT@)} {
    set PLOTNAME IdVg_temp
    create_plot -1d -name $PLOTNAME
    set_plot_prop -plot $PLOTNAME -hide_title
    
    foreach vb $bodylist {
      foreach temp $templist color $tempcolor {
        set idvgld idvg_temp$temp-@drain_con@$vdlin\_@source_con@$zero\_@bulk_con@$vb
        set idvghd idvg_temp$temp-@drain_con@$vdd\_@source_con@$zero\_@bulk_con@$vb
    
        load_file @pwd@/@nodedir|Mystic_Uniform_Enigma@/$DEVNAME-$idvgld.plt
        load_file @pwd@/@nodedir|Mystic_Uniform_Enigma@/$DEVNAME-$idvghd.plt
    
    ##    create_curve -name ld_target_log_vb -plot $PLOTNAME -dataset ld -axisX "{vgate OuterVoltage}" -axisY "{idrain TotalCurrent}"
    ##    set_curve_prop ld_target_log_vb -label ld_target_log_vb -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line
    
        create_curve -name ld_target_log_vb$vb$temp -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent target}"
        set_curve_prop ld_target_log_vb$vb$temp -label ld_target_log_vb$vb\_$temp -color $color -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line -function abs
    
        create_curve -name hd_target_log_vb$vb$temp -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent target}"
        set_curve_prop hd_target_log_vb$vb$temp -label hd_target_log_vb$vb\_$temp -color $color -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line -function abs
    
        create_curve -name ld_fit_log_vb$vb$temp -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent fitted}"
        set_curve_prop ld_fit_log_vb$vb$temp -label ld_fit_log_vb$vb\_$temp -color $color -line_style dash -line_width 3 -function abs -show_line
    
        create_curve -name hd_fit_log_vb$vb$temp -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent fitted}"
        set_curve_prop hd_fit_log_vb$vb$temp -label hd_fit_log_vb$vb\_$temp -color $color -line_style dash -line_width 3 -function abs -show_line
    
    
        set_axis_prop -plot $PLOTNAME -axis y -type log 
        set_axis_prop -plot $PLOTNAME -axis x -title Vg -title_font_family "Arial" -title_font_size 16 -scale_font_size 14 -manual_spacing -spacing 0.1
        set_axis_prop -plot $PLOTNAME -axis y -title log(Id(A)) -title_font_family "Arial" -title_font_size 16 -scale_font_size 16 
    
        create_curve -name ld_target_vb$vb$temp -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent target}"
        set_curve_prop ld_target_vb$vb$temp -label ld_target_vb$vb\_$temp -color $color -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -hide_line -function abs
    
        create_curve -name hd_target_vb$vb$temp -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent target}"
        set_curve_prop hd_target_vb$vb$temp -label hd_target_vb$vb\_$temp -color $color -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -hide_line -function abs
    
        create_curve -name ld_fit_vb$vb$temp -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent fitted}"
        set_curve_prop ld_fit_vb$vb$temp -label ld_fit_vb$vb\_$temp -color $color -line_style dash -line_width 3 -hide_legend -function abs -show_line
    
        create_curve -name hd_fit_vb$vb$temp -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent fitted}"
        set_curve_prop hd_fit_vb$vb$temp -label hd_fit_vb$vb\_$temp -color $color -line_style dash -line_width 3 -hide_legend -function abs -show_line
      }
    }
    
    set_axis_prop -plot $PLOTNAME -axis y2 -title Id(A) -title_font_family "Arial" -title_font_size 16 -scale_font_size 14
    export_view n@node@_Mystic_Unif_IdVg_temp.png -plots $PLOTNAME -format png -overwrite
}

#################### IdVg plot (Stress dependence) ###################
set PLOTNAME IdVg_stress
create_plot -1d -name $PLOTNAME
set_plot_prop -plot $PLOTNAME -hide_title

set avgStrains {@avgStrains@}

foreach st $avgStrains {
    if { $st == 0 } {
              set idvghd idvg_stress_${zero}-@drain_con@$vdd\_@source_con@$zero\_@bulk_con@$vb
              set idvgld idvg_stress_${zero}-@drain_con@$vdlin\_@source_con@$zero\_@bulk_con@$vb
    } else {
       set idvghd idvg_stress_${st}-@drain_con@$vdd\_@source_con@$zero\_@bulk_con@$vb
       set idvgld idvg_stress_${st}-@drain_con@$vdlin\_@source_con@$zero\_@bulk_con@$vb
    }
    load_file @pwd@/@nodedir|Mystic_Uniform_Enigma@/$DEVNAME-$idvgld.plt
    load_file @pwd@/@nodedir|Mystic_Uniform_Enigma@/$DEVNAME-$idvghd.plt

    create_curve -name ld_target_log_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent target}"
    set_curve_prop ld_target_log_st$st -label ld_target_log_st$st -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line -function abs

    create_curve -name ld_fit_log_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent fitted}"
    set_curve_prop ld_fit_log_st$st -label ld_fit_log_st$st -color red -line_style dash -line_width 3 -function abs -show_line

    create_curve -name hd_target_log_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent target}"
    set_curve_prop hd_target_log_st$st -label hd_target_log_st$st -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_line -function abs

    create_curve -name hd_fit_log_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY "{$drain_label TotalCurrent fitted}"
    set_curve_prop hd_fit_log_st$st -label hd_fit_log_st$st -color red -line_style dash -line_width 3 -function abs -show_line


    set_axis_prop -plot $PLOTNAME -axis y -type log 
    set_axis_prop -plot $PLOTNAME -axis x -title Vg -title_font_family "Arial" -title_font_size 16 -scale_font_size 14 -manual_spacing -spacing 0.1
    set_axis_prop -plot $PLOTNAME -axis y -title log(Id(A)) -title_font_family "Arial" -title_font_size 16 -scale_font_size 14

    create_curve -name ld_target_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent target}"
    set_curve_prop ld_target_st$st -label ld_target_st$st -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -hide_line -function abs

    create_curve -name ld_fit_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvgld -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent fitted}"
    set_curve_prop ld_fit_st$st -label ld_fit_st$st -color red -line_style dash -line_width 3 -hide_legend -function abs -show_line

    create_curve -name hd_target_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent target}"
    set_curve_prop hd_target_st$st -label hd_target_st$st -color black -show_markers -markers_size 9 -markers_type circle -line_width 3 -hide_legend -hide_line -function abs

    create_curve -name hd_fit_st$st -plot $PLOTNAME -dataset $DEVNAME-$idvghd -axisX "{$gate_label OuterVoltage}" -axisY2 "{$drain_label TotalCurrent fitted}"
    set_curve_prop hd_fit_st$st -label hd_fit_st$st -color red -line_style dash -line_width 3 -hide_legend -function abs -show_line
}

set_axis_prop -plot $PLOTNAME -axis y2 -title Id(A) -title_font_family "Arial" -title_font_size 16 -scale_font_size 16
export_view n@node@_Mystic_Unif_IdVg_stress.png -plots $PLOTNAME -format png -overwrite

#windows_style -style max

######else
######noexec
######endif
