#############################################################
### This template converts sn-mesh structure to tensor mesh
### for Garand Monte-Carlo simulation.
### This is tetsed using version R-2020.09.
#############################################################

#setdep @node|AddContacts@


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

### define accurate mesh lines
#define _Xcut0_  @<-0.5*H*1e-3-1.0*(Tiox+Thfo2)*1e-3>@
#define _Xcut1_  @<-0.5*H*1e-3-1.0*Tiox*1e-3>@
#define _Xcut2_  @<-0.5*H*1e-3>@
#define _Xcut3_  @< 0.5*H*1e-3>@

#if "_TechType_" == "GAA"
#define _Xcut4_  @< 0.5*H*1e-3+1.0*Tiox*1e-3>@
#define _Xcut5_  @< 0.5*H*1e-3+1.0*(Tiox+Thfo2)*1e-3>@
#endif

#define _Ycut0_  0.0 
#define _Ycut1_  @<0.5*W*1e-3>@ 
#define _Ycut2_  @<(0.5*W+Tiox)*1e-3>@ 
#define _Ycut3_  @<(0.5*W+Tiox+Thfo2)*1e-3>@

#define _Zcut0_   0.0
#define _Zcut1_   @< 0.5*Lg*1e-3>@
#define _Zcut1m_  @<-0.5*Lg*1e-3>@
#define _Zcut2_   @< (0.5*Lg+Thfo2)*1e-3>@
#define _Zcut2m_  @<-(0.5*Lg+Thfo2)*1e-3>@

#############################################
### for mesh window
#define _Xfin0_ @<(-0.5*H-5.0)*1e-3>@
#define _Xfin1_ @<( 0.5*H+5.0)*1e-3>@
#define _Yfin0_ @<(-0.5*W-5.0)*1e-3>@ 
#define _Yfin1_ @<( 0.5*W+5.0)*1e-3>@
#define _Zfin0_ @<(-0.5*Lg-5.0)*1e-3>@
#define _Zfin1_ @<( 0.5*Lg+5.0)*1e-3>@

#define _Xfin10_ @<(-0.5*H-2.5)*1e-3>@
#define _Xfin11_ @<( 0.5*H+2.5)*1e-3>@
#define _Yfin10_ @<(-0.5*W-2.5)*1e-3>@ 
#define _Yfin11_ @<( 0.5*W+2.5)*1e-3>@
#define _Zfin10_ @<(-0.5*Lg-3.0)*1e-3>@
#define _Zfin11_ @<( 0.5*Lg+3.0)*1e-3>@


#define _Xactive00_ @<-0.50*H*1e-3>@
#define _Xactive01_ @< 0.50*H*1e-3>@
#define _Xactive10_ @<-0.40*H*1e-3>@ 
#define _Xactive11_ @< 0.40*H*1e-3>@
#define _Xactive20_ @<-0.30*H*1e-3>@ 
#define _Xactive21_ @< 0.30*H*1e-3>@

#define _Xactive30_ @<-0.5*H*1e-3+0.003>@ 
#define _Xactive31_ @< 0.6*H*1e-3>@

#define _Yactive00_ @<-0.50*W*1e-3>@ 
#define _Yactive01_ @< 0.50*W*1e-3>@
#define _Yactive10_ @<-0.40*W*1e-3>@ 
#define _Yactive11_ @< 0.40*W*1e-3>@
#define _Yactive20_ @<-0.30*W*1e-3>@ 
#define _Yactive21_ @< 0.30*W*1e-3>@

#define _Zactive00_ @<-0.50*Lg*1e-3-0.002>@
#define _Zactive01_ @< 0.50*Lg*1e-3+0.002>@ 

#define _Zactive10_ @<-0.50*Lg*1e-3-0.001>@
#define _Zactive11_ @< 0.50*Lg*1e-3+0.001>@ 
#define _Zactive20_ @<-0.50*Lg*1e-3+0.002>@
#define _Zactive21_ @< 0.50*Lg*1e-3-0.002>@
#define _Zactive30_ @<-0.50*Lg*1e-3-0.0004>@
#define _Zactive31_ @< 0.50*Lg*1e-3+0.0004>@ 
#define _Zactive40_ @<-0.50*Lg*1e-3+0.001>@
#define _Zactive41_ @< 0.50*Lg*1e-3-0.001>@ 
###
#############################################

