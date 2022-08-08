#-----------------------------------------------------------------------------------------
# This template measures the effective mass in sdevice
# and converts the calibrated effective masses of Garand DD density-gradient model
# to alpha parameters in sdevice density-gradient model.
# This is tested using svisual version R-2020.09.
#-----------------------------------------------------------------------------------------

#setdep @node|mn_Extraction@

#define _TechType_  @TechType@
#if "_TechType_" == "CFET"
#define _TechType_  GAA
#elif "_TechType_" == "VFET"
#define _TechType_  GAA
#elif "_TechType_" == "SRAM"
#define _TechType_  GAA
#endif


#set mnFin          x
#set mnStop         x

#set alpha1_Fin     x
#set alpha2_Fin     x
#set alpha3_Fin     x

#set alpha1_Stop    x
#set alpha2_Stop    x
#set alpha3_Stop    x


#if "@Type@" == "nMOS"
 set dosMass  "eRelativeEffectiveMass"
 set dosName  "eEffectiveStateDensity"
#else
 set dosMass  "hRelativeEffectiveMass"
 set dosName  "hEffectiveStateDensity"
#endif

set Tstop     50.0e-3                ;# channel stop/well thickness


set did "SD_tdr"
set tdr_file "@nodedirpath|mn_Extraction@/n@node|mn_Extraction@_des.tdr"
load_file $tdr_file -name $did
create_plot -dataset $did
set pid "Plot_$did"
select_plots $pid

# Measure mn's in 'Channel' and 'ChannelStop'.
puts "~~~ $dosMass ~~~"
set_field_prop -plot $pid -geom $did $dosMass -show_bands
set xp 0.0
set mnFin [probe_field -coord "$xp 0.0" -field $dosMass -plot $pid -region Channel -geom $did]
puts "DOE: mnFin [format %.4f $mnFin]"

#if "_TechType_" == "BulkFinFET"
set x1 @<0.5e-3*H>@
set xp [expr ($x1 + 0.5*$Tstop)]
set mnStop [probe_field -coord "$xp 0.0" -field $dosMass -plot $pid -region ChannelStop -geom $did]
##puts "DOE: mnStop $mnStop"
puts " mnStop $mnStop"
puts "~~~~~~~~~~~~~~~"
#endif

# Measure DOS's in 'Channel' and 'ChannelStop'.
puts "~~~ $dosName ~~~"
set_field_prop -plot $pid -geom $did $dosName -show_bands
set xp 0.0
set dosValue [probe_field -coord "$xp 0.0" -field $dosName -plot $pid -region Channel -geom $did]
puts " dosFin $dosValue"

#if "_TechType_" == "BulkFinFET"
set Tstop     50.0e-3                ;# channel stop/well thickness
set x1 @<0.5e-3*H>@
set xp [expr ($x1 + 0.5*$Tstop)]
set dosValue [probe_field -coord "$xp 0.0" -field $dosName -plot $pid -region ChannelStop -geom $did]
puts " dosStop $dosValue"
puts "~~~~~~~~~~~~~~~"
#endif

#if "_TechType_" == "BulkFinFET"
set rList   [list "Fin" "Stop"]
set mnList  [list $mnFin $mnStop]
#else
set rList   [list "Fin"]
set mnList  [list $mnFin]
#endif
foreach r $rList mn $mnList {
  puts "~~ mn${r}  = $mn "

  set alpha3 [expr $mn/5.0]
  set alpha2 [expr $mn/@horiz_semi_opt@]
  set alpha1 [expr $mn/@vert_semi_opt@]

puts "DOE: alpha1_${r} [format %.4f $alpha1]"
puts "DOE: alpha2_${r} [format %.4f $alpha2]"
puts "DOE: alpha3_${r} [format %.4f $alpha3]"
}


