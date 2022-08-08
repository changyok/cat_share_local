#############################################################
### This template generates Bulk-FinFET structure for DTCO.
### This is tetsed using version R-2020.09.
#############################################################

## specifies the number of parallel threads for Sentaurus Process
math  numThreads=@Threads@

## Add new materials
mater add name=SiGeSD            new.like=SiliconGermanium  alt.matername=SiliconGermanium
mater add name=SiSD              new.like=Silicon           alt.matername=Silicon
mater add name=SiGeStop          new.like=SiliconGermanium  alt.matername=SiliconGermanium
mater add name=SiStop            new.like=Silicon           alt.matername=Silicon
mater add name=LowK              new.like=Oxide
mater add name=SiOCN             new.like=Oxide
mater add name=InterfacialOxide  new.like=Oxide

## Channel, source/drain, channel stop material names
#define  _ChMat_    SiliconGermanium
#define  _SdMat_    SiGeSD
#define  _StopMat_  SiGeStop

## X or Z
#define _ChanDir_     @Channel_UCS@
set ChanDir    @Channel_UCS@

#if "_ChanDir_" == "z"
#define _TopSurfDir_  x
set TopSurfDir x
#define _whereCut_    left

#elif "_ChanDir_" == "x"
#define _TopSurfDir_  z
set TopSurfDir z
#define _whereCut_    left
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

## Garand Monte-Carlo can simulate the half structure.
#define _isHalf_          1

## Generate Atomic Layer Deposition HKMG (High-K Metal Gate) structure 
## or selectivedepo HKMG structure.
#define _isSelectiveHKMG_ @SelectiveGate@
#if _isSelectiveHKMG_
#define _isALDHKMG_       0
#else
#define _isALDHKMG_       1
#endif

#---------------------------------------------------------------------#
#   SIMULATION CONTROLL
## save the boundary TDR files at the mid-process steps
set debug         1

#---------------------------------------------------------------------#
#   USER-DEFINED PROCEDURES

source @pwd@/user_proc.fps

## procedure to save the boundary TDR file
proc WriteBND {} {
        global count

        if { $count < 10} {
           struct tdr.bnd=n@node@_0${count}
        } else {
           struct tdr.bnd=n@node@_${count}
        }
        set count [expr $count+1]
}
set count 1

#
#---------------------------------------------------------------------#

source @pwd@/PH_LIB.fps

# Start with mgoal mode
sde off
#-----------------------------------------------------
# Structure parameters, [um]
set W        @<W*1.0e-3>@            ;# cross-section width
set H        @<H*1.0e-3>@            ;# cross-section height
set tox      @<Tiox*1.0e-3>@         ;# gox thickness
set thfo2    @<Thfo2*1.0e-3>@        ;# HfO2 thickness
set Lg       @<Lg*1.0e-3>@           ;# channel length
set Lhk      $thfo2                  ;# high-k length in the channel direction for ALD-HKMG
set Tsp      @<Tspacer*1.0e-3>@      ;# spacer length
set Lsd      [expr ($Tsp)]           ;# source/drain extension length
#if _isSelectiveHKMG_
set Ppitch   [expr ($Lg+2.0*$Lsd)]   ;# total length of the simulation structure
                                     ;# in the channel direction
#else
set Ppitch   [expr ($Lg+2.0*$Lhk+2.0*$Lsd)]   ;# total length of the simulation structure
                                              ;# in the channel direction
#endif

#if _isSelectiveHKMG_
set Ppitch0 [expr ($Lg+2.0*$Lsd)]
if { $Ppitch < $Ppitch0 } {
  puts "Ppitch ( = $Ppitch ) should be larger than Lg+2*Lsd ( = $Ppitch0 ) !!!"
  exit
}
#else
set Ppitch0   [expr ($Lg+2.0*$Lhk+2.0*$Lsd)] 
if { $Ppitch < $Ppitch0 } {
  puts "Ppitch ( = $Ppitch ) should be larger than Lg+2*Lhk+2*Lsd ( = $Ppitch0 ) !!!"
  exit
}
#endif

set tm       0.005                   ;# metal gate thickness
set Tstop     50.0e-3                ;# channel stop/well thickness


