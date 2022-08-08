#-----------------------------------------------------------------------------------------
# This template generates inversion density profiles and integrated inversion density
# from previous sband simulation.
# The inversion density curves are along horizontal and verical cutlines through
# the channel, with the cuts taken through the point of maximum density. 
# The profiles are written to .csv files for Garand density-gradient model calibration.
# This is tested using svisual version R-2020.09.
#-----------------------------------------------------------------------------------------

#setdep @node|xNinvVg@


set TDRdir   "@nodedirpath|xNinvVg@/"

#set peak_posX          x
#set peak_posY          x
#set TargetPoints       x

#set Parent_Path        x
#set rect_mesh_node     x
#set DG_target_node     x


set Type @Type@
set N    @node@

if {$Type == "nMOS"} {set dens eDensity} 
if {$Type == "pMOS"} {set dens hDensity}

# Set list of Vg used for SBand simulation
set Vgs   [list ]
for {set absVg 0.0} {$absVg<[expr @<abs(VDD)>@+0.01]} {set absVg [expr $absVg + @<abs(deltaVGATE)>@]} {
 # Set Vg
  if { [string compare @Type@ nMOS]==0 } {
    set Vg [format %.2f $absVg]
  } else {
    set Vg [format %.2f [expr -$absVg]]
  }
  lappend Vgs $Vg
}

set_window_full -on
windows_style -style max

# Region defining the channel
set chan_region "Channel"

# Integration window definition
set x0 @<-0.5e-3*H>@
set x1 @< 0.5e-3*H>@
set y0 @<-0.5e-3*W>@ 
set y1 @< 0.5e-3*W>@ 
set winList [list $x0 $y0 $x1 $y1]

# List of integrated inversion density (Vg)
set Ninv [list]

puts "====================================================================="
puts "Sweeping over gate biases:"
puts "Vgs: \[$Vgs\]"

# Loop over simulated gate biases and extract inversion density profiles
foreach Vg $Vgs {
  set tid  "Vg=${Vg}V"
  set pid0 "Plot_${tid}"
  load_file ${TDRdir}n@node|xNinvVg@_Vg=${Vg}V_sband.tdr -name $tid
  create_plot -dataset $tid -name $pid0
  select_plots $pid0

   # Integrate charge density over plane for Ninv and append to list
  set int [integrate_field -plot $pid0 -field $dens -geom $tid -regions $chan_region -window $winList]
  lappend Ninv [format %.4e $int]

  # find the position where the density has the maximum value
  set peakinfo [calculate_field_value -plot $pid0 -field $dens -max -regions $chan_region]
  set cdMax [lindex $peakinfo 0]
  set xpos  [lindex [lindex $peakinfo 1] 0]
  set ypos  [lindex [lindex $peakinfo 1] 1]

  # Cutline X/Y (along the FinFET height/width directions)
  foreach xy {X Y} {
    set did "cut${xy}_${tid}"
    set pid "Plot_${did}"
    set cid "C_${did}"

    if { $xy == "X" } {
      set x0n [expr $x0-0.001]
      set x1n [expr $x1+0.001]
      set Cut_Point "${x0n} ${ypos} ${x1n} ${ypos}"
      create_cutline -plot $pid0 -type free -points $Cut_Point -name $did
    } else {
      create_cutline -plot $pid0 -type x -at $xpos -name $did
    }

    create_plot -1d -name $pid -dataset $did
    select_plots $pid

    if { "@Channel_UCS@" == "x" && $xy == "X" } {
     set did1 ${did}_1
     create_variable -dataset $did1 -function "<$xy:$did>*-1" -name $xy
     create_variable -dataset $did1 -function "<$dens:$did>"  -name $dens
     export_variables "${xy} ${dens}" -dataset $did1 -filename "n${N}_${dens}_${cid}.csv" -overwrite
    } else {
     export_variables "${xy} ${dens}" -dataset $did -filename "n${N}_${dens}_${cid}.csv" -overwrite
    }
    create_curve -name $cid -plot $pid -dataset $did -axisX $xy -axisY $dens

  }
}

# Export Ninv vs Vg
set did "d_NinvVg"
set pid "Plot_${did}"
create_variable -name Vg -dataset $did -values $Vgs
create_variable -name ${dens}_int -dataset $did -values $Ninv
create_plot -1d -name $pid
create_curve -plot $pid -dataset $did -axisX Vg -axisY ${dens}_int
export_variables "Vg ${dens}_int" -dataset $did -filename "n${N}_${dens}_int.csv" -overwrite

#if @<W <= H>@
set xy Y
set xPeak $ypos
#else
if { "@Channel_UCS@" == "x" } {
  set xy mX
} else {
  set xy X
}
set xPeak $xpos
#endif
set Vg [lindex $Vgs end]
set tid  "Vg=${Vg}V"
set did "cut${xy}_${tid}"

set XYs [get_variable_data "${xy}"     -dataset $did]
set CDs [get_variable_data "${dens}"   -dataset $did]
set cd0 [expr 0.2*$cdMax]
ext::ExtractValue  -out x0  -name "noprint" -x $CDs -y $XYs -xo $cd0 -f %.6e
puts "$x0 $cd0"

set pointList [list 0.0]
if { [expr abs($xPeak)] > 0.5e-4 } {
 ##lappend pointList $xPeak [expr -1.0*$xPeak]
 lappend pointList [expr abs($xPeak)]
}
if { [expr abs($x0)] > 0.5e-4 } {
 ##lappend pointList $x0 [expr -1.0*$x0]
 lappend pointList [expr abs($x0)]
}
set sortedPointList [lsort -real $pointList]
puts $sortedPointList


## Export the positions to the SWB variable
if { "@Channel_UCS@" == "x" } {
  set xpos [expr -1*$xpos]
}
puts "DOE: peak_posX $xpos"
puts "DOE: peak_posY $ypos"
puts "DOE: TargetPoints $sortedPointList"

## For the optimization
puts "DOE: Parent_Path @pwd@"
##puts "DOE: Sprocess_node @node|sprocess@"
puts "DOE: rect_mesh_node @node|rect_mesh@"
##puts "DOE: xslice_node @node|xslice@"
puts "DOE: DG_target_node @node@"




