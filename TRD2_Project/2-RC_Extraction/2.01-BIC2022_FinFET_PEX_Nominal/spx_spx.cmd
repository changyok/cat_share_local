#setdep @node|rcnet@

set route n@node@
set flow @flow@
set gds @gds@
if {[string first "sram" $gds] != -1} {
set contactSpecs {
    WLR {box 0.0 0.045 0.003 0.01 0.03 0.03 {}}
    WLL {box 0.0 0.045 0.01 0.003 0.03 0.03 {}}
    BLU {box 0.0 0.045 0.022 0.022 0.004 0.004 {}}
    BLD {box 0.0 0.045 0.022 0.022 0.004 0.004 {}}
    BLBU {box 0.0 0.045 0.022 0.022 0.004 0.004 {}}
    BLBD {box 0.0 0.045 0.022 0.022 0.004 0.004 {}}
}
}
## Sample Pre-processing #######################################
### User-defined variables: Name Mean Sigma
set vars {
    fin_width     @Wns@   @Wss@
    #default poly mandrel bias is 0.000um
    poly_mandrel_bias @Pbn@ @Pbs@
    #default poly sadp spacer thickness 0.018um
    poly_sadp_spacer_thk @Psn@ @Pss@
    #default poly spacer2 thickness 0.002um
    poly_spacer2_thk @Ps2n@ @Ps2s@
    #nominal gate recess 0.010um
    gate_recess   @Grn@   @Grs@
    # nominal SD contact recess etch
    sdc_recess @SDCrn@ @SDCrs@
}

### Source random number tables
source "@pwd@/lhs20x10000.lut"
set method @method@      ;# options: sensitivity, sobol, simple,
                         ;#  lhs250, lhs500, lhs1000, lhs3000, lhs5000, lhs7000, lhs10000
set table [set $method]    ;# pass table from sampling.lut to $table
# set scut @scut@            ;# sigma cutoff
set scut 0.0            ;# sigma cutoff
set isplit @isplit@        ;# sample index

### Sample preprocessing
source @pwd@/sample_proc.tcl

set vsample [getSamples $vars $method $table $scut $isplit $num_columns]

#Assign values to variables
dict for { var val } $vsample {
    puts "variable $var : value $val"
    set $var $val
}

# Display Variable - Value 
if { 1 } {
    dict for { var val } $vsample {
        puts "DOE: $var [format %.4f $val]"
    }
    # exit
}



spx::connect \
    Connection=C1 \
    Host= @host@ \
    Port=@port@

# list materials
set matlist [spx::query Library= material Connection= C1] 
foreach mat $matlist {
   spx::material Name= $mat
}

set PERaphaelConfigFile @pwd@/PERaphaelConfig.tcl
set materialParamsFile @pwd@/MaterialParams.tcl

source @pwd@/meas_RC.tcl

set coords @bbox@
set coordsum ""
foreach coord $coords {
  set coord [expr $coord/1000.0]
  set coordsum "$coordsum $coord"
}
set coords [string trimleft $coordsum]
puts $coords

layout open @pwd@/@nodedir|rcnet@/n@node|rcnet@_rph.oasis ??

cell open @cell@

