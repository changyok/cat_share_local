import numpy as np
# ----------- PARAMETRISATION FROM GLOBAL AND SPLIT OPTIONS, OR DEFAULTS -----------
# Device physical parameters
tfin              = @tfin@					# Physical fin thickness [m]
hfin              = @hfin@					# Physical fin height [m]
lgate		  = @lgate@
dtype             = "@Type@"

# other parameters
wf0               = @workfn@					# workfunction
tnom		  = @tnom@
tspacer		  = @tspacer@
eot		  = @eot@
nsd		  = @nsd@
avgStrains        = "@avgStrains@".split()

# Bias parameters
vdd_nom           = @Vdd_nom@					# Supply Voltage [V]
vdd_lin           = @Vdd_lin@					# Linear drain bias [V]
idvd_hvg          = @Vdd_nom@
vg_max           = @Vdd_nom@	

# Simulation parameters
mystic_verbose    = True

# terminal mapping
drain_con 	= "@drain_con@"
gate_con 	= "@gate_con@"
source_con	= "@source_con@"
bulk_con	= "@bulk_con@"

modstr		= "mosmod."
# ---------------------------- MYSTIC EXECUTION SCRIPT -----------------------------

Simulator.SetAdditionalSpiceArguments(['-C'])

# Use mean percentage error over the range of data.
ErrorMethod = "rmsd"
Optimiser.SetOptimisationParameter("jac", True)
eps=1e-5
Optimiser.SetOptimisationParameter("eps1",eps)
Optimiser.SetOptimisationParameter("eps2",eps)
Optimiser.SetOptimisationParameter("eps3",eps)
Optimiser.SetOptimisationParameter("eps4",eps)
Optimiser.SetOptimisationParameter("eps5",eps)
Optimiser.SetOptimisationParameter("eps6",eps)
Optimiser.SetOptimisationParameter("jacobian_eps",1e-3)
Optimiser.SetOptimisationParameter("kwargs",{"eps":1e-3,"step_type":"abs","step_method":"cd"})

# Load the data/model from the previous stage
Model = mdb.GetFitModel()
# ------------------------------------------------------------------- #

for st in avgStrains:
	s = float(st)
	print(f"stress = {s}")
	IdVg   = mdb.Load(dvar=f'i{drain_con}', ivar=f'v{gate_con}',  dtype=dtype, instances={"l":lgate, "avgStrain":float(s)}, tfin=tfin, temperature=tnom)
	idvg_error = ExtractionUtils.PrintErrors("IdVg_error", IdVg, Simulator, Model, ErrorMethod)
	IdVg.WritePLTFile(f'@pwd@/@nodedir@/n@node@-idvg_stress_{s}', bias_info=True)