#----- minimum mesh size -----
set dx      0.2e-3                   ;# in the cross-section
set dz      0.5e-3                   ;# along the channel direction


#----- Doping parameters, [/cm3] -----
set Nch      @Nch@                            ;# channel doping
set Nsd      @Nsde@                           ;# SDE doping
set Nstop    @Nstop@                          ;# channel stop doping

#if "@Type@" == "nMOS"
set Dch      "Boron"                          ;# channel dopant
set Dsd      "Phosphorus"                     ;# source/drain dopant
set Dstop    "Boron"                          ;# channel stop dopant

#else
set Dch      "Phosphorus"                     ;# channel dopant
set Dsd      "Boron"                          ;# source/drain dopant
set Dstop    "Phosphorus"                     ;# channel stop dopant

#endif

#----- channel Germanium Mole Fraction -----
set GeMoleCh @GeMoleCh@
set GeMoleSD @GeMoleSD@

# Control parameters of Germanium profile
set dGe  0.001

#-----------------------------------------------------
# Derived dimensions
set AX0     [expr (-0.5*$H)]
set AX1     [expr ( 0.5*$H)]
set AY0     [expr (-0.5*$W)]
set AY1     [expr ( 0.5*$W)]

set L0      [expr (-0.5*$Lg)]
set L1      [expr ( 0.5*$Lg)]
set Lox0    [expr (-0.5*$Lg-$Lhk)]
set Lox1    [expr ( 0.5*$Lg+$Lhk)]

#if _isSelectiveHKMG_
set Z0      [expr ($L0-$Lsd)]
set Z1      [expr ($L1+$Lsd)]
set Z01     [expr ($L0-0.5*$Lsd)]
set Z11     [expr ($L1+0.5*$Lsd)]
#else
set Z0      [expr ($Lox0-$Lsd)]
set Z1      [expr ($Lox1+$Lsd)]
set Z01     [expr ($Lox0-0.5*$Lsd)]
set Z11     [expr ($Lox1+0.5*$Lsd)]
#endif

set Xox0    [expr ($AX0-$tox)]
set Xox1    [expr ($AX1+$tox)]
set Yox0    [expr ($AY0-$tox)]
set Yox1    [expr ($AY1+$tox)]

set X0      [expr ($AX0-$tox-$thfo2)]
set X1      [expr ($AX1+$tox+$thfo2)]
set Y0      [expr ($AY0-$tox-$thfo2)]
set Y1      [expr ($AY1+$tox+$thfo2)]

set X0gas   [expr ($X0-$tm)]
set X1gas   [expr ($X1+$tm)]
set X1soi   [expr ($AX1+$tm)]
set X1stop  [expr ($X1+$Tstop)]
set Y0gas   [expr ($Y0-$tm)]
set Y1gas   [expr ($Y1+$tm)]

# Control parameters of doping profile
set sigma 0.001
set dLud  0.002
set Lud0  [expr ($L0-$dLud)]
set Lud1  [expr ($L1+$dLud)]


#-----------------------------------------------------

# 
#---------------------------------------------------------------------#

##SetTDRList   {Dopants} !Solutions

## define the lines in the simulation structure
line _ChanDir_ loc=$Z0     tag=SD0          spacing=2.0*$dz
##line _ChanDir_ loc=$Z01    tag=SD01         spacing=0.05*$Lsd
line _ChanDir_ loc=$Lox0   tag=Lox0         spacing=$dz
line _ChanDir_ loc=$L0     tag=Lg0          spacing=$dz
line _ChanDir_ loc=0.0     tag=CenL         spacing=0.05*$Lg
line _ChanDir_ loc=$L1     tag=Lg1          spacing=$dz
line _ChanDir_ loc=$Lox1   tag=Lox1         spacing=$dz
##line _ChanDir_ loc=$Z11    tag=SD11         spacing=0.05*$Lsd
line _ChanDir_ loc=$Z1     tag=SD1          spacing=2.0*$dz

