#-----------------------------------------------------------------------------------------
# This template collects the IdVg and IdVd curves from Garand monte-carlo results,
# writes .plt files, extracts ET data (IDLIN, IDSAT, IOFF,..), and plot the IV curves.
# The linear currents (V(gate)>Vth) are simulated using Garand monte-carlo. 
# The subthreshold currents are estimated from the drift-diffusion results.
# This is tested using svisual version R-2020.09.
#-----------------------------------------------------------------------------------------

#setdep @node|Garand_DD:all@ && @node|Garand_MC:all@


#define _TechType_  @TechType@
#if "_TechType_" == "CFET"
#define _TechType_  GAA
#elif "_TechType_" == "VFET"
#define _TechType_  GAA
#elif "_TechType_" == "SRAM"
#define _TechType_  GAA
#endif


##############################################################################
##### PROCEDURES -BEGIN                                                  #####
##############################################################################

proc writeIVplt { fileName eh tvgList tvdList tidList tisList } {
 set fp [open $fileName w+]
 puts $fp "DF-ISE text"
 puts $fp ""
 puts $fp "Info {"
 puts $fp {  version   = 1.0
  type      = xyplot
  datasets  = [}
 puts -nonewline $fp "    \"${eh}drain OuterVoltage\""
 puts -nonewline $fp " \"${eh}drain TotalCurrent\""
 puts -nonewline $fp " \"${eh}source OuterVoltage\"" 
 puts -nonewline $fp " \"${eh}source TotalCurrent\"" 
 puts -nonewline $fp " \"substrate OuterVoltage\"" 
 puts -nonewline $fp " \"${eh}gate OuterVoltage\""
 puts $fp { ]
  functions  = [
    OuterVoltage TotalCurrent OuterVoltage TotalCurrent OuterVoltage OuterVoltage ]}
 puts $fp "}"
 puts $fp ""
 puts $fp "Data {"
 foreach tvg $tvgList tvd $tvdList tid $tidList tis $tisList {
  puts $fp "$tvd $tid 0.0 $tis 0.0 $tvg"
 }
 puts $fp "}"

}

##############################################################################
##### PROCEDURES -END                                                    #####
##############################################################################


##############################################################################
##### Collect drain current and generate CSV files of IdVg & IdVd curves #####
#####   for drift-diffusion and monte-carlo simulations.                 #####
##### Output monte-carlo IdVg & IdVd simulation total time. (summation)  #####
##############################################################################


#define _DD_    1
#define _MC_    1

#define _withAnalysisExtraction_ 1

#if _DD_
#setdep @node|Garand_DD@
#endif

#if _MC_ 
#setdep @node|Garand_MC@

#set TotalMCsimTime  x

#endif

#define _PNG_ 1

# Percentage error above which MC I-V points will not be plotted. Set to 1e3 to enforce plotting of all points
set plotTol 2e2

#if "@Type@" == "pMOS"
set SIGN         -1.0
set np            "p"
set YaxisSetList   [list {Y linear "-inverted"} {Y2 log "-not_inverted"}]
set Yinverted      "-inverted"
set mcfile       "INTERMITTENT_HOLE_OUTPUT"
#define _CD_     HOLE

set VGATE         @<(-1*VDD)>@

#else
set SIGN          1.0
set np            "n"
set YaxisSetList  [list {Y log "-not_inverted"} {Y2 linear "-not_inverted"}]
set Yinverted      "-not_inverted"
set mcfile        "INTERMITTENT_ELEC_OUTPUT"
#define _CD_      ELECTRON

set VGATE         @<( 1*VDD)>@

#endif

## When |Vd| is 0.05V or VDD, IdVg curve is generated.
## Otherwise, IdVd curve is genrated, when 0.05V < |Vd| < VDD.
#if @<0.05 < abs(Vd)>@ && @<abs(Vd) < abs(VDD)>@ 
#define _isVg_          0
#else
#define _isVg_          1
#endif

#if _isVg_
set strTag "IdVg_Vd=@Vd@V"
#else
set strTag "IdVd_Vg=@Vg@V"
#endif


set_window_full -on
windows_style -style max
 

set NODEdd     [list @node|Garand_DD:all@]
set NODEmc     [list @node|Garand_MC:all@]
set TEC        [list @TechType:all@]
set DEV        [list @Type:all@]
set LENGTH     [list @Lg:all@]
set WIDTH      [list @W:all@]
set TEMP       [list @Temperature:all@]
set VD         [list @Vd:all@]
set VG         [list @Vg:all@]

set ID [list]
foreach t $TEC d $DEV l $LENGTH w $WIDTH temp $TEMP {
 lappend ID "${t}_${d}_Lg${l}nm_Wfin${w}nm_${temp}C"
}

set NodeId   "@TechType@_@Type@_Lg@Lg@nm_Wfin@W@nm_@Temperature@C"
set fixedVD  @Vd@
set fixedVG  @Vg@


#################################################################
##### Drift-diffusion simulation IdVg curve generation ##########
#################################################################
#if _DD_

# collect curve data from individual voltage nodes
 #if _isVg_
set Id  [list]
set Is  [list]
set Vg  [list]
set Vd  [list]
 #else
set Id  [list 0]
set Is  [list 0]
set Vg  [list @Vg@]
set Vd  [list 0.0]
 #endif

