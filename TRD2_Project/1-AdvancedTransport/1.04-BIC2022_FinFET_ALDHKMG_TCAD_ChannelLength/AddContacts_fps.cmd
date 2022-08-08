#############################################################
### This template adds contacts to FinFET structure.
### This is tetsed using version R-2020.09.
#############################################################

#setdep @node|sprocess@

## specifies the number of parallel threads for Sentaurus Process
math  numThreads=@Threads@

mater add name=SiGeSD            new.like=SiliconGermanium  alt.matername=SiliconGermanium
mater add name=SiSD              new.like=Silicon           alt.matername=Silicon
mater add name=SiGeStop          new.like=SiliconGermanium  alt.matername=SiliconGermanium
mater add name=SiStop            new.like=Silicon           alt.matername=Silicon
mater add name=LowK              new.like=Oxide
mater add name=SiOCN             new.like=Oxide
mater add name=InterfacialOxide  new.like=Oxide

#define  _ChMat_    SiliconGermanium
#define  _SdMat_    SiGeSD
#define  _StopMat_  SiGeStop

## X or Z
#define _ChanDir_     @Channel_UCS@
set ChanDir    @Channel_UCS@

#if "_ChanDir_" == "z"
#define _TopSurfDir_  x
set TopSurfDir x
#define _whereSubCnt_    bottom
#elif "_ChanDir_" == "x"
#define _TopSurfDir_  z
set TopSurfDir z
#define _whereSubCnt_    front
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


#define _isRounded_       1

## Generate Atomic Layer Deposition HKMG (High-K Metal Gate) structure 
## or selectivedepo HKMG structure.
#define _isSelectiveHKMG_ @SelectiveGate@
#if _isSelectiveHKMG_
#define _isALDHKMG_       0
#else
#define _isALDHKMG_       1
#endif

init tdr= @nodedirpath|sprocess@/n@node|sprocess@_fps.tdr

## define the boundary coordinates along the channel direction
set Z0 @<-0.5*(Lg+2*Tspacer+2*Thfo2 * _isALDHKMG_)*1e-3>@
set Z1 @< 0.5*(Lg+2*Tspacer+2*Thfo2 * _isALDHKMG_)*1e-3>@

## channel location
set L0 @<-0.5*Lg*1e-3>@
set L1 @< 0.5*Lg*1e-3>@

set Tstop     50.0e-3                ;# channel stop/well thickness
set X1stop  [expr (@<(0.5*H+Tiox+Thfo2)*1.0e-3>@+$Tstop)]


############################################################################
##### Specify contacts

contact clear
#if "_TechType_" == "BulkFinFET"
contact name= source  _ChMat_ adjacent.material=gas !cut.mesh sidewall \
        ${ChanDir}lo=[expr ($Z0 - 1.0e-4)]  ${ChanDir}hi=[expr ($Z0 + 1.0e-4)] \
        ${TopSurfDir}hi=@<0.5*H*1.0e-3-0.002>@
contact name= drain _ChMat_ adjacent.material=gas !cut.mesh sidewall \
        ${ChanDir}lo=[expr ($Z1 - 1.0e-4)]  ${ChanDir}hi=[expr ($Z1 + 1.0e-4)] \
        ${TopSurfDir}hi=@<0.5*H*1.0e-3-0.002>@

 #if "_TopSurfDir_" == "x"
contact name=substrate _whereSubCnt_ _ChMat_
 #else
contact name= substrate _ChMat_ adjacent.material=gas !cut.mesh sidewall \
        ${TopSurfDir}lo=[expr ($X1stop - 1.0e-4)]  ${TopSurfDir}hi=[expr ($X1stop + 1.0e-4)] 
 #endif

#else
contact name= source  _ChMat_ adjacent.material=gas !cut.mesh sidewall \
        ${ChanDir}lo=[expr ($Z0 - 1.0e-4)]  ${ChanDir}hi=[expr ($Z0 + 1.0e-4)]  
contact name= drain _ChMat_ adjacent.material=gas !cut.mesh sidewall \
        ${ChanDir}lo=[expr ($Z1 - 1.0e-4)]  ${ChanDir}hi=[expr ($Z1 + 1.0e-4)]   

#endif

contact name=gate point replace region=GateMetal  


############################################################################
##### Change materials
#if "_TechType_" == "BulkFinFET"
set rEgions [list Channel cDrain cSource ChannelStop]
#else
set rEgions [list Channel cDrain cSource]
#endif
foreach r $rEgions {
region name= $r _ChMat_ change.material !zero.data
}

############################################################################
##### Specify uniform stresses
##### Change materials
#if "_TechType_" == "BulkFinFET"
set rEgions [list Channel cDrain cSource ChannelStop GateOxide GateHighK SPd SPs STI]
#else
set rEgions [list Channel cDrain cSource GateOxide GateHighK SPd SPs]
#endif
foreach r $rEgions {
stressdata region=$r s${ChanDir}${ChanDir}i= @<Sl_GPa*1e10>@ syyi= @<Sw_GPa*1e10>@ \
                     s${TopSurfDir}${TopSurfDir}i= @<Sh_GPa*1e10>@
}

############################################################################
##### remove the dummy oxynitride material regions
set rList [region list]
foreach rname $rList {
 if { [string match "OxyN*" $rname] } {
  region name= $rname Gas   change.material
 }
}

### save TDR file and BND files for the next SNMESH step (tensor mesh generation)
struct tdr=n@node@                       !gas interfaces alt.maternames
struct tdr.bnd=n@node@                   !gas interfaces alt.maternames

exit




