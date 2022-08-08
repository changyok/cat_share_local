####################################################################################################
### This template computes the carrier density profile using Schroedinger equation.
### Gate bias is ramped from 0V to VDD.
### The results will be used as a target reference of the Garand density-gradient model calibration.
### This is tetsed using R-2020.09.
####################################################################################################


#setdep @node|xslice@

## X or Z
#define _ChanDir_     @Channel_UCS@

#if "_ChanDir_" == "z"
#define _TopSurfDir_  x
#elif "_ChanDir_" == "x"
#define _TopSurfDir_  z
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

#define _MaterialCH_    SiGe
#define _GeMoleCh_      @GeMoleCh@
#define _MaterialSTOP_  SiGe
#define _GeMoleSTOP_    @GeMoleCh@


# Get Ninv or Pinv based on carrier Type
proc getInversionCharge { }  {
  if { [string compare @Type@ nMOS]==0 } {
    set Ninv [Extract model=eDensity region=Channel integral]
  } else {
    set Ninv [Extract model=hDensity region=Channel integral]
  }

  return $Ninv
}


# Specify new materials
Material name=InterfacialOxide type=insulator
Material name=HfO2             type=insulator
Material name=SiliconGermanium type=semiconductor


sBandSet nThreads=@Threads@

# Load device structure
LoadDevice tdrFile="@nodedirpath|xslice@/n@node|xslice@_x_msh.tdr"

# Set the temperature
##Physics temperature=300.0
Physics temperature=@<Temperature+273>@

######################################
### Set the insulator band parameters

### InterfacialOxide parameters
##Physics material=InterfacialOxide Permittivity  epsilon=3.9
Physics material=InterfacialOxide Permittivity  epsilon=@iOxide_perm@
Physics material=InterfacialOxide Affinity      chi=0.9
Physics material=InterfacialOxide Bandgap       Eg=9.0
set oxMass  0.5
set oxGamma 2.0
# Setup conduction valleys
foreach valley [list GammaC L1 L2 L3 L4 X1 X2 X3] {
  Physics material=InterfacialOxide ValleyModel=ConstantEllipsoid name=$valley \
          degeneracy=2 kl=[list 1 0 0] kt1=[list 0 1 0] kt2=[list 0 0 1] \
          ml=$oxMass mt1=$oxMass mt2=$oxMass alpha=0.0 Eshift=0.0 useForEBulkDensity=0
}
# Setup valence valley
Physics material=InterfacialOxide ValleyModel=6kpValley name=Gamma \
        degeneracy=1 gamma1=$oxGamma gamma2=0.0 gamma3=0.0 delta=0.0 \
        a_v=0.0 b=0.0 d=0.0 useForHBulkDensity=0


#if "_TechType_" == "BulkFinFET" || "_TechType_" == "FinFET"

### Oxide parameters
Physics material=Oxide Permittivity  epsilon=3.9
Physics material=Oxide Affinity      chi=0.9
Physics material=Oxide Bandgap       Eg=9.0
set oxMass  0.5
set oxGamma 2.0
# Setup conduction valleys
foreach valley [list GammaC L1 L2 L3 L4 X1 X2 X3] {
  Physics material=Oxide ValleyModel=ConstantEllipsoid name=$valley \
          degeneracy=2 kl=[list 1 0 0] kt1=[list 0 1 0] kt2=[list 0 0 1] \
          ml=$oxMass mt1=$oxMass mt2=$oxMass alpha=0.0 Eshift=0.0 useForEBulkDensity=0
}
# Setup valence valley
Physics material=Oxide ValleyModel=6kpValley name=Gamma \
        degeneracy=1 gamma1=$oxGamma gamma2=0.0 gamma3=0.0 delta=0.0 \
        a_v=0.0 b=0.0 d=0.0 useForHBulkDensity=0

#endif


### HfO2 parameters
##Physics material=HfO2 Permittivity epsilon=18.0
Physics material=HfO2 Permittivity epsilon=@HfO2_perm@
Physics material=HfO2 Bandgap      Eg=5.9
Physics material=HfO2 Affinity     chi=2.05
set hfo2Mass  1.0e-5
set hfo2Gamma 1.0e5
# Setup conduction valleys
foreach valley [list GammaC L1 L2 L3 L4 X1 X2 X3] {
  Physics material=HfO2 ValleyModel=ConstantEllipsoid name=$valley \
          degeneracy=2 kl=[list 1 0 0] kt1=[list 0 1 0] kt2=[list 0 0 1] \
          ml=$hfo2Mass mt1=$hfo2Mass mt2=$hfo2Mass alpha=0.0 Eshift=0.0 useForEBulkDensity=0
}
# Setup valence valley
Physics material=HfO2 ValleyModel=6kpValley name=Gamma \
        degeneracy=1 gamma1=$hfo2Gamma gamma2=0.0 gamma3=0.0 delta=0.0 \
        a_v=0.0 b=0.0 d=0.0 useForHBulkDensity=0