## Generate IdVg CSV file of drift-diffusion simulation
foreach n $NODEdd id $ID vd $VD vg $VG {
 if { "$id" == "$NodeId" && (($vd == $fixedVD && _isVg_) || ($vg == $fixedVG && !_isVg_)) } {
#if "_TechType_" == "BulkFinFET"
  set fname "@pwd@/results/nodes/${n}/n${n}_IdVg_Vd${vd}_Vsub0.0_1.plt"
#elif "_TechType_" == "GAA"
  set fname "@pwd@/results/nodes/${n}/n${n}_IdVg_Vd${vd}_1.plt"
#else
  puts "TechType= _TechType_ is beyond support ..."
  exit 
#endif
  if { [file exists $fname] == 1 } {
   set did "dat_$n"
   load_file $fname -name $did
   lappend Vg [lindex [get_variable_data "gate OuterVoltage"   -dataset $did] 0]
   lappend Vd [lindex [get_variable_data "drain OuterVoltage"  -dataset $did] 0]
   lappend Id [lindex [get_variable_data "drain TotalCurrent"  -dataset $did] 0]
   lappend Is [lindex [get_variable_data "source TotalCurrent" -dataset $did] 0]
  }
 }
}

## sort the list by V(gate) or V(drain)
set tsortList0 [list]
foreach id $Id is $Is vg $Vg vd $Vd {
 lappend tsortList0 [list $id $is $vg $vd]
}
puts $tsortList0
  #if _isVg_
set tsortList [lsort -real -index 2 $tsortList0]
  #else
set tsortList [lsort -real -index 3 $tsortList0]
  #endif
puts $tsortList
set Id  [list]
set Is  [list]
set Vg  [list]
set Vd  [list]
foreach tl $tsortList {
 lappend Id  [lindex $tl 0]
 lappend Is  [lindex $tl 1]
 lappend Vg  [lindex $tl 2]
 lappend Vd  [lindex $tl 3]
}

puts "Vg :: $Vg "
puts "Vd :: $Vd "
puts "Id :: $Id "
puts "Is :: $Is "

set pltName "n@node@_GarandDD_${strTag}_${NodeId}"
set dDDiv "dat_DD"

create_variable -name V(gate)   -dataset $dDDiv -values $Vg
create_variable -name V(drain)  -dataset $dDDiv -values $Vd
create_variable -name I(drain)  -dataset $dDDiv -values $Id
create_variable -name I(source) -dataset $dDDiv -values $Is

## generate .csv and .plt files.
export_variables {V(gate) V(drain) I(drain) I(source)} -dataset $dDDiv -filename "${pltName}.csv" -overwrite
writeIVplt "@pwd@/${pltName}.plt" $np $Vg $Vd $Id $Is



## Plot drift-diffusion IV curve
set pid "Plot_DD"
create_plot -1d -name $pid
select_plots $pid

 #if _isVg_
 ## Plot drift-diffusion IdVg curve

# loop over Y axes. Y1/Y2 linear/log or log/linear
foreach YaxisSet $YaxisSetList {

  set Yaxis  [lindex $YaxisSet 0]
  set Yscale [lindex $YaxisSet 1]
  set Yinv   [lindex $YaxisSet 2]

  create_curve -name C_iv_$Yscale -dataset $dDDiv \
               -axisX "V(gate)"  -axis${Yaxis} "I(drain)" 

  set label "GarandDD Vds= $fixedVD \[V\]"
  set_curve_prop C_iv_$Yscale -label $label -color black \
                 -show_markers -markers_type circle -markers_size 7 \
                 -line_width 2 -line_style solid

  # Set y-axis atributes
  set_axis_prop -axis [string tolower $Yaxis] -type $Yscale $Yinv \
          -title {I(drain) [A]} -title_font_size 20 -title_font_att bold \
          -scale_font_size 20  -scale_format scientific -scale_precision 1

};# end loop over linear and log scale

# Set x-axis properties
set_axis_prop -axis x -title {V(gate) [V]} \
              -title_font_size 20 -title_font_att bold -scale_font_size 20  
  
# Set title
set title "GarandDD IdVg"
set_plot_prop -title $title -title_font_size 20 -title_font_att bold

set_legend_prop -label_font_size 12 -label_font_att normal \
                 -position {0.45 0.90}

 #else
 ## Plot drift-diffusion IdVd curve

create_curve -name C_iv -dataset $dDDiv \
               -axisX "V(drain)"  -axisY "I(drain)" 

set label "GarandDD Vgs= $fixedVG \[V\]"
set_curve_prop C_iv -label $label -color black \
                 -show_markers -markers_type circle -markers_size 7 \
                 -line_width 2 -line_style solid

# Set y-axis atributes
set_axis_prop -axis y -type linear $Yinverted \
          -title {I(drain) [A]} -title_font_size 20 -title_font_att bold \
          -scale_font_size 20  -scale_format scientific -scale_precision 1

# Set x-axis properties
set_axis_prop -axis x -title {V(gate) [V]} \
              -title_font_size 20 -title_font_att bold -scale_font_size 20  
  
# Set title
set title "GarandDD IdVd"
set_plot_prop -title $title -title_font_size 20 -title_font_att bold

set_legend_prop -label_font_size 12 -label_font_att normal \
                 -position {0.45 0.90}

 #endif

 #if _PNG_
