from libfromage.data import Data
Data.set_options(error_method="log_rel")

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
tlow		  = @lowT@
thigh		  = @highT@
tspacer		  = @tspacer@
eot		  = @eot@
nsd		  = @nsd@
avgStrainNom      = @avgStrainNom@

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

IsVg     = mdb.Load(dvar=f"i{source_con}", ivar=f"v{gate_con}", dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin)
IdVg_nom_temp	 = mdb.Load(dvar=f"i{drain_con}", ivar=f"v{gate_con}", dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom)
IdVg_low_temp	 = mdb.Load(dvar=f"i{drain_con}", ivar=f"v{gate_con}", dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tlow)
IdVg_high_temp	 = mdb.Load(dvar=f"i{drain_con}", ivar=f"v{gate_con}", dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=thigh)

# disable temp dep
# mobility
Model.SetModelParameter(f"{modstr}UA1", 0)
Model.SetModelParameter(f"{modstr}UC1", 0)
Model.SetModelParameter(f"{modstr}UCSTE", 0)
# saturation
Model.SetModelParameter(f"{modstr}UTL", 0)
Model.SetModelParameter(f"{modstr}AT", 0)
Model.SetModelParameter(f"{modstr}PTWGT", 0)
Model.SetModelParameter(f"{modstr}PRT", 0)
Model.SetModelParameter(f"{modstr}IIT", 0)

isvg_error = ExtractionUtils.PrintErrors("IsVg_error", IsVg, Simulator, Model, ErrorMethod)
IsVg.WritePLTFile('@pwd@/@nodedir@/n@node@_temp', bias_info=False)


# Apply fiters
#if "@Type@" == "nMOS"
IsVg		= IsVg.FilterData(		'gt',   1e-13,		dtype="dvar")
vt_gm_val = 0.4
IsVgld		= IsVg.FilterData(		'eq', 	vdd_lin,	dtype=f"bias.{drain_con}")
IsVghd		= IsVg.FilterData(		'eq', 	vdd_nom,	dtype=f"bias.{drain_con}")
IsVgld_BelowVt 	= IsVgld.FilterData(		'le', 	vt_gm_val-0.1,	dtype="ivar")
IsVgld_AboveVt 	= IsVgld.FilterData(		'ge', 	vt_gm_val,	dtype="ivar")
IsVghd_BelowVt 	= IsVghd.FilterData(		'le', 	vt_gm_val-0.1,	dtype="ivar")
IsVghd_AboveVt 	= IsVghd.FilterData(		'ge', 	vt_gm_val,	dtype="ivar")
#else
IsVg		= IsVg.FilterData(		'lt',   -1e-13,		dtype="dvar")
vt_gm_val = -0.4
IsVgld		= IsVg.FilterData(		'eq', 	vdd_lin,	dtype=f"bias.{drain_con}")
IsVghd		= IsVg.FilterData(		'eq', 	vdd_nom,	dtype=f"bias.{drain_con}")
IsVgld_BelowVt 	= IsVgld.FilterData(		'ge', 	vt_gm_val+0.1,	dtype="ivar")
IsVgld_AboveVt 	= IsVgld.FilterData(		'le', 	vt_gm_val,	dtype="ivar")
IsVghd_BelowVt 	= IsVghd.FilterData(		'ge', 	vt_gm_val+0.1,	dtype="ivar")
IsVghd_AboveVt 	= IsVghd.FilterData(		'le', 	vt_gm_val,	dtype="ivar")
#endif


KT1     = OptParam(f'{modstr}KT1',	0,		-0.5,		0.5,		0.01)
TSS     = OptParam(f'{modstr}TSS',	0,		-0.1,		0.1,		1e-3)
UTE     = OptParam(f'{modstr}UTE',	0,		-2,		2,		0.1)
AT      = OptParam(f'{modstr}AT',	0,		-0.1,		0.1,		1e-3)


for x in range(3): ExtractionUtils.DoStage("LD_step1", Model, Simulator, [KT1, TSS], Optimiser, [IsVgld_BelowVt],verbose=mystic_verbose)
ExtractionUtils.DoStage("LD_step1", Model, Simulator, [UTE], Optimiser, [IsVgld_AboveVt],verbose=mystic_verbose)
ExtractionUtils.DoStage("LD_step1", Model, Simulator, [AT], Optimiser, [IsVghd_AboveVt],verbose=mystic_verbose)

Optimiser.SetMethod("least_squares")
ExtractionUtils.DoStage("LD_step1", Model, Simulator, [KT1, TSS, UTE, AT], Optimiser, [IsVg,IsVghd_AboveVt],[1,5],verbose=mystic_verbose)

isvg_error = ExtractionUtils.PrintErrors("IsVg_error", IsVg, Simulator, Model, ErrorMethod)

idvg_error = ExtractionUtils.PrintErrors("IdVg_error", IdVg_nom_temp, Simulator, Model, ErrorMethod)
idvg_error = ExtractionUtils.PrintErrors("IdVg_error", IdVg_low_temp, Simulator, Model, ErrorMethod)
idvg_error = ExtractionUtils.PrintErrors("IdVg_error", IdVg_high_temp, Simulator, Model, ErrorMethod)

IsVg.WritePLTFile('@pwd@/@nodedir@/n@node@_temp_fit', bias_info=False)
IdVg_nom_temp.WritePLTFile(f'@pwd@/@nodedir@/n@node@-idvg_temp{tnom}')
IdVg_low_temp.WritePLTFile(f'@pwd@/@nodedir@/n@node@-idvg_temp{tlow}')
IdVg_high_temp.WritePLTFile(f'@pwd@/@nodedir@/n@node@-idvg_temp{thigh}')

mdb.StoreFitData(IsVg, Model, description="temp tests", error=isvg_error)
