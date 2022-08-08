#------------------------------------------------------------------------------------
# This template runs Garand ensemble monte-carlo simulation of 3D device structure.
# This is tested using Garand version R-2020.09.
#------------------------------------------------------------------------------------

#setdep @node|Garand_DD@


#define _TechType_  @TechType@
#if "_TechType_" == "CFET"
#define _TechType_  GAA
#elif "_TechType_" == "VFET"
#define _TechType_  FinFET
#elif "_TechType_" == "SRAM"
#define _TechType_  GAA
#endif


#define _mct_ @nodedirpath|Garand_DD@/n@node|Garand_DD@_1.mct
#define _domain_ @nodedirpath|rect_mesh@/n@node|rect_mesh@_msh.tdr

/* Below this bias relax convergence criteria [V] */
#define _vcontrol_  0.3

#if [expr abs(@Vg@) == abs(_vcontrol_)] || [expr abs(@Vg@) == abs(@VDD@)]
/* Enable output of TDR */
#define _viz_ on  

#else
/* Disable output of TDR */
#define _viz_ off 

#endif
#define _viz_ off 

#if [expr @<abs(Vg)>@ <= _vcontrol_]
/* If the gate bias is below the value specified by _vcontrol_ relax convergence criteria */
#define _tol_        10.0
#define _numSteps_   120000
#else
/* If the gate bias is above the value specified by _vcontrol_ impose a standard convergence criteria */
#define _tol_        1.0
#define _numSteps_   150000
#endif
#define _tol_        1.0
#define _numSteps_   300000

# -------- Import the common file for DD and MC simulation ----------------
import pp@node@_gmc.garinp

#------------------------------ SIMULATION DOMAIN ------------------------------
# Device structure file
STRUCTURE	IMPORT  filename = _domain_ units = um	
# Path to Monte Carlo transfer file
STRUCTURE	MCT_FILE	= _mct_
# Scaling factor for output current from DD
STRUCTURE	AreaFactor	= 2.0	

#------------------------------- BIAS CONDITIONS -------------------------------
# Drain/Gate/Substrate Bias [V]
BIAS	drain		= @Vd@
BIAS	gate		= @Vg@
#if "_TechType_" == "BulkFinFET"
BIAS	substrate		= 0.0
#endif
# Incriment applied to drain or gate in I-V curve [V]
BIAS	delta		= 0.1
# Number of points in the I-V curve
BIAS	ivpoints	= 1

# ------------------------------ SIMULATION OUTPUT -----------------------------
# Write transfer file for MC simulation
OUTPUT	mc_transfer		= on

# ------------------------ MONTE CARLO OUTPUT PARAMETERS -----------------------
# Write MC simulation resulst to TDR file for vizualisation
OUTPUT	MC_results				= _viz_   
# Write time-averaged carrier energy/velocity/current density throughout domain
OUTPUT	carrier_properties			= _viz_
# separate statistics gathering and output over ensembles of particles
# identified by band. (valley occupation, carrier energy, carrier velocity,
# and the current density vector)
OUTPUT	separate_bands				= _viz_
# separate statistics gathering and output over the ensemble of particles
# moving from source to drain and the ensemble from drain to source
OUTPUT	ballisticity				= _viz_
# the calculated scattering rates for the selected material mechanisms
OUTPUT	scattering_rates			= _viz_
# statistics gathered at each time step to write the time evolution of
# ensemble average carrier properties during the simulation
OUTPUT	time_evolution				= _viz_
# the steady-state distribution of the carrier energy and wavevector
OUTPUT	E_distribution				= _viz_
OUTPUT	k_distribution				= _viz_
# write the average velocity in cross-sections across the device, 
# weighted by the carrier density
OUTPUT	weighted_velocity			= _viz_
# plot E(k) dispersion
OUTPUT	band_dispersions			= _viz_


# ---------------------- MONTE CARLO SIMULATION PARAMETERS ---------------------
# Ensemble simulation
SIMULATION	ensemble			= on	

#if "@Type@" == "nMOS"
# Simulate electron transport
SIMULATION	electrons			= on
# Number of particles to use for ensemble simulation
SIMULATION	num_elec			= 200000

#elif "@Type@" == "pMOS"		
# Simulate hole transport
SIMULATION	holes			= on
# Number of particles to use for ensemble simulation
SIMULATION	num_hole			= 200000

#endif

# Self-consistent simulation
SIMULATION	self_consistent			= on		

# Apply position dependent parameters for alloy scattering
SIMULATION	mc_pos_dep_scat 		= on	


# Use large number of particles to sample charge
SIMULATION	superparticles  		= on	
# Field-Adjusting-Time-Step	
SIMULATION	DT			= 5.d-17	

# Number of time steps in simulation/in transient/
# between intermittend output/between stats/between non-linear updates	
##SIMULATION	num_steps			= 120000
SIMULATION	num_steps			= _numSteps_
SIMULATION	num_trans			= 30000	
SIMULATION	num_inter			= 5000	
SIMULATION	num_stats			= 200	
SIMULATION	num_nlin			= 10000	

# Tolerance for convergence [A]/convergence [%]
SIMULATION	abstol				= 1.d-10	
SIMULATION	tolerance			= _tol_		