export_view zFig_${pltName}.png -format png -overwrite
 #endif

#endif


#############################################################
##### Monte-carlo simulation IdVg curve generation ##########
#############################################################
#if _MC_

# collect curve data from individual voltage nodes
set Id		[list]
set Is		[list]
set Vg		[list]
set Vd		[list]

set IdError	[list]
set IdErrTol1	[list]
set IdErrTol5	[list]
set IdErrTol10	[list]
set NumbCarrier	[list]
set SimStep	[list]
set SimTime	[list]

set simTimeMClist   [list]

## Generate IdVg CSV file of monte-carlo simulation
foreach n $NODEmc id $ID vd $VD vg $VG {
 if { "$id" == "$NodeId" && (($vd == $fixedVD && _isVg_) || ($vg == $fixedVG && !_isVg_)) } {
  set writeSimTimeFlag 0

  set fname "@pwd@/results/nodes/${n}/data/${mcfile}"

  if { [file exists $fname] == 1} {
    set f [open $fname]
    set lines [split [read $f] \n]
    close $f

    foreach line $lines {
      if [regexp "CURRENT THROUGH TEST PLANE" $line]==1 {
        puts $line
        set currentline $line
      }
      if [regexp "  NUMB " $line]==1 {
        puts $line
        set currentlineNumb $line
      }
      if [regexp "  SIMULATION STEP " $line]==1 {
        puts $line
        set currentlineSimStep $line
      }
    }
    set strings [split $currentline " "]
    set this_current [lindex $strings [expr [lsearch $strings +/-*] - 1] ]
    set this_error   [string trim [lindex $strings [expr [lsearch $strings %*] - 1] ] "("]

    set strings                  [regexp -all -inline {\S+} $currentlineNumb]
    set this_NumbCarrier0        [lindex $strings [lsearch $strings :*]]
    set length_this_NumbCarrier0 [string length $this_NumbCarrier0]
    if { $length_this_NumbCarrier0 > 1 } {
     set this_NumbCarrier [string trim [llength [lindex $strings [lsearch $strings :*]]] ":"]
    } elseif { $length_this_NumbCarrier0 == 1 } {
     set this_NumbCarrier [lindex $strings [expr [lsearch $strings :*] + 1] ]
    } else {
     puts "Error in obtaining \'NUMB\' ...!!"
     exit
    }

    set strings              [regexp -all -inline {\S+} $currentlineSimStep]
    set this_SimStep0        [lindex $strings [lsearch $strings :*]]
    set length_this_SimStep0 [string length $this_SimStep0]
    if { $length_this_SimStep0 > 1 } {
     set this_SimStep [string trim [llength [lindex $strings [lsearch $strings :*]]] ":"]
    } elseif { $length_this_SimStep0 == 1 } {
     set this_SimStep [lindex $strings [expr [lsearch $strings :*] + 1] ]
    } else {
     puts "Error in obtaining \'SIMULATION STEP\' ...!!"
     exit
    }

    if {[expr abs($this_current)] > 1e-20} {
      if { [string match $this_error "*"] } {
        set this_error  1e3
      }
      if { $this_error <= $plotTol } {
       lappend Id         [expr  2.0*$this_current] 
       lappend Is         [expr -2.0*$this_current] 
       lappend Vg         $vg
       lappend Vd         $vd
       lappend IdError    $this_error 
       lappend IdErrTol1   1.0  
       lappend IdErrTol5   5.0
       lappend IdErrTol10 10.0

       lappend NumbCarrier $this_NumbCarrier
       lappend SimStep     $this_SimStep

       set writeSimTimeFlag 1
      }  
    }
  }

  set fname "@pwd@/results/nodes/${n}/n${n}_gmc.out"

  set currentline ""
  if { [file exists $fname] == 1} {
    set f [open $fname]
    set lines [split [read $f] \n]
    close $f

    foreach line $lines {
      if [regexp "TOTAL SIMULATION TIME" $line]==1 {
        puts $line
        set currentline $line
      }
    }
    # Simulation Time
    if { $currentline != "" } {
      set strings [split $currentline " "]
      set this_hours   [lindex $strings [expr [lsearch $strings "hour*"] - 1] ]
      set this_minutes [lindex $strings [expr [lsearch $strings "minute*"] - 1] ]
      set this_seconds [lindex $strings [expr [lsearch $strings "second*"] - 1] ]
      if { $this_hours == "" } { set this_hours 0 }
      if { $this_minutes == "" } { set this_minutes 0 }
      if { $this_seconds == "" } { set this_seconds 0 } 
      lappend simTimeMClist "${this_hours}h_${this_minutes}m_${this_seconds}s"
     
      if { $writeSimTimeFlag } {
       lappend SimTime [expr (60.0*$this_hours + $this_minutes + $this_seconds/60.0)]
      }
    }
  }


 }
}
 #if !_isVg_
set Id		[linsert $Id 0 0]
set Is		[linsert $Is 0 0]
set Vg		[linsert $Vg 0 @Vg@]
set Vd		[linsert $Vd 0 0.0]