if {[string first "sram" $gds] == -1} {
puts "annotation for parasitics"

cell edit_state 1

# parasitic transistor annotation
array set nfins {
    invx1s 1
    invx1d 2
    invx1t 3
    invx2s 1
    invx2d 2
    invx2t 3
    nand2x1s 1
    nand2x1d 2
    nand2x1t 3
}
set cs @bbox@
foreach "x0 y0 x1 y1" $cs {}
set xc [expr ($x0+$x1)/2.0]
set yc [expr ($y0+$y1)/2.0]
set cpp 45; #gate pitch
set lg 16; #gate length
set fw 5; #fin width
set fp 26; #fin picth
set f0 20; #distance from center to first fin edge
set gatetextlayer 9:100
set sdtextlayer 10:1
# xp1 - pmos on the left edge
for {set i 0} {$i<$nfins(@cell@)} {incr i} {
    set y [expr $yc+$f0+$fw/2.0+$fp*$i]
    foreach text "xp1s xp1g xp1d" layer "$sdtextlayer $gatetextlayer $sdtextlayer" x "[expr $x0-$cpp/2.0] [expr $x0+2] [expr $x0+$cpp/2.0]" {
	cell object add text "layer $layer string $text coords {$x $y} mag 1 anchor center angle 0 mirror 0"
    }
}
# xn1 - nmos on the left edge
for {set i 0} {$i<$nfins(@cell@)} {incr i} {
    set y [expr $yc-$f0-$fw/2.0-$fp*$i]
    foreach text "xn1s xn1g xn1d" layer "$sdtextlayer $gatetextlayer $sdtextlayer" x "[expr $x0-$cpp/2.0] [expr $x0+2] [expr $x0+$cpp/2.0]" {
	cell object add text "layer $layer string $text coords {$x $y} mag 1 anchor center angle 0 mirror 0"
    }
}
# xp2 - pmos on the right edge
for {set i 0} {$i<$nfins(@cell@)} {incr i} {
    set y [expr $yc+$f0+$fw/2.0+$fp*$i]
    foreach text "xp2s xp2g xp2d" layer "$sdtextlayer $gatetextlayer $sdtextlayer" x "[expr $x1-$cpp/2.0] [expr $x1-2] [expr $x1+$cpp/2.0]" {
	cell object add text "layer $layer string $text coords {$x $y} mag 1 anchor center angle 0 mirror 0"
    }
}
# xn1 - nmos on the right edge
for {set i 0} {$i<$nfins(@cell@)} {incr i} {
    set y [expr $yc-$f0-$fw/2.0-$fp*$i]
    foreach text "xn2s xn2g xn2d" layer "$sdtextlayer $gatetextlayer $sdtextlayer" x "[expr $x1-$cpp/2.0] [expr $x1-2] [expr $x1+$cpp/2.0]" {
	cell object add text "layer $layer string $text coords {$x $y} mag 1 anchor center angle 0 mirror 0"
    }
}

# generate parasitic netlist
set fi [open n@node@_par.spi w]
puts $fi "XMPX1 xp1d xp1g @xp1s@ VBP p@parmodel@ m= 1 nfin= $nfins(@cell@)"
puts $fi "XMPX2 @xp2d@ xp2g xp2s VBP p@parmodel@ m= 1 nfin= $nfins(@cell@)"
puts $fi "XMNX1 xn1d xn1g @xn1s@ VBN n@parmodel@ m= 1 nfin= $nfins(@cell@)"
puts $fi "XMNX2 @xn2d@ xn2g xn2s VBN n@parmodel@ m= 1 nfin= $nfins(@cell@)"
close $fi

layout save -format oasis -rename n@node@_rph.oasis
catch {exec cp @pwd@/layout/@gds@.mac n@node@_rph.oasis.mac}


}

gauge load @pwd@/@gds@.ggs

spx::route \
    Route= $route

spx::clip \
    Route= $route \
    Clip= 1 \
    Name= H1 \
    Coords=  "$coords" \
    LayoutFile=  none

spx::flow \
    Route= $route \
    Flow= $flow \
    Connection= C1

### do split: 

set module "Fin_SADP_Spacer"

set step "depo_iso_oxideCVD_spacer"

set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    Time= [list [expr $fin_width] [list min]]

set step "etch_ansio_spacer"
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    Time= [list [expr $fin_width+0.023] [list min]]
    # overetch by 23nm

set module "Poly_SADP_Spacer"

set step "poly_mandrel_mask"
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    Bias= [list [expr $poly_mandrel_bias] [list um]]

set step "depo_iso_oxideCVD_spacer"
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    Time= [list [expr $poly_sadp_spacer_thk] [list min]]

set module "2nd_Spacer"

set step "depo_iso_SiN"
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    Time= [list [expr $poly_spacer2_thk] [list min]]

set module "Gate_Recess_n_Etchstop"
set step "etch_iso_gate_etchback"
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    Time= [list [expr $gate_recess] [list min]]


set module "TC_Formation"
set step "etch_aniso_simple_recess"
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    Time= [list [expr $sdc_recess] [list min]]

# We need to change the contact placement in the postprocessing
set module "HKMG"
set step "depo_iso_HfO2"
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    ContactsLayerName= CPOLYDISABLED