### define the mesh size
#if "_TechType_" == "GAA"
 #if @<W > H>@
#define _dMesh0_  @<0.5*W*1e-3>@
#define _dMesh1_  @<0.1*W*1e-3>@
#define _dMesh2_  @<0.03*W*1e-3>@
 #else
#define _dMesh0_  @<0.5*H*1e-3>@
#define _dMesh1_  @<0.1*H*1e-3>@
#define _dMesh2_  @<0.03*H*1e-3>@
 #endif

#else
#define _dMesh0_  @<1.0*H*1e-3>@
#define _dMesh1_  @<0.1*H*1e-3>@
#define _dMesh2_  @<0.03*H*1e-3>@

#endif

# specify the names of input files describing the structure and 
# the name of the output file with the generated result
IOControls {
  inputFile = "@nodedirpath|AddContacts@/n@node|AddContacts@_bnd.tdr"
  # enables the tensor-product mesh generator
  EnableTensor
  # specifies the name of the output file
  outputFile = "n@node@_msh.tdr"
  # specifies whether Sentaurus Mesh creates a tensor mesh that is compatible with S-Device
  unstructuredTensorMesh = true
  numThreads = @Threads@
}

Definitions {
  # external simulation results given on a mesh
  # can be used to define profiles in the device
  SubMesh "SubMesh" {
    # specifies the name of a file with an external mesh
    Geofile = "@nodedirpath|AddContacts@/n@node|AddContacts@_fps.tdr"		
  }
}

# place submesh
Placements {
  SubMesh "SubMesh" {
    Reference = "SubMesh"
  }
}