line y loc=$Y0gas  tag=GasY0        spacing=2.0*$dx
line y loc=$Y0     tag=Wfhf0        spacing=2.0*$dx
line y loc=$Yox0   tag=Wfox0        spacing=$dx
line y loc=$AY0    tag=Wf0          spacing=$dx
line y loc=0.0     tag=CenW         spacing=0.05*$W
line y loc=$AY1    tag=Wf1          spacing=$dx
line y loc=$Yox1   tag=Wfox1        spacing=$dx
line y loc=$Y1     tag=Wfhf1        spacing=2.0*$dx
line y loc=$Y1gas  tag=GasY1        spacing=2.0*$dx

line _TopSurfDir_ loc=$X0gas  tag=GasX0        spacing=2.0*$dx
line _TopSurfDir_ loc=$X0     tag=Hfhf0        spacing=2.0*$dx
line _TopSurfDir_ loc=$Xox0   tag=Hfox0        spacing=$dx
line _TopSurfDir_ loc=$AX0    tag=Hf0          spacing=$dx
line _TopSurfDir_ loc=0.0     tag=CenH         spacing=0.05*$H
line _TopSurfDir_ loc=$AX1    tag=Hf1          spacing=$dx
#if "_TechType_" == "BulkFinFET"
line _TopSurfDir_ loc=$X1stop tag=GasX1        spacing=10.0*$dx  
#elif "_TechType_" == "FinFET"
line _TopSurfDir_ loc=$X1soi  tag=GasX1        spacing=2.0*$dx
#else
line _TopSurfDir_ loc=$Xox1   tag=Hfox1        spacing=$dx
line _TopSurfDir_ loc=$X1     tag=Hfhf1        spacing=2.0*$dx
line _TopSurfDir_ loc=$X1gas  tag=GasX1        spacing=2.0*$dx
#endif

##############################################

#if "_ChanDir_" == "z"
region Oxynitride  zlo=SD0  zhi=SD1  ylo=GasY0  yhi=GasY1 xlo=GasX0 xhi=GasX1 name=OxyN
#elif "_ChanDir_" == "x"
region Oxynitride  xlo=SD0  xhi=SD1  ylo=GasY0  yhi=GasY1 zlo=GasX0 zhi=GasX1 name=OxyN
#endif

init 

## define the corner rounding radius
## sharp corner when radius < 0
if { $W < $H } { 
  set Ra [expr (0.5*$W)]
} else { 
  set Ra [expr (0.5*$H)] 
}
## define the corner radiuses of the layers
set Rtm [expr ($Ra+$tox+$thfo2+$tm)]
set Rhf [expr ($Ra+$tox+$thfo2)]
set Rox [expr ($Ra+$tox)]
set Rnw $Ra

## define the width and height of the cross-section
set Wtm [expr ($W+2.0*($tox+$thfo2+$tm))]
set Htm [expr ($H+2.0*($tox+$thfo2+$tm))]
set Whf [expr ($W+2.0*($tox+$thfo2))]
set Hhf [expr ($H+2.0*($tox+$thfo2))]
set Wox [expr ($W+2.0*($tox))]
set Hox [expr ($H+2.0*($tox))]
set Wa  $W
set Ha  $H

set centerCoord  [list 0.0 0.0 0.0]

##-- Tungsten gate metal
set cuboidSize   [list $Htm $Wtm $Ppitch]
PolyHedronRoundedCuboid mt $centerCoord $cuboidSize $Rtm _ChanDir_ _TechType_
##PolyHedronRoundedCuboid mt $centerCoord $cuboidSize -1 _ChanDir_ _TechType_
polyhedron list
insert polyhedron=mt replace.materials= { Oxynitride } new.material=Tungsten new.region=GateMetal
PolyHedronClear
if { $debug } { WriteBND }

##-- HfO2 gate high-k
set cuboidSize   [list $Hhf $Whf $Ppitch]
PolyHedronRoundedCuboid hf $centerCoord $cuboidSize $Rhf _ChanDir_ _TechType_
polyhedron list
insert polyhedron=hf replace.materials= { Tungsten Oxynitride } new.material=HfO2 new.region=GateHighK
PolyHedronClear
if { $debug } { WriteBND }

##-- Spacer HighK for ALD HKMG
set brickSlist [list $X0gas-0.001 $Y0gas-0.001 $Z0-0.1 $X1gas+0.001 $Y1gas+0.001 $L0]
BrickGeneration ghfs $brickSlist {Tungsten} HfO2 GateHighK _ChanDir_ _isALDHKMG_