set module "PostProcess"
set step "interface_growth_hfo2_restore"
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    ContactsLayerName= CPOLY

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    ContactsPlacement= top

# Ensure the post-processing steps are run.
set steps [spx::show Route= $route Flow= $flow Module= $module Children= Step]
foreach step $steps {
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    Skip= false
}

# Patch the pins for the SRAM powerrail case.
if {[string first "sram" $gds] != -1} {
set sramM0pins PR_PINS
puts "M0 pins will be changed for SRAM"

set module "M0_Formation"
set step "depo_iso_Co"
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    ContactsLayerName= $sramM0pins

set step "depo_fill_Cu"
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    ContactsLayerName= $sramM0pins
}

set module "PostProcess_SRAM_outerdomain"
set steps [spx::show Route= $route Flow= $flow Module= $module Children= Step]
foreach step $steps {
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    Skip= true

if {[string first "sram" $gds] != -1} {
spx::modify \
    Target= [dict create ProcessStep $Loc1] \
    Skip= false
}
}

set selectivehighK @selectivehighK@

if { $selectivehighK == 1 } {
set module HKMG
set step depo_iso_HfO2
set Loc1 [spx::exist \
    Route= $route \
    Flow= $flow \
    Module= $module \
    Step= $step ]

spx::modify \
    Target= [dict create ProcessStep $Loc1] \
SelectiveMaterialsFilter= {{{Material equals OxideThermal}}}
}

#----

# RC Extraction

set module "RCX"
set step "meas_RC"

spx::module  Route= $route Flow= $flow Module= $module
spx::meas_RC Route= $route Flow= $flow Module= $module Step= $step \
   ExtractionType= resistance_capacitance FullCapacitanceMatrix= false Skip= false

#----

### end split

spx::run \
    Route= $route

# Inline metrology report.
set module "FIN Mandrel Litho"
set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_FIN_Mandrel_CD_1" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    puts "DOE: FIN_Mandrel_CD_1_$i [format %.4f $r]"
}

set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_FIN_Mandrel_CD_2" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    puts "DOE: FIN_Mandrel_CD_2_$i [format %.4f $r]"
}

set module "Fin_SADP_Spacer"
set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_FIN_SADP_Spacer_CD_1" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    puts "DOE: FIN_SADP_Spacer_CD_1_$i [format %.4f $r]"
}

set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_FIN_SADP_Spacer_CD_2" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    puts "DOE: FIN_SADP_Spacer_CD_2_$i [format %.4f $r]"
}

set module "Fin_Formation"
set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_FIN_Spacing_CD_1" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    puts "DOE: FIN_Spacing_CD_1_$i [format %.4f $r]"
}

set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_FIN_Spacing_CD_2" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    puts "DOE: FIN_Spacing_CD_2_$i [format %.4f $r]"
}

set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_FIN_CD_1_midWidth" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    puts "DOE: FIN_CD_1_midWidth_$i [format %.4f $r]"
}

set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_FIN_CD_2_midWidth" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    puts "DOE: FIN_CD_2_midWidth_$i [format %.4f $r]"
}

set module "Poly_SADP_Spacer"
set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_Poly_Mandrel_CD" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    puts "DOE: Poly_Mandrel_CD_$i [format %.4f $r]"
}

set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_Poly_Spacer_CD" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    puts "DOE: Poly_Spacer_CD_$i [format %.4f $r]"
}

set module "Poly_Final"
set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_Poly_CD_FinTop" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    puts "DOE: Poly_CD_FinTop_$i [format %.4f $r]"
}

set module "NMOS_SD_Epi"
set o [spx::show Route= $route Flow= @flow@ Module= $module Step= "meas_CD_spacer_nitride2_fintop" Parameters= Output]
set v [lindex $o 1]
# Iterate results
for {set i 0} {$i < [llength $v]} {incr i} {
    set r [lindex $v $i 0]
    catch {puts "DOE: NMOS_SD_Spacer_CD_FinTop_$i [format %.4f $r]"}
}

#if @saveRoute@ == 1
spx::rename Route= $route NewName= @flow@_@node@
spx::save \
    Route= @flow@_@node@ \
    Connection = C1 \
    HostMaterials= true \
    Overwrite = true
#endif



exit