### End 
######################################


#############################################################
# Specify device orientation based on WaferDir and ChannelDir
# wafer orientation (100)
#       channel direction <100> <110>
# wafer orientation (110)
#       channel direction <100> <110> <111> <112>
# wafer orientation (111)
#       channel direction <110> <112>
# wafer orientation (112)
#       channel direction <110> <111>

set xUCS @Xucs_Crystal@
set zUCS @Zucs_Crystal@
set XucsAxis   [split @Xucs_Crystal@ ":"]
set ZucsAxis   [split @Zucs_Crystal@ ":"]

if { [scalarProduct $XucsAxis $ZucsAxis] > 1.0e-10 } {
  puts "xDirection (XucsAxis)    = { $XucsAxis } "
  puts "zDirection (ZucsAxis)    = { $ZucsAxis } "
  return -code error "Xucs_Crystal and Zucs_Crystal should be orthogonal!!"
}
set YucsAxis [crossProduct $ZucsAxis $XucsAxis]

#if "_ChanDir_" == "z"
set channelAxis    $ZucsAxis
set sidewallAxis   $YucsAxis
set topsurfaceAxis $XucsAxis

puts "3D structure "
puts "xDirection = { $XucsAxis } "
puts "yDirection = { $YucsAxis } "
puts "zDirection = { $ZucsAxis } "
puts "channelDirection    = { $channelAxis } "
puts "sidewallDirection   = { $sidewallAxis } "
puts "topsurfaceDirection = { $topsurfaceAxis } "
puts "2D structure "
puts "xDirection = { $XucsAxis } "
puts "yDirection = { $YucsAxis } "

Physics xDirection=$XucsAxis yDirection=$YucsAxis

#elif "_ChanDir_" == "x"
set channelAxis    $XucsAxis
set sidewallAxis   $YucsAxis
set topsurfaceAxis $ZucsAxis

puts "3D structure "
puts "xDirection = { $XucsAxis } "
puts "yDirection = { $YucsAxis } "
puts "zDirection = { $ZucsAxis } "
puts "channelDirection    = { $channelAxis } "
puts "sidewallDirection   = { $sidewallAxis } "
puts "topsurfaceDirection = { $topsurfaceAxis } "
puts "2D structure "
puts "xDirection = { $ZucsAxis } "
puts "yDirection = { $YucsAxis } "

Physics xDirection=$ZucsAxis yDirection=$YucsAxis

#endif

##############################################################################
### Set up material and molefraction dependent model parameters and apply stress
#if "@prjorg@" == "hierarchical"
source @pwd@/Materials/MaterialPhysics_hier.tcl
#else
source @pwd@/Materials/MaterialPhysics.tcl
#endif

# strain due to uniaxial stress along channel
set strainTensorL [computeUniaxialStrain _MaterialCH_ _GeMoleCh_ @<Sl_GPa*1.0e9>@ $channelAxis]; 
# strain due to uniaxial stress across fin pitch
set strainTensorW [computeUniaxialStrain _MaterialCH_ _GeMoleCh_ @<Sw_GPa*1.0e9>@ $sidewallAxis]; 
# strain due to uniaxial stress perpendicular to wafer
set strainTensorH [computeUniaxialStrain _MaterialCH_ _GeMoleCh_ @<Sh_GPa*1.0e9>@ $topsurfaceAxis]; 

set strainTensorAdd [matrixAdd $strainTensorL $strainTensorW]
set strainTensor [matrixAdd $strainTensorAdd $strainTensorH]
puts "   ...strain tensor due to external stress =\n $strainTensor\n"

# apply strain to fin region
Physics region=Channel CrystalStrain strain=$strainTensor; 
# lattice spacing in [cm]
set a0 [computeRelaxedLatticeParameter _MaterialCH_ _GeMoleCh_]; 
setupMaterialParameters _MaterialCH_ Channel _GeMoleCh_ $strainTensor
##catch { setupMaterialParameters _MaterialCH_ Channel 0.0 [list [list 0 0 0] [list 0 0 0] [list 0 0 0]] }

#if "_TechType_" == "BulkFinFET"

