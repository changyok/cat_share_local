#------------------------------------------------------------------------------------
# This template runs Garand drift-diffusion simulation of 3D device structure.
# The result is used as a initial solution of the next ensemble monte-carlo simularion 
# This is tested using Garand version R-2020.09.
#------------------------------------------------------------------------------------

#setdep @node|DOEdisplay@


#define _TechType_  @TechType@
#if "_TechType_" == "CFET"
#define _TechType_  GAA
#elif "_TechType_" == "VFET"
#define _TechType_  FinFET
#elif "_TechType_" == "SRAM"
#define _TechType_  GAA
#endif


#define _domain_ @nodedirpath|rect_mesh@/n@node|rect_mesh@_msh.tdr

# -------- Import the common file for DD and MC simulation ----------------
import pp@node@_gmc.garinp

#------------------------------ SIMULATION DOMAIN ------------------------------
# Device structure file
STRUCTURE	IMPORT  filename = _domain_ units = um	

# Scaling factor for output current from DD
STRUCTURE	AreaFactor	= 2.0	

#------------------------------- BIAS CONDITIONS -------------------------------
# Drain/Gate/Substrate Bias [V]
BIAS	drain			= @Vd@
BIAS	gate			= @Vg@
#if "_TechType_" == "BulkFinFET"
BIAS	substrate		= 0.0
#endif
# Incriment applied to drain or gate in I-V curve [V]
BIAS	delta			= 0.1
# Number of points in the I-V curve
BIAS	ivpoints		= 1

# ------------------------------ SIMULATION OUTPUT -----------------------------
# Write transfer file for MC simulation
OUTPUT	mc_transfer		= on


