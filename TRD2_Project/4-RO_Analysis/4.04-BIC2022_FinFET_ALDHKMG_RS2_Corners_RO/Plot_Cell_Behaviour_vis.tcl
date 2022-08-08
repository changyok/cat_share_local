#setdep @node|GetCircuitSimData@

set cell @logic@X@strength@@height@

create_plot -1d
select_plots {Plot_1}

#if "@Corners_TX@" == "True"
foreach corner {ff tt ss} {
#else
foreach corner {tt} {
#endif
   load_file @pwd@/@nodedir|GetCircuitSimData@/n@node|GetCircuitSimData@_${corner}_${cell}.csv -name ${corner}_${cell}
   create_curve -plot Plot_1 -dataset ${corner}_${cell} -axisX stage_delay -axisY stage_energy -name $corner
   set_curve_prop -plot Plot_1 $corner -show_markers -markers_size 9

}

set_axis_prop -plot Plot_1 -axis x -type log -title "Stage Delay (s)" -title_font_family arial -title_font_size 16 -title_font_color #000000 -title_font_att normal
set_axis_prop -plot Plot_1 -axis x -scale_font_family arial -scale_font_size 16 -scale_font_color #000000 -scale_font_att normal
set_axis_prop -plot Plot_1 -axis y -title "Stage energy (J)" -title_font_family arial -title_font_size 16 -title_font_color #000000 -title_font_att normal
set_axis_prop -plot Plot_1 -axis y -scale_font_family arial -scale_font_size 16 -scale_font_color #000000 -scale_font_att normal
set_plot_prop -plot {Plot_1} -show_grid
#if "@vt_mode@" == "svt"
set_plot_prop -plot {Plot_1} -title "${cell} at @sim_temp@, @vt_mode@, Vdd=0.8V - 0.5V" -title_font_family arial -title_font_size 16 -title_font_color #000000 -title_font_att normal
#elif "@vt_mode@" == "lvt"
set_plot_prop -plot {Plot_1} -title "${cell} at @sim_temp@, @vt_mode@, Vdd=0.7V - 0.4V" -title_font_family arial -title_font_size 16 -title_font_color #000000 -title_font_att normal
#elif "@vt_mode@" == "ulvt"
set_plot_prop -plot {Plot_1} -title "${cell} at @sim_temp@, @vt_mode@, Vdd=0.65V - 0.35V" -title_font_family arial -title_font_size 16 -title_font_color #000000 -title_font_att normal
#endif 