set IdError	[linsert $IdError     0 [lindex $IdError 0]]
set IdErrTol1	[linsert $IdErrTol1   0 [lindex $IdErrTol1 0]]
set IdErrTol5	[linsert $IdErrTol5   0 [lindex $IdErrTol5 0]]
set IdErrTol10	[linsert $IdErrTol10  0 [lindex $IdErrTol10 0]]
set NumbCarrier	[linsert $NumbCarrier 0 [lindex $NumbCarrier 0]]
set SimStep	[linsert $SimStep     0 [lindex $SimStep 0]]
set SimTime	[linsert $SimTime     0 [lindex $SimTime 0]]
 #endif

## sort the list by V(gate) or V(drain)
set tsortList0 [list]
foreach id $Id is $Is vg $Vg vd $Vd ie $IdError iet1 $IdErrTol1 iet5 $IdErrTol5 iet10 $IdErrTol10 nc $NumbCarrier sstep $SimStep stime $SimTime {
 lappend tsortList0 [list $id $is $vg $vd $ie $iet1 $iet5 $iet10 $nc $sstep $stime]
}
puts $tsortList0
  #if _isVg_
set tsortList [lsort -real -index 2 $tsortList0]
  #else
set tsortList [lsort -real -index 3 $tsortList0]
  #endif
puts $tsortList
set Id		[list]
set Is		[list]
set Vg		[list]
set Vd		[list]
set IdError	[list]
set IdErrTol1	[list]
set IdErrTol5	[list]
set IdErrTol10	[list]
set NumbCarrier	[list]
set SimStep	[list]
set SimTime	[list]
foreach tl $tsortList {
 lappend Id		[lindex $tl 0]
 lappend Is		[lindex $tl 1]
 lappend Vg		[lindex $tl 2]
 lappend Vd		[lindex $tl 3]
 lappend IdError	[lindex $tl 4]
 lappend IdErrTol1	[lindex $tl 5]
 lappend IdErrTol5	[lindex $tl 6]
 lappend IdErrTol10	[lindex $tl 7]
 lappend NumbCarrier	[lindex $tl 8]
 lappend SimStep	[lindex $tl 9]
 lappend SimTime	[lindex $tl 10]
}

puts "Vg          :: $Vg "
puts "Vd          :: $Vd "
puts "Id          :: $Id "
puts "Is          :: $Is "
puts "IdError     :: $IdError "
puts "IdErrTol1   :: $IdErrTol1 "
puts "IdErrTol5   :: $IdErrTol5 "
puts "IdErrTol10  :: $IdErrTol10 "
puts "NumbCarrier :: $NumbCarrier "
puts "SimStep     :: $SimStep "
puts "SimTime     :: $SimTime "

set pltName "n@node@_GarandMC_${strTag}_${NodeId}"
set dMCiv "dat_MC"

create_variable -name V(gate)        -dataset $dMCiv -values $Vg
create_variable -name V(drain)       -dataset $dMCiv -values $Vd
create_variable -name I(drain)       -dataset $dMCiv -values $Id
create_variable -name I(source)      -dataset $dMCiv -values $Is
create_variable -name Id_error       -dataset $dMCiv -values $IdError
create_variable -name Id_tolerance1  -dataset $dMCiv -values $IdErrTol1
create_variable -name Id_tolerance5  -dataset $dMCiv -values $IdErrTol5
create_variable -name Id_tolerance10 -dataset $dMCiv -values $IdErrTol10
create_variable -name NumbCarrier    -dataset $dMCiv -values $NumbCarrier
create_variable -name SimStep        -dataset $dMCiv -values $SimStep
create_variable -name SimTime        -dataset $dMCiv -values $SimTime

## generate .csv and .plt files.
export_variables {V(gate) V(drain) I(drain) I(source) Id_error Id_tolerance1 Id_tolerance5 Id_tolerance10 NumbCarrier SimStep SimTime} \
                 -dataset $dMCiv -filename "${pltName}.csv" -overwrite
writeIVplt "@pwd@/${pltName}.plt" $np $Vg $Vd $Id $Is


## Plot monte-carlo IV curve
set pid "Plot_MC"
create_plot -1d -name $pid
select_plots $pid

 #if _isVg_
 ## Plot monte-carlo IdVg curve

# loop over Y axes. Y1/Y2 linear/log or log/linear
foreach YaxisSet $YaxisSetList {

  set Yaxis  [lindex $YaxisSet 0]
  set Yscale [lindex $YaxisSet 1]
  set Yinv   [lindex $YaxisSet 2]

  create_curve -name C_iv_$Yscale -dataset $dMCiv \
               -axisX "V(gate)"  -axis${Yaxis} "I(drain)" 

  set label "GarandDD Vds= $fixedVD \[V\]"
  set_curve_prop C_iv_$Yscale -label $label -color black \
                 -show_markers -markers_type circle -markers_size 7 \
                 -line_width 2 -line_style solid

  # Set y-axis atributes
  set_axis_prop -axis [string tolower $Yaxis] -type $Yscale $Yinv \
          -title {I(drain) [A]} -title_font_size 20 -title_font_att bold \
          -scale_font_size 20  -scale_format scientific -scale_precision 1

};# end loop over linear and log scale

# Set x-axis properties
set_axis_prop -axis x -title {V(gate) [V]} \
              -title_font_size 20 -title_font_att bold -scale_font_size 20  
  
# Set title
set title "GarandMC IdVg"
set_plot_prop -title $title -title_font_size 20 -title_font_att bold

set_legend_prop -label_font_size 12 -label_font_att normal \
                 -position {0.45 0.90}

 #else
 ## Plot monte-carlo IdVd curve

