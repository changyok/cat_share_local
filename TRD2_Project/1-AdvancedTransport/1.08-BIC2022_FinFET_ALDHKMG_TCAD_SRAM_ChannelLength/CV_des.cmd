#################################################################################
### This template runs Sdevice simulation to obtain C(gate,gate)-V(gate) curve.
### This is tetsed using version R-2020.09.
#################################################################################

#setdep @node|SDparam@


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
#if "_ChanDir_" == "z" 
#define _StressTensor_  @<Sh_GPa*1e9>@, @<Sw_GPa*1e9>@, @<Sl_GPa*1e9>@, 0.0, 0.0, 0.0
#define _AnisoAxes_ (1,0,0) (0,1,0)

## Define the quantum potential domain
#define _X0_      @<-0.5e-3*H>@
#define _X1_      @< 1.0e-3*(0.5*H+1.0)>@
#define _Y0_      @<-0.5e-3*W>@
#define _Y1_      @< 0.5e-3*W>@
#define _Z0_      @<-1.0e-3*(0.5*Lg+Tiox+Thfo2+Tspacer+1.0)>@
#define _Z1_      @< 1.0e-3*(0.5*Lg+Tiox+Thfo2+Tspacer+1.0)>@

#elif "_ChanDir_" == "x" 
#define _StressTensor_  @<Sl_GPa*1e9>@, @<Sw_GPa*1e9>@, @<Sh_GPa*1e9>@, 0.0, 0.0, 0.0
#define _AnisoAxes_ (0,0,1) (0,1,0)

## Define the quantum potential domain
#define _Z0_      @<-0.5e-3*H>@
#define _Z1_      @< 1.0e-3*(0.5*H+1.0)>@
#define _Y0_      @<-0.5e-3*W>@
#define _Y1_      @< 0.5e-3*W>@
#define _X0_      @<-1.0e-3*(0.5*Lg+Tiox+Thfo2+Tspacer+1.0)>@
#define _X1_      @< 1.0e-3*(0.5*Lg+Tiox+Thfo2+Tspacer+1.0)>@

#elif "_ChanDir_" == "y"  
#define _StressTensor_  @<Sh_GPa*1e9>@, @<Sl_GPa*1e9>@, @<Sw_GPa*1e9>@, 0.0, 0.0, 0.0
#define _AnisoAxes_ (1,0,0) (0,0,1)

## Define the quantum potential domain
#define _X0_      @<-0.5e-3*H>@
#define _X1_      @< 1.0e-3*(0.5*H+1.0)>@
#define _Z0_      @<-0.5e-3*W>@
#define _Z1_      @< 0.5e-3*W>@
#define _Y0_      @<-1.0e-3*(0.5*Lg+Tiox+Thfo2+Tspacer+1.0)>@
#define _Y1_      @< 1.0e-3*(0.5*Lg+Tiox+Thfo2+Tspacer+1.0)>@

#endif




#if [string compare @Type@ nMOS] == 0
#define _SIGN_ 1.0
#define _Vg0_ @<-1.5*VDD>@
#define _Vg_  @< 1.5*VDD>@

#elseif [string compare @Type@ pMOS] == 0
#define _SIGN_ -1.0
#define _Vg0_ @< 1.5*VDD>@
#define _Vg_  @<-1.5*VDD>@

#else
error "Type must be either NMOS or PMOS"
#endif

#define _QPBoxe_ eQPBox
#define _QPBoxh_ hQPBox
#define _QPe_    eQuantumPotential(density Formula=1)
#define _ANIe_   Aniso(eQuantumPotential( AnisoAxes( SimulationSystem)={ _AnisoAxes_ } ))
#define _QPh_    hQuantumPotential(density Formula=1)
#define _ANIh_   Aniso(hQuantumPotential( AnisoAxes( SimulationSystem)={ _AnisoAxes_ } ))
#define _POTENTIAL_EQNS_ Poisson eQuantumPotential hQuantumPotential
#define _COUPLED_EQNS_   Poisson eQuantumPotential hQuantumPotential Electron Hole

#define _ANI_   Aniso(eQuantumPotential( AnisoAxes( SimulationSystem)={ _AnisoAxes_ } ) hQuantumPotential( AnisoAxes( SimulationSystem)={ _AnisoAxes_ } ))


#define _WF_ @WF_opt@

