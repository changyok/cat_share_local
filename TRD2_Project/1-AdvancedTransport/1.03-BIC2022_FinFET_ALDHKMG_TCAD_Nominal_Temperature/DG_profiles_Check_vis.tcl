#-----------------------------------------------------------------------------------------
# This template generates inversion density profiles and integrated inversion density
# from calibrated Garand simulation.
# The inversion density curves are along horizontal and verical cutlines through
# the channel, with the cuts taken through the point of maximum density. 
# The profiles are written to .csv files for the density-gradient model calibration.
# 'DG_error' and 'Ninv_error' are calculated against the target data 
# from previous sband simulation. 
# Plot the carrier profiles and Ninv-Vg curve.
# This is tested using svisual version R-2020.09.
#-----------------------------------------------------------------------------------------

#setdep @node|Garand_xNinvVg_Check@

# Integration window definition
set x0 @<-0.5e-3*H>@
set x1 @< 0.5e-3*H>@
set y0 @<-0.5e-3*W>@ 
set y1 @< 0.5e-3*W>@ 
set xp [expr 0.5*($x0+$x1)]

## X or Z
#define _ChanDir_     @Channel_UCS@

#if "_ChanDir_" == "z"
set xycutList   {Y X}
set xyXaxisList {X Y}
set winList [list $x0 $y0 $x1 $y1]
set measurePoint "$xp 0.0"

#elif "_ChanDir_" == "x"
set xycutList   {Y Z}
set xyXaxisList {Z Y}
set winList [list $y0 $x0 $y1 $x1]
set measurePoint "0.0 $xp"

#elif "_ChanDir_" == "y"
set xycutList   {Z X}
set xyXaxisList {X Z}
set winList [list $x0 $y0 $x1 $y1]
set measurePoint "$xp 0.0"

#else
puts "Channel direction should be \"x\" or \"z\" in UCS"
exit
#endif

#define _TechType_  @TechType@
#if "_TechType_" == "CFET"
#define _TechType_  GAA
#elif "_TechType_" == "VFET"
#define _TechType_  FinFET
#elif "_TechType_" == "SRAM"
#define _TechType_  GAA
#endif

##-#set DG_error        x
##-#set Ninv_error      x
#set dosFin          0
#set dosStop         0

#if "@Type@" == "pMOS"
#define _VGATE_          @<(-1*VDD)>@
#define _labelLocation_  top_right
#else
#define _VGATE_          @<( 1*VDD)>@
#define _labelLocation_  top_left
#endif

set TDRdir         "@nodedirpath|Garand_xNinvVg_Check@/results/"
set CSVfitDir      "@nodedirpath@/"
set CSVtargetDir   "@nodedirpath|SB_profiles@/"

#if "@Type@" == "pMOS"
## Y axis attributes in the plot
set YaxisSetList [list {Y linear "-inverted"} {Y2 log "-not_inverted"}]

# hole density profile and DOS
set dens    hDensity
set dosName hEffectiveStateDensity

#else
## Y axis attributes in the plot
set YaxisSetList [list {Y log "-not_inverted"} {Y2 linear "-not_inverted"}]

# electron density profile and DOS
set dens    eDensity
set dosName eEffectiveStateDensity

#endif


## save plot in .png form
#define _PNG_  0
## display the plot
#define _PLOT_ 1


set Type    @Type@
set N       @node@
set xpos    @peak_posX@
set ypos    @peak_posY@
set ptList  [list $ypos $xpos]
set xylabelList {X Y}
set tpList  [list @TargetPoints@]
#if @<W <= H>@
set tpXY    Y
#else
set tpXY    X
#endif

##set_window_full -on
windows_style -style max

# Region defining the channel
set chan_region "Channel"