create_curve -name C_iv -dataset $dMCiv \
               -axisX "V(drain)"  -axisY "I(drain)" 

set label "GarandMC Vgs= $fixedVG \[V\]"
set_curve_prop C_iv -label $label -color black \
                 -show_markers -markers_type circle -markers_size 7 \
                 -line_width 2 -line_style solid

# Set y-axis atributes
set_axis_prop -axis y -type linear $Yinverted \
          -title {I(drain) [A]} -title_font_size 20 -title_font_att bold \
          -scale_font_size 20  -scale_format scientific -scale_precision 1

# Set x-axis properties
set_axis_prop -axis x -title {V(gate) [V]} \
              -title_font_size 20 -title_font_att bold -scale_font_size 20  
  
# Set title
set title "GarandMC IdVd"
set_plot_prop -title $title -title_font_size 20 -title_font_att bold

set_legend_prop -label_font_size 12 -label_font_att normal \
                 -position {0.45 0.90}

 #endif

 #if _PNG_
export_view zFig_${pltName}.png -format png -overwrite
 #endif

## Plot MC drain current error

 #if _isVg_
 ## Plot monte-carlo error-Vg curve
set xvar "V(gate)"
set label "GarandMC Vds= $fixedVD \[V\]"
 #else
 ## Plot monte-carlo error-Vd curve
set xvar "V(drain)"
set label "GarandMC Vgs= $fixedVG \[V\]"
 #endif

set pid "Plot_MCerror"
create_plot -1d -name $pid
select_plots $pid

create_curve -name C_ierror      -dataset $dMCiv -axisX $xvar  -axisY "Id_error" 
create_curve -name C_ierTol1     -dataset $dMCiv -axisX $xvar  -axisY "Id_tolerance1" 
create_curve -name C_ierTol5     -dataset $dMCiv -axisX $xvar  -axisY "Id_tolerance5" 
create_curve -name C_ierTol10    -dataset $dMCiv -axisX $xvar  -axisY "Id_tolerance10" 
create_curve -name C_numCarrier  -dataset $dMCiv -axisX $xvar  -axisY2 "NumbCarrier" 

set Vbias [get_variable_data "$xvar" -dataset $dMCiv]
set NC    [get_variable_data "NumbCarrier" -dataset $dMCiv]
ext::ExtractExtremum -out ncMax -name "noprint" -x $Vbias -y $NC -type "max"
ext::ExtractExtremum -out ncMin -name "noprint" -x $Vbias -y $NC -type "min"

set_curve_prop C_ierror -label $label -color black -line_width 2 -line_style solid \
               -show_markers -markers_type circle -markers_size 7 
set label "Tolerance \[1%\]"
set_curve_prop C_ierTol1 -label $label -color blue -line_width 3 -line_style dash \
               -hide_markers -markers_type circle -markers_size 7 
set label "Tolerance \[5%\]"
set_curve_prop C_ierTol5 -label $label -color red -line_width 3 -line_style dash \
               -hide_markers -markers_type circle -markers_size 7 
set label "Tolerance \[10%\]"
set_curve_prop C_ierTol10 -label $label -color cyan -line_width 3 -line_style dash \
               -hide_markers -markers_type circle -markers_size 7                  
set label "Carrier Number"
set_curve_prop C_numCarrier -label $label -color magenta -line_width 2 -line_style solid \
               -show_markers -markers_type cross -markers_size 7    

# Set y-axis atributes
set_axis_prop -axis y -type linear -scale_font_size 20   \
          -title {Id_error [%]} -title_font_size 20 -title_font_att bold \
          -scale_format fixed -manual_precision -scale_precision 1 \
          -min -1 -min_fixed -max 6 -max_fixed

# Set y2-axis atributes
set_axis_prop -axis y2 -type linear -scale_font_size 20   \
          -title {Number of Carrier} -title_font_size 20 -title_font_att bold \
          -scale_format preferred -auto_precision 

# Set x-axis properties
set_axis_prop -axis x -title "$xvar \[V\]" \
              -title_font_size 20 -title_font_att bold -scale_font_size 20  
  
# Set title
set title "GarandMC Id Error"
set_plot_prop -title $title -title_font_size 20 -title_font_att bold

set_legend_prop -label_font_size 14 -label_font_att normal -position {0.45 0.90}

 #if _PNG_
export_view zFig_${pltName}_Error.png -format png -overwrite
 #endif


## Plot MC sim. step & time

 #if _isVg_
 ## Plot monte-carlo error-Vg curve
set xvar "V(gate)"
set title0 "Vds= $fixedVD \[V\]"
 #else
 ## Plot monte-carlo error-Vd curve
set xvar "V(drain)"
set title0 "Vgs= $fixedVG \[V\]"
 #endif

set pid "Plot_MCsimStepTime"
create_plot -1d -name $pid
select_plots $pid

create_curve -name C_simStep      -dataset $dMCiv -axisX $xvar  -axisY "SimStep" 
create_curve -name C_simTime      -dataset $dMCiv -axisX $xvar  -axisY2 "SimTime" 

set label "Sim. Step"
set_curve_prop C_simStep -label $label -color black -line_width 3 -line_style solid \
               -show_markers -markers_type circle -markers_size 7 
