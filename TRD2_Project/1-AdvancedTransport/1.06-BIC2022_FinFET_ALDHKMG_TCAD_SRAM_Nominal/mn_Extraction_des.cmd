########################################################################
### This template runs Sdevice simulation to obtain the effective mass.
### This is tetsed using version R-2020.09.
########################################################################

#setdep @node|DG_profiles_Check@


## X or Z
#define _ChanDir_     @Channel_UCS@

#define _TechType_  @TechType@
#if "_TechType_" == "CFET"
#define _TechType_  GAA
#elif "_TechType_" == "VFET"
#define _TechType_  FinFET
#elif "_TechType_" == "SRAM"
#define _TechType_  GAA
#endif

/* Define stress components  */
#define _StressTensor_  @<Sh_GPa*1e9>@, @<Sw_GPa*1e9>@, @<Sl_GPa*1e9>@, 0.0, 0.0, 0.0
#define _AnisoAxes_ (1,0,0) (0,1,0)

#if [string compare @Type@ nMOS] == 0
#define _SIGN_ 1.0
#define _QP_    eQuantumPotential(density Formula=1)
#define _ANI_ Aniso(eQuantumPotential( AnisoAxes( SimulationSystem)={ _AnisoAxes_ } ))
#define _POTENTIAL_EQNS_ Poisson eQuantumPotential 
 
#elseif [string compare @Type@ pMOS] == 0
#define _SIGN_ -1.0
#define _QP_    hQuantumPotential(density Formula=1)
#define _ANI_ Aniso(hQuantumPotential( AnisoAxes( SimulationSystem)={ _AnisoAxes_ } ))
#define _POTENTIAL_EQNS_ Poisson hQuantumPotential

#else
error "Type must be either NMOS or PMOS"
#endif

#define _Vg0_ 0.0

#define _WF_ @WF_opt@


## set the input/output/parameter files
File {
  * input files:
  Grid=   "@nodedirpath|xslice@/n@node|xslice@_x_msh.tdr"

  * output files:
  Plot=   "n@node@_des.tdr"
  Current="@plot@"
  Output= "@log@"
  Parameter=   "@parameter@"
  PMIPath="."
}

## set the thermal contact
Thermode {
  { Name="gate"       Temperature=@<Temperature+273>@ }
#if "_TechType_" == "BulkFinFET"
  { Name="substrate"  Temperature=@<Temperature+273>@ }
#endif
}

## set the electrode contact
Electrode {
  { Name="gate"       Voltage= _Vg0_ Workfunction=_WF_}
#if "_TechType_" == "BulkFinFET"
  { Name="substrate"  Voltage= 0.0 }
#endif
}

## set the physics model used in the simulation
Physics {
  Temperature=@<Temperature+273>@

  AreaFactor=@<1.0>@

  EffectiveIntrinsicDensity( NoBandGapNarrowing )
  Mobility (
    BalMob( Lch = @Lg@ )
    DopingDependence
    HighFieldSaturation
  )

  Piezo(
    Stress=(_StressTensor_)
    Model(
          DeformationPotential(ekp hkp minimum)
          *DOS(eMass hMass)
 #if "@Type@" == "nMOS"
          Mobility( efactor(kanda sfactor=SBmob(Type=0) ApplyToMobilityComponents )
                   eSaturationFactor = 0.20
          )
 #else
          Mobility( hfactor(kanda sfactor=SBmob(Type=1) ApplyToMobilityComponents )
                   hSaturationFactor = 0.27
          )
 #endif
    )
  )
}

## solve the density-gradient equation in 'Channel' and 'ChannelStop' regions
Physics(Region="Channel") { 
 _QP_ 
 _ANI_ 

#if "_TechType_" != "BulkFinFET"
 eQuasiFermi = 0
 hQuasiFermi = 0
#endif
}

#if "_TechType_" == "BulkFinFET"
Physics(Region="ChannelStop") { 
 _QP_ 
 _ANI_ 
}
#endif

## specify the variables which will be saved in the output TDR.
Plot{
  eDensity hDensity 
  Potential Electricfield/Vector Doping SpaceCharge
  eMobility hMobility eVelocity/Vector hVelocity/Vector
  DonorConcentration Acceptorconcentration
  BandGap Affinity BandGapNarrowing EffectiveBandGap EffectiveIntrinsicDensity
  ConductionBand ValenceBand eQuasiFermi hQuasiFermi 
  eGradQuasiFermi/Vector hGradQuasiFermi/Vector eQuantumPotential hQuantumPotential

  eRelativeEffectiveMass hRelativeEffectiveMass
  eEffectiveStateDensity hEffectiveStateDensity

  StressXX StressYY StressZZ StressXY StressYZ StressXZ
  eMobilityStressFactorXX eMobilityStressFactorYY eMobilityStressFactorZZ
  eMobilityStressFactorYZ eMobilityStressFactorXZ eMobilityStressFactorXY
  hMobilityStressFactorXX hMobilityStressFactorYY hMobilityStressFactorZZ
  hMobilityStressFactorYZ hMobilityStressFactorXZ hMobilityStressFactorXY
  eTensorMobilityFactorXX eTensorMobilityFactorYY eTensorMobilityFactorZZ
  hTensorMobilityFactorXX hTensorMobilityFactorYY hTensorMobilityFactorZZ

  DielectricConstant xMoleFraction
  LayerThickness NearestInterfaceOrientation
}

## numerical set-up
Math {
  CoordinateSystem { UCS }
  -CheckUndefinedModels
  AutoOrientationSmoothingDistance = -1
  GeometricDistances

  ThinLayer( Mirror = ( None None None ) )

  Extrapolate
  Derivative
  Method=ILS
  RhsMin = 1e-12
  Iterations=20

  wallclock
  ExitOnFailure

  Number_of_Threads = @Threads@ 
}

## solve sdevice
Solve{
#-initial solution:
	NewCurrentFile="init_" 
	Coupled(Iterations= 100 LineSearchDamping= 1e-4){ _POTENTIAL_EQNS_ }
}