set brickDlist [list $X0gas-0.001 $Y0gas-0.001 $L1 $X1gas+0.001 $Y1gas+0.001 $Z1+0.1]
BrickGeneration ghfd $brickDlist {Tungsten} HfO2 GateHighK _ChanDir_ _isALDHKMG_
if { $debug } { WriteBND }

##-- gate oxide
set cuboidSize   [list $Hox $Wox $Ppitch]
PolyHedronRoundedCuboid gox $centerCoord $cuboidSize $Rox _ChanDir_ _TechType_
polyhedron list
insert polyhedron=gox replace.materials= { HfO2 } new.material=InterfacialOxide new.region=GateOxide
PolyHedronClear
if { $debug } { WriteBND }

##-- active region
set cuboidSize   [list $Ha $Wa $Ppitch]
PolyHedronRoundedCuboid active $centerCoord $cuboidSize $Ra _ChanDir_ _TechType_
polyhedron list
insert polyhedron=active replace.materials= { InterfacialOxide } new.material=_ChMat_ new.region=Channel
PolyHedronClear
if { $debug } { WriteBND }


##############################################
##### SOI-FinFET #############################
##### define SOI region ######################
#if "_TechType_" == "FinFET"
##set brickSOIlist [list $AX1 $Y0gas-0.1 $Z0-0.1 $X1gas+0.1 $Y1gas+0.1 $Z1+0.1]
set brickSOIlist [list $AX1 $Y0gas-0.1 $Z0-0.1 $AX1+$tm $Y1gas+0.1 $Z1+0.1]
BrickGeneration soi $brickSOIlist {Tungsten Oxynitride HfO2 InterfacialOxide} Oxide SOI _ChanDir_ 1
set brickDummylist [list $AX1 $Y0gas-0.1 $Z0-0.1 $X1gas+0.1 $Y1gas+0.1 $Z1+0.1]
BrickGeneration dummy $brickDummylist {Tungsten Oxynitride HfO2 InterfacialOxide} Gas Dummy _ChanDir_ 1
if { $debug } { WriteBND }
#endif


##############################################
##### Bulk-FinFET ############################
##### define bottom high-k region ############
#####        ChannelStop/STI regions #########
#if "_TechType_" == "BulkFinFET"
##-- STI
set brickSTIlist [list $X1 -100.0 -100.0 100.0 100.0 100.0]
BrickGeneration sti $brickSTIlist {Tungsten Oxynitride HfO2} Oxide STI _ChanDir_ 1
if { $debug } { WriteBND }

##-- Bottom High-K
set brickBottomHKlist [list $AX1 $Y0gas-0.001 $Z0-0.1 $X1 $Y1gas+0.001 $Z1+0.1]
BrickGeneration ghfb $brickBottomHKlist {Tungsten} HfO2 GateHighK _ChanDir_ 1
if { $debug } { WriteBND }

##-- Bottom gate oxide
set brickBottomGOXlist [list $AX1 $Yox0 $L0 $X1 $Yox1 $L1]
BrickGeneration gox $brickBottomGOXlist {HfO2} InterfacialOxide GateOxide _ChanDir_ 1
if { $debug } { WriteBND }

##-- Channel Stop
set brickChannelStoplist [list $AX1 $AY0 $Z0-0.1 $X1stop+0.1 $AY1 $Z1+0.1]
BrickGeneration cstop $brickChannelStoplist {Oxide HfO2 InterfacialOxide Tungsten} _StopMat_ ChannelStop _ChanDir_ 1
if { $debug } { WriteBND }
#endif


##############################################
##### define source/drain regions
set brickSACTIVElist [list $AX0-0.001 $AY0-0.001 $Z0-0.1 $AX1+0.001 $AY1+0.001 $L0]
BrickGeneration s1 $brickSACTIVElist {_ChMat_} _SdMat_ cSource _ChanDir_ 1

set brickDACTIVElist [list $AX0-0.001 $AY0-0.001 $L1 $AX1+0.001 $AY1+0.001 $Z1+0.1]
BrickGeneration d1 $brickDACTIVElist {_ChMat_} _SdMat_ cDrain _ChanDir_ 1
if { $debug } { WriteBND }
##