set label "Sim. Time \[min.\]"
set_curve_prop C_simTime -label $label -color blue -line_width 3 -line_style dash \
               -show_markers -markers_type cross -markers_size 10 

# Set y-axis atributes
set_axis_prop -axis y -type linear -scale_font_size 20   \
          -title {Sim. Step} -title_font_size 20 -title_font_att bold \
          -scale_format preferred -auto_precision

# Set y2-axis atributes
set_axis_prop -axis y2 -type linear -scale_font_size 20   \
          -title {Sim. Time [min.]} -title_font_size 20 -title_font_att bold \
          -scale_format preferred -auto_precision 

# Set x-axis properties
set_axis_prop -axis x -title "$xvar \[V\]" \
              -title_font_size 20 -title_font_att bold -scale_font_size 20  
  
# Set title
set title "GarandMC Sim. Step & Time $title0"
set_plot_prop -title $title -title_font_size 20 -title_font_att bold

set_legend_prop -label_font_size 14 -label_font_att normal -position {0.45 0.90}

 #if _PNG_
export_view zFig_${pltName}_SimStepTime.png -format png -overwrite
 #endif


#endif


##########################################################################################
### Generate the full IdVg curves with MC (linear region) and DD (subthreshold region) ###
##########################################################################################

#if _withAnalysisExtraction_ && _DD_ && _MC_ && _isVg_

#set IDLIN_MC_uA        x
#set IDSAT_MC_uA        x
#set IOFF_MC_nA         x
#set VTL_MC_mV          x
#set VTS_MC_mV          x
#set SSlin_MC_mVdec     x
#set SSsat_MC_mVdec     x


## Current level for Vth extractions
set Io 3.0e-7
##set Io 4.0e-6

## Target off-current level
set Ioff_Target 0.1e-9


set dDDiv "dat_DD"
set dMCiv "dat_MC"

create_variable -name absId -dataset $dDDiv -function "abs(<I(drain):$dDDiv>)"
create_variable -name absId -dataset $dMCiv -function "abs(<I(drain):$dMCiv>)"

set VgDD       [get_variable_data "V(gate)"  -dataset $dDDiv]
set VdDD       [get_variable_data "V(drain)" -dataset $dDDiv]
set IdDD       [get_variable_data "absId"    -dataset $dDDiv]
set VgMC       [get_variable_data "V(gate)"  -dataset $dMCiv]
set absIdMC    [get_variable_data "absId"    -dataset $dMCiv]
set IdMC       [get_variable_data "I(drain)" -dataset $dMCiv]
set IdError    [get_variable_data "Id_error" -dataset $dMCiv]

## Remove the point which has > 10% monte-carlo error.
set VgMC1    [list]
set IdMC1    [list]
set absIdMC1 [list]
foreach vg $VgMC id $IdMC absid $absIdMC iderr $IdError {
 if { $iderr < 10.0 } {
  lappend VgMC1    $vg
  lappend IdMC1    $id
  lappend absIdMC1 $absid
 }
}

## Vth/Ioff/S.S. extractions for MC off-current estimation from DD IdVg curve

#if "@Type@" == "pMOS"
set VtMC    [lindex $VgMC1 end]
set Ivtmc   [lindex $absIdMC1 end]
set VgStart [lindex [lsort -real $VgDD] end]
#else
set VtMC    [lindex $VgMC1 0]
set Ivtmc   [lindex $absIdMC1 0]
set VgStart [lindex [lsort -real $VgDD] 0]
#endif
puts "VgStart= $VgStart \[V\] "

ext::ExtractSS   -out SS0   -name "noprint" -v $VgDD -i $IdDD -vo [expr $SIGN*1e-2]
ext::ExtractIoff -out Ioff0 -name "noprint" -v $VgDD -i $IdDD -vo [expr $SIGN*1e-4]
if { $Ioff0 > $Ivtmc } {
  ext::ExtractVti  -out VtMC  -name "noprint" -v $VgMC1 -i $absIdMC1 -io $Ioff0 -f %.3f
  set VtDD 0.0
  set Icut $Ioff0
} else {
  ext::ExtractVti  -out VtDD  -name "noprint" -v $VgDD -i $IdDD -io $Ivtmc -f %.3f
  set Icut $Ivtmc
}


if { $VtDD != "x" && $VtMC != "x" } {
 set deltaVt [expr ($VtMC - $VtDD)]
 create_variable -name Vgs -dataset $dDDiv -function "<V(gate):$dDDiv>+$deltaVt"
} else {
 puts "VtDD= $VtDD"
 puts "VtMC= $VtMC"
 puts "Icut= $Icut"
 puts "Please, check the Vt current level !!!"
 ##exit
}

set VgsDD   [get_variable_data "Vgs"      -dataset $dDDiv]



ext::ExtractValue  -out id  -name "noprint" -x $VgsDD -y $IdDD -xo $VgStart -f %.6e
if { $id == "x" } {
 set ioff [expr ($Ioff0/pow(10, ($SIGN*($deltaVt-$VgStart)*1.0e3/$SS0)))]
 puts "Estimated Ioff= [expr $ioff*1e9] nA at Vg= $VgStart \[V\]"

 lappend VgsDD $VgStart
 lappend IdDD $ioff
 set tsortList0 [list]
 foreach vg $VgsDD id $IdDD {
  lappend tsortList0 [list $vg $id]
 }
 set tsortList [lsort -real -index 0 $tsortList0]
 set VgsDD  [list]
 set IdDD   [list]
 foreach tl $tsortList {
  lappend VgsDD  [lindex $tl 0]
  lappend IdDD   [lindex $tl 1]
 }
}
puts "VgsDD :: $VgsDD"
puts "IdDD :: $IdDD"

