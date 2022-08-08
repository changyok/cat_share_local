#------------------------------------------------------------------------------------
# This template runs Garand simulation with the calibrated density-gradient model.
# This is tested using Garand version R-2020.09.
#------------------------------------------------------------------------------------

#setdep @node|DOEdisplay@

## X or Z
#define _ChanDir_     @Channel_UCS@

#if "_ChanDir_" == "z"
#define _reflectAxis_  y-
#elif "_ChanDir_" == "x"
#define _reflectAxis_  y-
#elif "_ChanDir_" == "y"
#define _reflectAxis_  z-
#else
puts "Channel direction should be \"x\" or \"z\" in UCS"
exit
#endif

#define _domain_ @nodedirpath|rect_mesh@/n@node|rect_mesh@_msh.tdr

# -------- Import the common file for DD and MC simulation ----------------
IMPORT pp@node@_gmc.garinp

# ------------------------------- SIMULATION TYPE ------------------------------
# For Ninv-Vg simulations slice the device
# Modify domain to only simulate a slice through the channel
SIMULATION  autoslice          = on
# Enforce slice around channel position                                   
SIMULATION  autoslice_position = 0.0

#------------------------------ SIMULATION DOMAIN ------------------------------
# Device structure file
STRUCTURE   IMPORT   filename  = _domain_  units = um
# Reflect domain in -'ve y-direction to get full fin
STRUCTURE   reflect  _reflectAxis_        = on
# Scaling factor for output current from DD
STRUCTURE	AreaFactor	= 1.0	

#------------------------------- BIAS CONDITIONS -------------------------------
# Gate Bias [V]
BIAS        gate               = 0.0
# Incriment applied to drain or gate in I-V curve [V]
BIAS        delta              = @deltaVGATE@
# Number of points in the I-V curve
BIAS        ivpoints           = @<round(1+abs(VDD/deltaVGATE))>@

#----------------------------------- OUTPUT ------------------------------------
# Write transfer file for MC simulation
OUTPUT	mc_transfer		= off