##############################################
##### define source/drain spacers
#if _isALDHKMG_
set brickSSPlist [list $X0-0.1 $Y0-0.1 $Z0-0.1 $X1+0.1 $Y1+0.1 $Lox0]
set brickDSPlist [list $X0-0.1 $Y0-0.1 $Lox1 $X1+0.1 $Y1+0.1 $Z1+0.1]
#else
set brickSSPlist [list $X0-0.1 $Y0-0.1 $Z0-0.1 $X1+0.1 $Y1+0.1 $L0]
set brickDSPlist [list $X0-0.1 $Y0-0.1 $L1 $X1+0.1 $Y1+0.1 $Z1+0.1]
#endif

BrickGeneration slk $brickSSPlist {Tungsten HfO2 InterfacialOxide} LowK SPs _ChanDir_ 1
BrickGeneration dlk $brickDSPlist {Tungsten HfO2 InterfacialOxide} LowK SPd _ChanDir_ 1
if { $debug } { WriteBND }

##############################################
## make it half structure
#if _isHalf_
transform cut location= 0.0 _whereCut_ !remesh
if { $debug } { WriteBND }
#endif


###############################################################################
### Specify the doping profiles ##and activate the dopant

set dopFunctionL  "$Nsd*(exp(-1*(($ChanDir-$Lud0)/$sigma)^2)+exp(-1*(($ChanDir-$Lud1)/$sigma)^2))"

#if "_TechType_" == "BulkFinFET"
##set dopFunctionH  "$Nsd*exp(-1*(($TopSurfDir-$AX1)/(0.1*$sigma))^2)"
##set dopFunctionLH "$Nsd*(exp(-1*(($ChanDir-$Lud0)/$sigma)^2)+exp(-1*(($ChanDir-$Lud1)/$sigma)^2))*exp(-1*(($TopSurfDir-$AX1)/(0.1*$sigma))^2)"
##set rEgions [list Channel cDrain cSource GateOxide GateHighK SPd SPs ChannelStop STI]
set rEgions [list Channel cDrain cSource GateOxide SPd SPs]
foreach r $rEgions {
##select name=$Dsd region=$r  store  z=($TopSurfDir<$AX1)?(($ChanDir<$Lud0)?$Nsd:(($ChanDir<$Lud1)?$dopFunctionL:$Nsd)):(($ChanDir<$Lud0)?$dopFunctionH:(($ChanDir<$Lud1)?$dopFunctionLH:$dopFunctionH))
select name=$Dsd region=$r  store  z=($ChanDir>0)?(($ChanDir>$Lud1)?($Nsd):($Nsd*exp(-1*(($ChanDir-$Lud1)/$sigma)^2))):(($ChanDir<$Lud0)?($Nsd):($Nsd*exp(-1*(($ChanDir-$Lud0)/$sigma)^2)))
}

##set rEgions [list ChannelStop STI]
set rEgions [list ChannelStop]
foreach r $rEgions {
select name=$Dstop region=$r  store  z=$Nstop
}

#else
set rEgions [list Channel cDrain cSource GateOxide GateHighK SPd SPs]
foreach r $rEgions {
select name=$Dsd region=$r  store  z=($ChanDir<$Lud0)?$Nsd:(($ChanDir<$Lud1)?$dopFunctionL:$Nsd)
}

#endif

##diffuse temp=500.0 time=1.0 stress.relax


###############################################################################
## linear grading of Ge Mole concentration

set NchGe [lindex [MoleFractionFields SiGe $GeMoleCh] 5]
set NsdGe [lindex [MoleFractionFields SiGe $GeMoleSD] 5]
set NchSi [lindex [MoleFractionFields SiGe $GeMoleCh] 2]
set NsdSi [lindex [MoleFractionFields SiGe $GeMoleSD] 2]
if { $NsdGe > $NchGe } { 
 set NgeHigh $NsdGe ; set NgeLow $NchGe 
} else {
 set NgeHigh $NchGe ; set NgeLow $NsdGe 
}
if { $NsdSi > $NchSi } { 
 set NsiHigh $NsdSi ; set NsiLow $NchSi 
} else {
 set NsiHigh $NchSi ; set NsiLow $NsdSi 
}