set VgMCnew [list]
set VdMCnew [list]
set IdMCnew [list]
set IsMCnew [list]
foreach vg $VgDD vd $VdDD {
 ext::ExtractValue  -out id  -name "noprint" -x $VgMC1 -y $IdMC1 -xo $vg -f %.6e
 if { $id == "x" } {
  puts "Estimate Vg= $vg V bias point..."
  ext::ExtractValue  -out id  -name "noprint" -x $VgsDD -y $IdDD -xo $vg -f %.6e -yLog 1
  if { $id != "x" } {
   lappend IdMCnew [expr $SIGN*$id]
   lappend IsMCnew [expr -1.0*$SIGN*$id]
  } else {
   error "Problem in Vg= $vg V estimation !!!"
   # exit
  }
 } else {
  lappend IdMCnew $id
  lappend IsMCnew [expr -1.0*$id]
 }

 lappend VgMCnew $vg
 lappend VdMCnew $vd
}
puts "VgMCnew :: $VgMCnew"
puts "VdMCnew :: $VdMCnew"
puts "IdMCnew :: $IdMCnew"
puts "IsMCnew :: $IsMCnew"

set pltName "n@node@_GarandMCnew_${strTag}_${NodeId}"
set dMCneWiv "dat_MCnew"

create_variable -name V(gate)        -dataset $dMCneWiv -values $VgMCnew
create_variable -name V(drain)       -dataset $dMCneWiv -values $VdMCnew
create_variable -name I(drain)       -dataset $dMCneWiv -values $IdMCnew
create_variable -name I(source)      -dataset $dMCneWiv -values $IsMCnew

## generate .csv and .plt files of the full IdVg curves from Garand MC and DD.
export_variables {V(gate) V(drain) I(drain) I(source)} \
                 -dataset $dMCiv -filename "${pltName}.csv" -overwrite
writeIVplt "@pwd@/${pltName}.plt" $np $VgMCnew $VdMCnew $IdMCnew $IsMCnew

### Plot begin ###
set pid "Plot_Analysis"
create_plot -1d -name $pid
select_plots $pid

# loop over Y axes. Y1/Y2 linear/log or log/linear
foreach YaxisSet $YaxisSetList {

  set Yaxis  [lindex $YaxisSet 0]
  set Yscale [lindex $YaxisSet 1]
  set Yinv   [lindex $YaxisSet 2]

  create_curve -name C_ivdd_$Yscale       -dataset $dDDiv -axisX "V(gate)"  -axis${Yaxis} "I(drain)" 
  create_curve -name C_ivmc_$Yscale       -dataset $dMCiv -axisX "V(gate)"  -axis${Yaxis} "I(drain)" 
  create_curve -name C_ivdd_shift_$Yscale -dataset $dDDiv -axisX "Vgs"      -axis${Yaxis} "I(drain)" 

  set label "GarandDD Vds= $fixedVD \[V\]"
  set_curve_prop C_ivdd_$Yscale -label $label -color black -line_width 2 -line_style solid \
                 -hide_markers -markers_type circle -markers_size 7
  set label "GarandMC Vds= $fixedVD \[V\]"
  set_curve_prop C_ivmc_$Yscale -label $label -color blue -line_width 2 -line_style solid \
                 -show_markers -markers_type circle -markers_size 7
  set label "Shifted GarandDD Vds= $fixedVD \[V\]"
  set_curve_prop C_ivdd_shift_$Yscale -label $label -color black -line_width 3 -line_style dash \
                 -hide_markers -markers_type circle -markers_size 7                 

  # Set y-axis atributes
  set_axis_prop -axis [string tolower $Yaxis] -type $Yscale $Yinv \
          -title {I(drain) [A]} -title_font_size 20 -title_font_att bold \
          -scale_font_size 20  -scale_format scientific -scale_precision 1

};# end loop over linear and log scale

# Set x-axis properties
set_axis_prop -axis x -title {V(gate) [V]} \
              -title_font_size 20 -title_font_att bold -scale_font_size 20  
  
# Set title
set title "GarandMC IdVg Analysis"
set_plot_prop -title $title -title_font_size 20 -title_font_att bold

set_legend_prop -label_font_size 12 -label_font_att normal -position {0.45 0.90}

 #if _PNG_
export_view zFig_${pltName}_Analysis.png -format png -overwrite
 #endif


##
set pid "Plot_FullIdVg"
create_plot -1d -name $pid
select_plots $pid