# apply strain to channel stop region
Physics region=ChannelStop CrystalStrain strain=$strainTensor; 
# lattice spacing in [cm]
##set a0 [computeRelaxedLatticeParameter _MaterialSTOP_ _GeMoleSTOP_]; 
setupMaterialParameters _MaterialSTOP_ ChannelStop _GeMoleSTOP_ $strainTensor
##catch { setupMaterialParameters _MaterialSTOP_ ChannelStop 0.0 [list [list 0 0 0] [list 0 0 0] [list 0 0 0]] }

#endif

### End
##############################################################################


# Specify initial workfunction
Physics contact=gate workfunction=@WF_init@
#if "_TechType_" == "BulkFinFET"
Physics contact=substrate
#endif

# Set Poisson convergence tolerance
Math potentialUpdateTolerance=1.0e-4 \
     iterations=10 doOnFailure=0

# Initial, classical solve
Solve V(gate)=0.0 initial logFile=n@node@_initial_sband.plt

# Carrier dependent sign
#if [string compare @Type@ nMOS]==0
  set carrierSign 1
#else
  set carrierSign -1
#endif

# Create non-local line/area for Schrodinger
# Include oxide region for wavefunction penetration
#if "_TechType_" == "BulkFinFET"
Math nonlocal name=NL1 regions=[list Channel ChannelStop GateOxide GateHighK STI STI_mirrored] \
 #if "_ChanDir_" == "z"
     maxX=[expr  @<0.5*H*1e-3>@ + 0.010]; 
 #elif "_ChanDir_" == "x"
     minX=[expr -@<0.5*H*1e-3>@ - 0.010]; 
 #endif
#elif "_TechType_" == "FinFET"
Math nonlocal name=NL1 regions=[list Channel GateOxide GateHighK SOI] \
 #if "_ChanDir_" == "z"
     maxX=[expr  @<0.5*H*1e-3>@ + 0.010]; 
 #elif "_ChanDir_" == "x"
     minX=[expr -@<0.5*H*1e-3>@ - 0.010]; 
 #endif
#else
Math nonlocal name=NL1 regions=[list Channel GateOxide GateHighK]
#endif

####################################
### Specify Schrodinger solver
#if [string compare @Type@ nMOS]==0
  set Nsubbands 64
  set valleys [list GammaC L1 L2 L3 L4 X1 X2 X3]
  Physics nonlocal=NL1 eSchrodinger=Parabolic valleys=$valleys \
          Nk=16 Kmax=0.3 Nsubbands=$Nsubbands a0=$a0 correction=3
#else
 set Nsubbands 256
 set valleys [list Gamma]
 set kGrid [list 0.00E+00 6.0e-3 1.67E-02 3.33E-02 5.00E-02 6.67E-02 8.33E-02 0.1 \
                 0.116666667 0.133333333 0.15 0.2 0.25 0.3]
 set kmax [lindex $kGrid [expr [llength $kGrid] - 1]]
 Physics nonlocal=NL1 hSchrodinger=6kp valleys=$valleys \
         Nsubbands=$Nsubbands Nphi=48 kGrid=$kGrid iwSymmetry=AUTO a0=$a0 \
         useKdependentWF=1

#endif

### End
####################################


# Print physics
Physics print

# Create list of models to save
set modelsToSave [list DopingConcentration \
                       ConductionBandEnergy ValenceBandEnergy \
                       eQuasiFermiEnergy hQuasiFermiEnergy \
                       eDensity hDensity ] 

# At this point:
# - Material-dependent parameters have been specified
# - Schrodinger has been specified
# - Stress has been appplied

# Do Vg ramp.
for {set absVg 0.0} {$absVg<[expr @<abs(VDD)>@+0.01]} {set absVg [expr $absVg + @<abs(deltaVGATE)>@]} {

 # Set Vg
  if { [string compare @Type@ nMOS]==0 } {
    set Vg [format %.2f $absVg]
  } else {
    set Vg [format %.2f [expr -$absVg]]
  }
  
  # Do Solve
  Solve V(gate)=$Vg logFile=n@node@_sband.plt

  # save inversion carrier density, injection velocity, and transport effect mass
  set Ninv [getInversionCharge]
  set vinj [ComputeVinj]
  set mass [ComputeMass]
  puts -nonewline "Ninv=[format %.3e $Ninv] 1/cm "
  puts -nonewline "Vinj=[format %.3e $vinj] cm/sec " 
  puts            "TransMass=[format %.3f $mass] m0"
  AddToLogFile name=Ninv value=$Ninv
  AddToLogFile name=vinj value=$vinj
  AddToLogFile name=TransMass value=$mass

  # Save TDR file with structure and models
  Save tdrFile=n@node@_Vg=${Vg}V_sband.tdr models=$modelsToSave
}