# controls the tensor-product mesh generator
Tensor {
  Mesh {
    # specifies the maximum cell size allowed in a region
    maxCellSize= _dMesh0_
    ##maxBndCellSize interface material "SiliconGermanium" "Exterior" @<(0.5*Tiox)*1e-3>@
    ##maxBndCellSize interface material "InterfacialOxide" "Exterior" @<(0.25*Tiox)*1e-3>@ 
    ##maxBndCellSize interface material "HfO2"             "Exterior" @<(0.25*Thfo2)*1e-3>@  

### mesh refinement commands
!(
source @pwd@/MESH_LIB.tcl

set mwindow [list _Xfin0_ _Xfin1_  _Yfin0_ _Yfin1_  _Zfin0_ _Zfin1_]
MeshWindow "fin" $mwindow _dMesh1_ "xyz" _ChanDir_
set mwindow [list _Xfin10_ _Xfin11_  _Yfin10_ _Yfin11_  _Zfin10_ _Zfin11_]
MeshWindow "fin1" $mwindow _dMesh2_ "xyz" _ChanDir_

#if "_TechType_" == "GAA"
 #if @<W >= H>@

set mwindow [list _Xactive00_ _Xactive01_ _Yactive00_ _Yactive20_ _Zactive00_ _Zactive01_]
MeshWindow "finleft"   $mwindow 0.3e-3 "y" _ChanDir_
set mwindow [list _Xactive00_ _Xactive01_ _Yactive00_ _Yactive10_ _Zactive00_ _Zactive01_]
MeshWindow "finleft1"  $mwindow 0.2e-3 "y" _ChanDir_
set mwindow [list _Xactive00_ _Xactive01_ _Yactive21_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "finright"  $mwindow 0.3e-3 "y" _ChanDir_
set mwindow [list _Xactive00_ _Xactive01_ _Yactive11_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "finright1" $mwindow 0.2e-3 "y" _ChanDir_

 #endif

 #if @<W <= H>@

set mwindow [list _Xactive00_ _Xactive20_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "fintop"   $mwindow 0.3e-3 "x" _ChanDir_
set mwindow [list _Xactive00_ _Xactive10_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "fintop1"  $mwindow 0.2e-3 "x" _ChanDir_
set mwindow [list _Xactive21_ _Xactive01_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "finbot"  $mwindow 0.3e-3 "x" _ChanDir_
set mwindow [list _Xactive11_ _Xactive01_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "finbot1" $mwindow 0.2e-3 "x" _ChanDir_

 #endif

 #if @<W > H>@

set mwindow [list _Xactive00_ _Xactive01_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "finH"     $mwindow 0.3e-3 "x" _ChanDir_
set mwindow [list _Xactive00_ _Xactive10_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "fintop1"  $mwindow 0.2e-3 "x" _ChanDir_
set mwindow [list _Xactive11_ _Xactive01_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "finbot1"  $mwindow 0.2e-3 "x" _ChanDir_

 #elif @<W < H>@

set mwindow [list _Xactive00_ _Xactive01_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "finW"      $mwindow 0.3e-3 "y" _ChanDir_
set mwindow [list _Xactive00_ _Xactive01_ _Yactive00_ _Yactive10_ _Zactive00_ _Zactive01_]
MeshWindow "finleft1"  $mwindow 0.2e-3 "y" _ChanDir_
set mwindow [list _Xactive00_ _Xactive01_ _Yactive11_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "finright1" $mwindow 0.2e-3 "y" _ChanDir_

 #endif

#else

set mwindow [list _Xactive00_ _Xactive10_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "fintop"   $mwindow 0.3e-3 "x" _ChanDir_
set mwindow [list _Xactive00_ _Xactive30_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "fintop1"  $mwindow 0.202e-3 "x" _ChanDir_
set mwindow [list _Xactive11_ _Xactive31_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "finbot"   $mwindow 0.3e-3 "x" _ChanDir_
set mwindow [list _Xactive00_ _Xactive01_ _Yactive00_ _Yactive01_ _Zactive00_ _Zactive01_]
MeshWindow "finW"     $mwindow 0.325e-3 "y" _ChanDir_

#endif

set mwindow [list _Xactive00_ _Xactive01_ _Yactive00_ _Yactive01_ _Zactive10_ _Zactive20_]
MeshWindow "finL0"   $mwindow 0.3e-3 "z" _ChanDir_
set mwindow [list _Xactive00_ _Xactive01_ _Yactive00_ _Yactive01_ _Zactive21_ _Zactive11_]
MeshWindow "finL1"   $mwindow 0.3e-3 "z" _ChanDir_
set mwindow [list _Xactive00_ _Xactive01_ _Yactive00_ _Yactive01_ _Zactive30_ _Zactive40_]
MeshWindow "finL00"  $mwindow 0.1e-3 "z" _ChanDir_
set mwindow [list _Xactive00_ _Xactive01_ _Yactive00_ _Yactive01_ _Zactive41_ _Zactive31_]
MeshWindow "finL10"  $mwindow 0.1e-3 "z" _ChanDir_
)!

### specify the mesh lines at the exact location
#if "_ChanDir_" == "z"
 #if "_TechType_" == "GAA"
    xCuts = ( _Xcut0_ _Xcut1_ _Xcut2_ _Xcut3_ _Xcut4_ _Xcut5_ )
 #else
    xCuts = ( _Xcut0_ _Xcut1_ _Xcut2_ _Xcut3_ )
 #endif
    yCuts = ( _Ycut0_ _Ycut1_ _Ycut2_ _Ycut3_ )
    zCuts = ( _Zcut2m_ _Zcut1m_ _Zcut0_ _Zcut1_ _Zcut2_ )

#elif "_ChanDir_" == "x"
 #if "_TechType_" == "GAA"
    zCuts = ( _Xcut0_ _Xcut1_ _Xcut2_ _Xcut3_ _Xcut4_ _Xcut5_ )
 #else
    zCuts = ( _Xcut0_ _Xcut1_ _Xcut2_ _Xcut3_ )
 #endif
    yCuts = ( _Ycut0_ _Ycut1_ _Ycut2_ _Ycut3_ )
    xCuts = ( _Zcut2m_ _Zcut1m_ _Zcut0_ _Zcut1_ _Zcut2_ )
#endif

    Doping
  }

}



