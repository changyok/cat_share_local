#setdep @node|icrit_sim@

set corner_list   [list "tt" "ss" "ff" "sf" "fs"]
set color_list    [list "black" "red" "blue" "magenta" "cyan"]
create_plot -1d -name SNM
select_plots SNM
foreach corner $corner_list color $color_list {
  load_file @pwd@/@nodedir|icrit_sim@/n@node|icrit_sim@_vv0_data_${corner}.csv -name ${corner}_data0
  load_file @pwd@/@nodedir|icrit_sim@/n@node|icrit_sim@_vv1_data_${corner}.csv -name ${corner}_data1
  create_curve -plot SNM -dataset ${corner}_data0   -axisX vcored -axisY vncored  -name ${corner}-curve1
  create_curve -plot SNM -dataset ${corner}_data1   -axisX vcored -axisY vncored  -name ${corner}-curve2

  set_curve_prop -plot SNM ${corner}-curve1  -line_width 3  -label ${corner} -color ${color}
  set_curve_prop -plot SNM ${corner}-curve2  -line_width 3  -color ${color} -hide_legend
}

set_axis_prop -axis y1 -title "V(ncored)" -title_font_att bold -title_font_size 20 -scale_font_size 20
set_axis_prop -axis x -title "V(cored)" -title_font_att bold -title_font_size 20 -scale_font_size 20
set_legend_prop -label_font_size 16  -location top_right