*----------------------------------------------------------------------
Device MOS {
*----------------------------------------------------------------------
## set the input/output/parameter files
File {
  * input files:
  Grid=   "@nodedirpath|rect_mesh@/n@node|rect_mesh@_msh.tdr"

  * output files:
  Plot=   "n@node@_des.tdr"
  Current="@plot@"
*  Output= "@log@"
  Parameter=   "@parameter@"
*  PMIPath="."
}

## set the thermal contact
Thermode {
  { Name="gate"       Temperature=@<Temperature+273>@ }
  { Name="drain"      Temperature=@<Temperature+273>@ }
  { Name="source"     Temperature=@<Temperature+273>@ }
#if "_TechType_" == "BulkFinFET"
  { Name="substrate"  Temperature=@<Temperature+273>@ }
#endif
}

## set the electrode contact
Electrode {
  { Name="gate"       Voltage= 0.0 Workfunction=_WF_}
  { Name="drain"      Voltage= 0.0 }
  { Name="source"     Voltage= 0.0 }
#if "_TechType_" == "BulkFinFET"
  { Name="substrate"  Voltage= 0.0 }
#endif
}

## set the physics model used in the simulation
Physics {
  Temperature=@<Temperature+273>@

  ## simulation structure is half FinFET and the capacitance needs to be doubled.
  AreaFactor=@<2.0>@

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

## solve the density-gradient equation in 'Channel', 'ChannelStop', 'cDrain', and 'cSource' regions
Physics(Region="Channel") { 
 _QPe_ 
 _QPh_ 
 _ANI_ 
}
Physics(Region="cDrain") { 
 _QPe_ 
 _QPh_ 
 _ANI_ 
}
Physics(Region="cSource") { 
 _QPe_ 
 _QPh_ 
 _ANI_ 
}

#if "_TechType_" == "BulkFinFET"
Physics(Region="ChannelStop") { 
 _QPe_ 
 _QPh_ 
 _ANI_ 
}
#endif

*----------------------------------------------------------------------
} * End of Device
*----------------------------------------------------------------------

File {
  Output= "@log@"
  ACExtract = "@pwd@/@acplot@"
}

## specify the variables which will be saved in the output TDR.
Plot {
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
  ExtendedPrecision

  CoordinateSystem { UCS }
  -CheckUndefinedModels
  AutoOrientationSmoothingDistance = -1
  GeometricDistances

  ThinLayer( Mirror = ( None Min None ) )

  Extrapolate
  Derivative
  Method=ILS(Set=5)
  RhsMin = 1e-12
  Iterations=20

  wallclock
  ExitOnFailure

  Number_of_Threads = @Threads@ 

  _QPBoxe_({MinX=_X0_ MaxX=_X1_ MinY=_Y0_ MaxY=_Y1_ MinZ=_Z0_ MaxZ=_Z1_ Attenuation_Length=1e-3})
  _QPBoxh_({MinX=_X0_ MaxX=_X1_ MinY=_Y0_ MaxY=_Y1_ MinZ=_Z0_ MaxZ=_Z1_ Attenuation_Length=1e-3})

  ACMethod=Blocked
  ACSubMethod=ILS(Set=5)
}

System { 
#if "_TechType_" == "BulkFinFET"
  MOS mos (drain=d source=s gate=g substrate=b) 
#else
  MOS mos (drain=d source=s gate=g)
#endif
  
  Vsource_pset vd ( d 0 ){ dc = 0 } 
  Vsource_pset vs ( s 0 ){ dc = 0 } 
  Vsource_pset vg ( g 0 ){ dc = 0 } 
#if "_TechType_" == "BulkFinFET"
  Vsource_pset vb ( b 0 ){ dc = 0 }
#endif
} 


Solve {
#- Creating initial guess:
   Coupled(Iterations= 100 LineSearchDamping= 1e-4){ Poisson }
   Coupled(Iterations= 100 LineSearchDamping= 1e-4){ _POTENTIAL_EQNS_ }

   Quasistationary( 
      InitialStep=1e-3 Increment=1.35 
      MinStep=1e-5 MaxStep=0.2
      Goal { Parameter=vg.dc Voltage= _Vg0_ } 
   ){ Coupled { _POTENTIAL_EQNS_ } }
   Coupled(Iterations= 100){ _COUPLED_EQNS_ }
   Coupled { _COUPLED_EQNS_ Contact Circuit }

#- Vg sweep for Vd=Vs=0.0
   NewCurrentFile="CggVg_@Type@_" 
   Quasistationary( 
      DoZero 
      InitialStep=1e-3 Increment=1.35 
      MinStep=1e-5 MaxStep=0.1
      Goal { Parameter=vg.dc Voltage= _Vg_ } 
   ){ ACCoupled ( 
       StartFrequency=1e6 EndFrequency=1e6 NumberOfPoints=1 Decade 
#if "_TechType_" == "BulkFinFET"
       Node(d s g b) Exclude(vd vs vg vb) 
#else
       Node(d s g) Exclude(vd vs vg) 
#endif
       ACCompute (Time = (Range = (0 1)  Intervals = 14)) 
      ){ _COUPLED_EQNS_ } 
   }

}


