#setdep @node|ExtractCorners@ 

## no need to plot process corners if LV is on
#if "@lv@" == "True"
#noexec
#endif

set fomlist   [list "Ioff_lin" "Ioff_sat" "Ion_lin"  "Ion_sat"  "VT_lin" "VT_sat" ]
set fomlabel  [list "log10(A)" "log10(A)" "log10(A)" "log10(A)" "V"      "V"      ]
set axisnames [list "Ioff_lin" "Ioff_sat" "Ion_lin"  "Ion_sat" "VT_lin" "VT_sat"  ]

set title_size 10
set axis_size 8
set axis_marker_size 6

foreach fom $fomlist label $fomlabel axisname $axisnames {

  puts "$fom $label"
  load_file @pwd@/@nodedir|ExtractCorners@/n@node|ExtractCorners@_${fom}_fit-0.csv -name $fom-mcdata
  load_file @pwd@/@nodedir|ExtractCorners@/n@node|ExtractCorners@_${fom}_fit-1.csv -name $fom-PCAdata
  load_file @pwd@/@nodedir|ExtractCorners@/n@node|ExtractCorners@_${fom}_fit-2.csv -name $fom-CornerFitdata

  create_plot -1d -name $fom
  select_plots $fom

  create_curve -plot $fom -dataset $fom-mcdata         -axisX $axisname-n -axisY $axisname-p  -name $fom-mcdata-curve
  create_curve -plot $fom -dataset $fom-PCAdata        -axisX $axisname-n -axisY $axisname-p  -name $fom-PCAdata-curve
  create_curve -plot $fom -dataset $fom-CornerFitdata  -axisX $axisname-n -axisY $axisname-p  -name $fom-CornerFitdata-curve

  set_curve_prop -plot $fom $fom-mcdata-curve        -hide_line -line_width 1  -label MC-Points -color #000000
  set_curve_prop -plot $fom $fom-PCAdata-curve       -hide_line -line_width 10 -label PCA-Points
  set_curve_prop -plot $fom $fom-CornerFitdata-curve -hide_line -line_width 10 -label CornerFit-Points

  set_axis_prop -plot $fom -axis y -title "p-$fom $label" -title_font_family "Arial" -title_font_size 14 -scale_font_size 12
  set_axis_prop -plot $fom -axis x -title "n-$fom $label" -title_font_family "Arial" -title_font_size 14 -scale_font_size 12 
  set_legend_prop -plot $fom -font_size 6 -color_fg white
  set_plot_prop -plot $fom -title_font_family arial -title_font_size 12 
}