# List of integrated inversion density (Vg)
set Ninv [list]
set Vgs  [list] 
set Vg   0.0
# Loop over simulated gate biases and extract Ninv
while {[expr abs($Vg)] <= [expr abs(_VGATE_)]} {
  puts "====================================================================="
  set Vgp [format %.2f $Vg]
  puts "Vg: $Vg \[V\]"
  # Load Garand solution tdr and create plot to manipulate
  set tid  "DG_${Vg}"
  set pid0 "Plot_${tid}"
#if "_TechType_" == "BulkFinFET"
  load_file ${TDRdir}Vd0.0_Vg${Vg}_Vsub0.0/viz/n@node|Garand_xNinvVg_Check@-DD-Output_1.tdr -name $tid
#else
  load_file ${TDRdir}Vd0.0_Vg${Vg}/viz/n@node|Garand_xNinvVg_Check@-DD-Output_1.tdr -name $tid
#endif
  create_plot -dataset $tid -name $pid0
  select_plots $pid0

  # Create a 2D cutplane perpendicular to the channel direction
  set did2 "Vg=${Vgp}V"
  set pid2 "Plot_${did2}"
  create_cutplane -plot $pid0 -type _ChanDir_ -at 0.0 -name $did2
  create_plot -dataset $did2 -ref_plot $pid0                                  


  # Integrated charge density over plane and append to list
  set int [integrate_field -plot $pid2 -field $dens -geom $did2 -regions $chan_region -window $winList]
  lappend Ninv [format %.4e $int] 
  lappend Vgs $Vg

  # Cutline X/Y (along the FinFET height/width directions)
  foreach xy $xylabelList xyXaxis $xyXaxisList xycut $xycutList pt $ptList {
    ##set did "d_GARAND_C_cut${xy}_${did2}"
    set did "cut${xy}_${did2}"
    set pid "Plot_${did}"
    set cid "C_${did}"

    create_cutline -plot $pid2 -type $xycut -at $pt -name $did

    create_plot -1d -name $pid -dataset $did
    select_plots $pid
    create_curve -name $cid -plot $pid -dataset $did -axisX $xyXaxis -axisY $dens
    export_variables "${xyXaxis} ${dens}" -dataset $did -filename "n${N}_${dens}_${cid}.csv" -overwrite
  }
  ##remove_plots [list $pid $pid2 $pidX $pidY]
  set Vg [format %g [expr ($Vg+@deltaVGATE@)]]
}

# Export Ninv vs Vg
set did "d_NinvVg"
set pid "Plot_${did}"
create_variable -name Vg -dataset $did -values $Vgs
create_variable -name ${dens}_int -dataset $did -values $Ninv
create_plot -1d -name $pid
create_curve -plot $pid -dataset $did -axisX Vg -axisY ${dens}_int
export_variables "Vg ${dens}_int" -dataset $did -filename "n${N}_${dens}_int.csv" -overwrite

# Measure DOS's in 'ChFin' and 'ChStop'.
puts "~~~ $dosName ~~~"
select_plots $pid2
set_field_prop -plot $pid2 -geom $did2 $dosName -show_bands
set dosValue [probe_field -coord $measurePoint -field $dosName -plot $pid2 -region CHannel -geom $did2]
puts "DOE: dosFin [format %.4e $dosValue]"

#if "_TechType_" == "BulkFinFET"

##set Tsti     0.100     ;# STI trench depth
set Tstop     50.0e-3                ;# channel stop/well thickness
set xp [expr ($x1 + 0.5*$Tstop)]
#if "_ChanDir_" == "x"
set measurePoint "0.0 $xp"
#else
set measurePoint "$xp 0.0"
#endif
set dosValue [probe_field -coord $measurePoint -field $dosName -plot $pid2 -region ChannelStop -geom $did2]
puts "DOE: dosStop [format %.4e $dosValue]"
puts "~~~~~~~~~~~~~~~"

#endif

## remove the plots
foreach Vg $Vgs {
  set tid  "DG_${Vg}"
  set pid0 "Plot_${tid}"
  set Vgp [format %.2f $Vg]
  set did2 "Vg=${Vgp}V"
  set pid2 "Plot_${did2}"

  remove_plots "$pid0 $pid2"
}


#===============================================================================
# Error calculation
# DG_error :: Carrier profile 
# Ninv_error :: Inversion carrier density 
#===============================================================================

# VDD bias 
set Vgp [format %.2f _VGATE_]

# Fin width/height
set W         @<W*1e-3>@
set H         @<H*1e-3>@

# X-Y ranges for the error calculation
set minx_cutY [expr -0.5*$W+0e-3]
set maxx_cutY [expr  0.5*$W-0e-3]
set minx_cutX [expr -0.5*$H+0e-3]
set maxx_cutX [expr  0.5*$H-0e-3]

# X-Y ranges for the plot
set minx_cutYp [expr -0.55*$W]
set maxx_cutYp [expr  0.55*$W]
set minx_cutXp [expr -0.55*$H]
set maxx_cutXp [expr  0.55*$H]


# load data
# Garand results (x-cut/y-cut carrier profiles, Ninv-Vg)
# Traget sabnd results (x-cut/y-cut carrier profiles, Ninv-Vg)
set dirList   [list "${CSVfitDir}" "${CSVtargetDir}"]
set toolList  [list "GARAND" "SBAND"]
set nodeList  [list $N @node|SB_profiles@]
set curveList [list "C_cutX_Vg=${Vgp}V" "C_cutY_Vg=${Vgp}V" "int"]
set xyList    [list "X" "Y"]
foreach tdir $dirList tool $toolList nd $nodeList {
  foreach crv $curveList {
    load_file "${tdir}n${nd}_${dens}_${crv}.csv" -name "d_${tool}_${crv}"
  }
}

