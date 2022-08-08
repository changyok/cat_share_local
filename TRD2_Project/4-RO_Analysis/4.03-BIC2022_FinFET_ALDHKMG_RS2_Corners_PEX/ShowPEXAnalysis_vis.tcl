#setdep @node|GetCircuitSimData_RSM:all@

#if @node:index@ != 2
#noexec
#endif


load_file @pwd@/@nodedir|GetCircuitSimData_RSM@/n@node|GetCircuitSimData_RSM@_tt_@logic@X@strength@@height@_RSM_MC.csv -name ModelData
load_file @pwd@/@nodedir|GetCircuitSimData_RSM@/n@node|GetCircuitSimData_RSM@_tt_@logic@X@strength@@height@.csv -name SimulationData
load_file @pwd@/@nodedir|GetCircuitSimData_RSM@/PEX_corners.csv -name CornerData

create_plot -1d
select_plots {Plot_1}

create_curve -plot Plot_1 -dataset {ModelData SimulationData CornerData} -axisX stage_delay -axisY stage_energy

set_curve_prop -plot Plot_1 {Curve_1 Curve_2} -xScale 1e+12
set_curve_prop -plot Plot_1 {Curve_1 Curve_2} -yScale 1e+15
set_curve_prop -plot Plot_1 {Curve_1 Curve_2 Curve_3} -hide_line -line_width 2
set_legend_prop -plot Plot_1 -position {0.468023 0.279534}

set_curve_prop -plot Plot_1 {Curve_3} -label "PEX corners" -markers_type cross -markers_size 11 -line_width 3
set_curve_prop -plot Plot_1 {Curve_2} -label "Simulation data" -markers_size 7 -line_width 1 -color #ff0000
set_curve_prop -plot Plot_1 {Curve_1} -label "10,000 Model samples" -color #000000

set_plot_prop -plot {Plot_1} -show_grid

set_axis_prop -plot Plot_1 -axis x -title "Stage delay (ps)"
set_axis_prop -plot Plot_1 -axis x -title_font_family arial -title_font_size 24 -title_font_color #000000 -title_font_att normal
set_axis_prop -plot Plot_1 -axis x -scale_font_family arial -scale_font_size 20 -scale_font_color #000000 -scale_font_att normal
set_axis_prop -plot Plot_1 -axis y -title "Stage energy (fJ)"
set_axis_prop -plot Plot_1 -axis y -title_font_family arial -title_font_size 24 -title_font_color #000000 -title_font_att normal
set_axis_prop -plot Plot_1 -axis y -scale_font_family arial -scale_font_size 20 -scale_font_color #000000 -scale_font_att normal


set_legend_prop -plot Plot_1 -position {0.645349 0.34609}
set_plot_prop -plot {Plot_1} -hide_title


