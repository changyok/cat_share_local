#############################################################
### This template cuts 2D slice at the middle of the FinFET
### used for Sband simulation.
### This is tetsed using version R-2020.09.
#############################################################

#setdep @node|rect_mesh@

## X or Z
#define _ChanDir_     @Channel_UCS@

#if "_ChanDir_" == "z"
#define _normalVector_  (0 0 1)
#define _reflectAxis_   ymin
#elif "_ChanDir_" == "x"
#define _normalVector_  (1 0 0)
#define _reflectAxis_   ymin
#define _rotateAxis_    (0 1 0)
###define _rotateAxis_    Y
#define _rotateAngle_   90
#else
puts "Channel direction should be \"x\" or \"z\" in UCS"
exit
#endif

IOControls {
  EnableTools
  numThreads = 1
  inputFile = "@nodedirpath|rect_mesh@/n@node|rect_mesh@_msh.tdr"
  outputFile = "n@node@_x_msh.tdr"
  verbosity = 3
  useUCScoordinates
}

Tools {
  Slice {
## Cut plane normal to the channel direction (z-direction)
    normal = _normalVector_
## Cut the plane including the point
    location = (0.0 0.0 0.0)
  }
## Grand MC simulation structure is the half FinFET.
## Sband requires the full cross-section.
## Reflected at the minimum y point in the y-direction (fin width direction)
  Reflection {
    axis = _reflectAxis_
  }
#if 0
  Set Transformation {
    rotation {
      axis  = _rotateAxis_
      angle = _rotateAngle_
    }
  }
  Apply Transformation
#endif
}