# obtain the maximum carrier density at each x-,y-cut.
# set half the maximum denisty as the minimum carrier density for the error calculation.
set minDenList  [list]
set toolList  [list "SBAND"]
set curveList [list "C_cutX_Vg=${Vgp}V" "C_cutY_Vg=${Vgp}V"]
foreach tool $toolList {
  foreach crv $curveList xy $xyList {
    set did "d_${tool}_${crv}"
    set xyList   [get_variable_data "$xy"   -dataset $did]
    set densList [get_variable_data "$dens" -dataset $did]
    ext::ExtractExtremum -out maxDen -name "noprint" -x $xyList -y $densList -type "max"
    # Minimum carrier density for the error calculation
    lappend minDenList  [expr @dg_coeff@*$maxDen]
##puts "$xy maximum density= $maxDen"
  }
}
##puts $minDenList
set toolList  [list "GARAND" "SBAND"]
set curveList [list "C_cutX_Vg=${Vgp}V" "C_cutY_Vg=${Vgp}V" "int"]


###================================================
### DG_error calculation
### Carrier profile error (x-cut/y-cut)
###================================================
set errorXY2 0.0
foreach xy $xylabelList xyXaxis $xyXaxisList minx [list $minx_cutX $minx_cutY] maxx [list $maxx_cutX $maxx_cutY] minDen $minDenList {
  set didFit       "d_GARAND_C_cut${xy}_Vg=${Vgp}V"
  set didTarget    "d_SBAND_C_cut${xy}_Vg=${Vgp}V"
  ## Garand data
  # x or y coordinate
  set xFitList0    [get_variable_data $xyXaxis -dataset $didFit]
  # carrier density
  set yFitList0    [get_variable_data ${dens} -dataset $didFit]
  ext::RemoveDuplicates -out XY -x $xFitList0 -y $yFitList0
  set xFitList $XY(X)
  set yFitList $XY(Y)

  ## Target sband data
  # x or y coordinate
  set xTargetList0 [get_variable_data $xy -dataset $didTarget]
  # carrier density
  set yTaregtList0 [get_variable_data ${dens} -dataset $didTarget]
  ext::RemoveDuplicates -out XY -x $xTargetList0 -y $yTaregtList0
  set xTargetList $XY(X)
  set yTaregtList $XY(Y)

  ## error calculation
  set error2 0.0
  set np 0

  ## calculate RMS along the cut line
  foreach xT $xTargetList yT $yTaregtList {
    if { $minx < $xT && $xT < $maxx } {
      if { $minDen < $yT } {
        ext::ExtractValue -out yF -name "noprint" -x $xFitList -y $yFitList -xo $xT -f %.18e
        if { $yF == "x" } {
          set p_err 1.00
        } else {
          set p_err  [expr (($yF-$yT)/$yT)]
        }
        set error2 [expr ($error2 + ($p_err)**2)]
        set np      [expr (1+$np)]
      }
    }
  }
  if { $error2 < 0.0 || $np==0 } {
    puts "$xy :: error2= $error2 , np = $np"
  } else {
    set error [expr sqrt($error2/$np)]
  }

  if { $xy == $tpXY } {
    set error2 0.0
    set np 0
    ## calculate RMS for critical points
    foreach xT $tpList {
      ext::ExtractValue -out yT -name "noprint" -x $xTargetList -y $yTaregtList -xo $xT -f %.18e
      ext::ExtractValue -out yF -name "noprint" -x $xFitList -y $yFitList -xo $xT -f %.18e
      if { $yT != "x" } {
        if { $yF == "x" } {
          set p_err 1.00
        } else {
          set p_err  [expr (($yF-$yT)/$yT)]
        }
        set error2 [expr ($error2 + ($p_err)**2)]
        set np      [expr (1+$np)]
      }
    }
    if { $error2 < 0.0 || $np==0 } {
      puts "$xy :: error2= $error2 , np = $np"
    } else {
      set error [expr sqrt(($error**2+($error2/$np))/2.0)]
    }
  } 

  set errorXY2 [expr ($errorXY2 + $error**2)]

}
## Average error over x-cut and y-cut.
set DG_error [expr sqrt($errorXY2/2.0)]

puts "DOE:DG_error [format %.1f [expr 100.0*$DG_error]]"


## Plot x-cut and y-cut profiles of Garand and sband results
#if _PLOT_

set_window_full -on
windows_style -style max