# loop over Y axes. Y1/Y2 linear/log or log/linear
foreach YaxisSet $YaxisSetList {

  set Yaxis  [lindex $YaxisSet 0]
  set Yscale [lindex $YaxisSet 1]
  set Yinv   [lindex $YaxisSet 2]

  create_curve -name C_ivmc_$Yscale       -dataset $dMCiv    -axisX "V(gate)"  -axis${Yaxis} "I(drain)" 
  create_curve -name C_ivmcnew_$Yscale    -dataset $dMCneWiv -axisX "V(gate)"  -axis${Yaxis} "I(drain)" 

  set label "GarandMC Vds= $fixedVD \[V\]"
  set_curve_prop C_ivmc_$Yscale -label $label -color blue -line_width 2 -line_style solid \
                 -show_markers -markers_type circle -markers_size 7
  set label "New GarandMC Vds= $fixedVD \[V\]"
  set_curve_prop C_ivmcnew_$Yscale -label $label -color black -line_width 3 -line_style dash \
                 -hide_markers -markers_type circle -markers_size 7                 

  # Set y-axis atributes
  set_axis_prop -axis [string tolower $Yaxis] -type $Yscale $Yinv \
          -title {I(drain) [A]} -title_font_size 20 -title_font_att bold \
          -scale_font_size 20  -scale_format scientific -scale_precision 1

};# end loop over linear and log scale

# Set x-axis properties
set_axis_prop -axis x -title {V(gate) [V]} \
              -title_font_size 20 -title_font_att bold -scale_font_size 20  
  
# Set title
set title "GarandMC IdVg Analysis"
set_plot_prop -title $title -title_font_size 20 -title_font_att bold

set_legend_prop -label_font_size 12 -label_font_att normal -position {0.45 0.90}

 #if _PNG_
export_view zFig_${pltName}_fullIdVg.png -format png -overwrite
 #endif
### Plot end ###


#################################################################
### MC ET (IDLIN/IDSAT/IOFF) extractions
#################################################################

 #if @< abs(Vd)<0.1 >@
ext::ExtractValue  -out id  -name "noprint" -x $VgMCnew -y $IdMCnew -xo $VGATE -f %.6e
if { $id != "x" } { puts "DOE: IDLIN_MC_uA [format %.1f [expr abs($id * 1e6)]]" }

ext::ExtractSS     -out SS    -name "noprint" -v $VgMCnew -i $IdMCnew -vo [expr $SIGN*1e-2] -f %.1f
if { $SS != "x" } { puts "DOE: SSlin_MC_mVdec [format %.1f $SS]" }

ext::ExtractVti    -out Vti   -name "noprint" -v $VgMCnew -i $IdMCnew -io $Io -f %.3f
if { $Vti != "x" } { puts "DOE: VTL_MC_mV [format %.1f [expr $Vti*1e3]]" }

 #else
ext::ExtractValue  -out id  -name "noprint" -x $VgMCnew -y $IdMCnew -xo $VGATE -f %.6e
if { $id != "x" } { puts "DOE: IDSAT_MC_uA [format %.1f [expr abs($id * 1e6)]]" }

ext::ExtractSS     -out SS    -name "noprint" -v $VgMCnew -i $IdMCnew -vo [expr $SIGN*1e-2] -f %.1f
if { $SS != "x" } { puts "DOE: SSsat_MC_mVdec [format %.1f $SS]" }

ext::ExtractVti    -out Vti   -name "noprint" -v $VgMCnew -i $IdMCnew -io $Io -f %.3f
if { $Vti != "x" } { puts "DOE: VTS_MC_mV [format %.1f [expr $Vti*1e3]]" }

ext::ExtractIoff   -out Ioff  -name "noprint" -v $VgMCnew -i $IdMCnew -vo [expr $SIGN*1e-4] -f %.6e
if { $Ioff != "x" } { puts "DOE: IOFF_MC_nA [format %.2e [expr ($Ioff * 1e9)]]" }


set deltaVt_Target [expr $SIGN*(1.0e-3*$SS*log10($Ioff_Target/$Ioff))]
puts "DDDOE: deltaVt_Target_V [format %.4f $deltaVt_Target]"
puts "DOE: WF_gmc_Ioff [format %.3f [expr (@WF_init@-$deltaVt_Target)]]"

 #endif
#endif


#if _MC_
#############################################################
##### Monte-carlo IdVg simulation time (summation) ##########
#############################################################
set mcHourSum0 0
set mcMinSum0  0
set mcSecSum0  0
foreach mcTime $simTimeMClist {
  set mcTimes [split $mcTime "_"]
  set mcHour [string trim [lindex $mcTimes 0] "h"]
  set mcMin  [string trim [lindex $mcTimes 1] "m"]
  set mcSec  [string trim [lindex $mcTimes 2] "s"]

  set mcHourSum0 [expr ($mcHourSum0 + $mcHour)]
  set mcMinSum0  [expr ($mcMinSum0 + $mcMin)]
  set mcSecSum0  [expr ($mcSecSum0 + $mcSec)]
}
set mcSecSum [expr ($mcSecSum0 % 60)]

set mcMinSum0 [expr ($mcMinSum0 + int($mcSecSum0 / 60))]
set mcMinSum [expr ($mcMinSum0 % 60)]

set mcHourSum [expr ($mcHourSum0 + int($mcMinSum0 / 60))]

if { [expr ($mcHourSum/10)] < 1 } { set mcHourSum "0${mcHourSum}" }
if { [expr ($mcMinSum/10)]  < 1 } { set mcMinSum  "0${mcMinSum}" }
if { [expr ($mcSecSum/10)]  < 1 } { set mcSecSum  "0${mcSecSum}" }

puts "DOE: TotalMCsimTime ${mcHourSum}h_${mcMinSum}m_${mcSecSum}s"

#endif