set dGe  0.000
set L0sh [expr $L0+$dGe]
set L1sh [expr $L1-$dGe]
set Z0sh [expr $Z0+$dGe]
set Z1sh [expr $Z1-$dGe]

set slopeGe [expr ($NsdGe-$NchGe)/($Lsd + _isALDHKMG_ * ($tox + $thfo2))]
set slopeSi [expr ($NsdSi-$NchSi)/($Lsd + _isALDHKMG_ * ($tox + $thfo2))]

set geFunction0  "($NchGe-($ChanDir-$L0sh)*$slopeGe)"
set geFunction1  "($NchGe+($ChanDir-$L1sh)*$slopeGe)"
set siFunction0  "($NchSi-($ChanDir-$L0sh)*$slopeSi)"
set siFunction1  "($NchSi+($ChanDir-$L1sh)*$slopeSi)"

set rEgions [list Channel cDrain cSource GateOxide GateHighK SPd SPs]
foreach r $rEgions {
select name=Germanium region=$r   store  z="($ChanDir<$Z0sh)?$NsdGe:(($ChanDir<$L0sh)?$geFunction0:(($ChanDir<$L1sh)?$NchGe:(($ChanDir<$Z1sh)?$geFunction1:$NsdGe)))"
select name=Silicon region=$r   store  z="($ChanDir<$Z0sh)?$NsdSi:(($ChanDir<$L0sh)?$siFunction0:(($ChanDir<$L1sh)?$NchSi:(($ChanDir<$Z1sh)?$siFunction1:$NsdSi)))"
}

#if "_TechType_" == "BulkFinFET"
set Hge 0.005
set Hsh [expr $AX1+$Hge]

set slopeGeH [expr ($NchGe-$NsdGe)/$Hge]
set slopeSiH [expr ($NchSi-$NsdSi)/$Hge]

set geFunctionH    "($NsdGe+($TopSurfDir-$AX1)*$slopeGeH)"
set siFunctionH    "($NsdSi+($TopSurfDir-$AX1)*$slopeSiH)"
set geFunctionLH0  "(($NsdGe+($TopSurfDir-$AX1)*$slopeGeH)*($NchGe-($ChanDir-$L0sh)*$slopeGe)/$NsdGe)"
set geFunctionLH1  "(($NsdGe+($TopSurfDir-$AX1)*$slopeGeH)*($NchGe+($ChanDir-$L1sh)*$slopeGe)/$NsdGe)"
set siFunctionLH0  "(($NsdSi+($TopSurfDir-$AX1)*$slopeSiH)*($NchSi-($ChanDir-$L0sh)*$slopeSi)/$NsdSi)"
set siFunctionLH1  "(($NsdSi+($TopSurfDir-$AX1)*$slopeSiH)*($NchSi+($ChanDir-$L1sh)*$slopeSi)/$NsdSi)"

set rEgions [list ChannelStop STI]
foreach r $rEgions {
select name=Germanium region=$r   store  z="($ChanDir<$Z0sh)?$geFunctionH:(($ChanDir<$L0sh)?$geFunctionLH0:(($ChanDir<$L1sh)?$NchGe:(($ChanDir<$Z1sh)?$geFunctionLH1:$geFunctionH)))"
select name=Germanium region=$r   store  z="(Germanium>$NgeHigh)?$NgeHigh:((Germanium<$NgeLow)?$NgeLow:Germanium)"

select name=Silicon   region=$r   store  z="($ChanDir<$Z0sh)?$siFunctionH:(($ChanDir<$L0sh)?$siFunctionLH0:(($ChanDir<$L1sh)?$NchSi:(($ChanDir<$Z1sh)?$siFunctionLH1:$siFunctionH)))"
select name=Silicon region=$r   store  z="(Silicon>$NsiHigh)?$NsiHigh:((Silicon<$NsiLow)?$NsiLow:Silicon)"
}

#endif

struct tdr= n@node@_0_fps.tdr !Gas !interfaces alt.maternames pdb !bnd !Adaptive

diffuse temp=500 time=1.0<s> stress.relax

###############################################################################


### Save TDR file
struct tdr= n@node@_fps.tdr !Gas !interfaces alt.maternames pdb !bnd !Adaptive


exit