foreach xy $xylabelList xyXaxis $xyXaxisList minx [list $minx_cutXp $minx_cutYp] maxx [list $maxx_cutXp $maxx_cutYp] {
  set pid "Plot_cut${xy}"
  create_plot -1d -name $pid
  select_plots $pid

  foreach tool $toolList c {blue black} lw {5 2} ls {solid dash} mk {hide show} { 
   set did    "d_${tool}_C_cut${xy}_Vg=${Vgp}V"
   set cid    "C_$did"

   if { $tool == "GARAND" } {
     create_curve -plot $pid -dataset $did -axisX $xyXaxis -axisY $dens -name $cid
   } else {
     create_curve -plot $pid -dataset $did -axisX $xy -axisY $dens -name $cid
   }
   set_curve_prop $cid -plot $pid -label "${tool}" \
      -color $c -show_line -line_width $lw -line_style $ls \
      -${mk}_markers -markers_type cross  -markers_size 11
  }
  set_axis_prop -plot $pid -axis x -title "$xy \[<greek>m</greek>m\]" \
     -title_font_size 20 -title_font_att bold -scale_font_size 20 \
     -min $minx -min_fixed  -max $maxx -max_fixed
  set_axis_prop -plot $pid -axis y -title "$dens  \[cm<sup>-3</sup>\]" \
     -title_font_size 20 -title_font_att bold -scale_font_size 20

  set_plot_prop -plot $pid -title_font_size 20 -title_font_att bold
  set_legend_prop -plot $pid -label_font_size 14 -label_font_att normal -location _labelLocation_

#if _PNG_
  export_view zFig_n@node@_cut${xy}.png -format png -overwrite
#endif
}

#endif


###=======================================================
### Ninv_error calculation at zero bias point (log scale)
###=======================================================
set didFit    "d_GARAND_int"
set didTarget "d_SBAND_int"
set xvar "Vg"
set yvar "${dens}_int"
## Garand data
# Gate bias
set xFitList0    [get_variable_data $xvar -dataset $didFit]
# Integrated carrier density
set yFitList0    [get_variable_data $yvar -dataset $didFit]
ext::RemoveDuplicates -out XY -x $xFitList0 -y $yFitList0
set xFitList $XY(X)
set yFitList $XY(Y)
## Target sband data
# Gate bias
set xTargetList0 [get_variable_data $xvar -dataset $didTarget]
# Integrated carrier density
set yTaregtList0 [get_variable_data $yvar -dataset $didTarget]
ext::RemoveDuplicates -out XY -x $xTargetList0 -y $yTaregtList0
set xTargetList $XY(X)
set yTaregtList $XY(Y)

## Calculate error
## Target Ninv_int normalized to 1e-2
set ninvPS0 [lindex $yTaregtList 0]
set yF00    [lindex $yFitList 0]
set yT00    [lindex $yTaregtList 0]
set yF0     [expr (1.0e-2*$yF00/$ninvPS0)]
set yT0     [expr (1.0e-2*$yT00/$ninvPS0)]
set logYf0  [expr log(abs($yF0))]
set logYt0  [expr log(abs($yT0))]

set Ninv_error [expr abs(($logYf0-$logYt0)/$logYt0)]

puts "DOE:Ninv_error [format %.1f [expr 100.0*$Ninv_error]]"

set yFon    [lindex $yFitList end]
set yTon    [lindex $yTaregtList end]
puts "##DOE:NinvOn_error [format %.1f [expr 100.0*($yFon-$yTon)/$yTon]]"


## Plot Ninv-Vg of Garand and sband results
#if _PLOT_

set_window_full -on
windows_style -style max

set pid "Plot_Ninv"
create_plot -1d -name $pid
select_plots $pid

foreach tool $toolList c {blue black} lw {5 2} ls {solid dash} mk {hide show} { 
 set did    "d_${tool}_int"
 set cid    "C_$did"

 foreach yList $YaxisSetList {
  set ay [lindex $yList 0]
  set as [lindex $yList 1]
  set cid "C_${did}_${as}"
  create_curve -plot $pid -dataset $did -axisX $xvar -axis${ay} $yvar -name $cid
  set_curve_prop $cid -plot $pid -label "${tool}" \
     -color $c -show_line -line_width $lw -line_style $ls \
     -${mk}_markers -markers_type cross  -markers_size 11

  set_axis_prop -plot $pid -axis [string tolower $ay] -type $as \
          -title "Ninv integration \[cm<sup>-1</sup>\]" \
          -title_font_size 20 -title_font_att bold -scale_font_size 20
 }
}
set_axis_prop -plot $pid -axis x -title "V(gate) \[V\]" \
        -title_font_size 20 -title_font_att bold -scale_font_size 20
set_plot_prop -plot $pid -title "Ninv-Vg Comparison" \
        -title_font_size 20 -title_font_att bold
set_legend_prop -plot $pid -label_font_size 14 -label_font_att normal -location _labelLocation_

#if _PNG_
export_view zFig_n@node@_NinvVg.png -format png -overwrite
#endif

#endif

#===============================================================================
# Error calculation
#===============================================================================




