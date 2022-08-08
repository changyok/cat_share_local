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
mystic_verbose    = False

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


IsVg     = mdb.GetFitData(ivar=f"v{gate_con}", 	dvar=f"i{source_con}")
IsVgld   = mdb.GetFitData(ivar=f"v{gate_con}", 	dvar=f"i{source_con}", bias={f"{drain_con}":vdd_lin})
IsVghd   = mdb.GetFitData(ivar=f"v{gate_con}", 	dvar=f"i{source_con}", bias={f"{drain_con}":vdd_nom})
IsVd     = mdb.GetFitData(ivar=f"v{drain_con}", dvar=f"i{source_con}")
IsVd_vdd = mdb.GetFitData(ivar=f"v{drain_con}", dvar=f"i{source_con}", bias={f"{gate_con}":vdd_nom})

IdVg     = mdb.Load(dvar=f"i{drain_con}", ivar=f"v{gate_con}", dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom)
IdVd     = mdb.Load(dvar=f"i{drain_con}", ivar=f"v{drain_con}", dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom)

IdVgld 	 = IdVg.FilterData('eq', vdd_lin, dtype=f"bias.{drain_con}")

# Setup bias points for gm evalution
#if "@Type@" == "nMOS"
vg_deriv_biases = np.linspace(vdd_nom-0.3, vdd_nom, 11)
vd_deriv_biases = np.linspace(vdd_nom-0.3, vdd_nom, 11)
#else
vg_deriv_biases = np.linspace(vdd_nom, vdd_nom+0.3, 11)
vd_deriv_biases = np.linspace(vdd_nom, vdd_nom+0.3, 11)
#endif

# Calculate VtGmMax
vt_gm_val = float(IdVgld.VtGmMaxFinal())
ivt       = float(IdVgld[0](vt_gm_val))

#if "@Type@" == "nMOS"
IdVd           = IdVd.FilterData('gt',   0.0,			dtype="ivar")
IsVd           = IsVd.FilterData('gt',   0.45,                  dtype=f"bias.{gate_con}")
IsVd	       = IsVd.FilterData('gt', 	 1e-7,			dtype="dvar")
IsVd_vdd       = IsVd_vdd.FilterData('gt', 1e-7,		dtype="dvar")
IsVgld         = IsVgld.FilterData('gt', 1e-13, 		dtype="dvar")
IsVghd         = IsVghd.FilterData('gt', 1e-13, 		dtype="dvar")
IsVgld_BelowVt = IsVgld.FilterData("lt", vt_gm_val-0.02, 	dtype="ivar")
IsVgld_AboveVt = IsVgld.FilterData("gt", vt_gm_val-0.02,	dtype="ivar")
IsVghd_BelowVt = IsVghd.FilterData("lt", vt_gm_val-0.02, 	dtype="ivar")
IsVghd_AboveVt = IsVghd.FilterData("gt", vt_gm_val-0.02, 	dtype="ivar")
off = 0.1
IsVghd_MidInv 	= IsVghd_AboveVt.FilterData(		'le', 	vg_max-0.2, dtype="ivar")
IsVghd_StrongInv 	= IsVghd.FilterData(		'ge', 	vg_max-0.2, dtype="ivar")
IsVghd_onFoM 	= IsVghd_AboveVt.MakeFoMTarget(	'ion', 	vg_max-0.05)
#else
IdVd           = IdVd.FilterData('lt',   0.0,			dtype="ivar")
IsVd           = IsVd.FilterData('lt',   -0.45,                 dtype=f"bias.{gate_con}")
IsVd	       = IsVd.FilterData('lt', 	 -1e-7,			dtype="dvar")
IsVd_vdd       = IsVd_vdd.FilterData('lt', -1e-7,		dtype="dvar")
IsVgld         = IsVgld.FilterData('lt', -1e-13, 		dtype="dvar")
IsVghd         = IsVghd.FilterData('lt', -1e-13,	 	dtype="dvar")
IsVgld_BelowVt = IsVgld.FilterData("gt", vt_gm_val+0.02, 	dtype="ivar")
IsVgld_AboveVt = IsVgld.FilterData("lt", vt_gm_val+0.02, 	dtype="ivar")
IsVghd_BelowVt = IsVghd.FilterData("gt", vt_gm_val+0.02, 	dtype="ivar")
IsVghd_AboveVt = IsVghd.FilterData("lt", vt_gm_val+0.02, 	dtype="ivar")
off = -0.1
IsVghd_StrongInv	= IsVghd.FilterData(		'le', 	vg_max+0.2, dtype="ivar")
IsVghd_MidInv 	= IsVghd_AboveVt.FilterData(		'ge', 	vg_max+0.2, dtype="ivar")
IsVghd_onFoM 	= IsVghd_AboveVt.MakeFoMTarget(	'ion', 	vg_max+0.05)
#endif

Ioff_sat	= IsVghd.MakeFoMTarget("ioff", off)

# Set up parameters
phigval  = Model.GetModelParameter(f'{modstr}PHIG')
PHIG     = OptParam(f'{modstr}PHIG',	phigval,	phigval-0.5,	phigval+0.5,	1)
ETA0     = OptParam(f'{modstr}ETA0',	2,		0,		100,		0.1)
CDSC     = OptParam(f'{modstr}CDSC',	7e-3,		0.0,		10.0,		1)
CDSCD    = OptParam(f'{modstr}CDSCD',	7e-3,		0,		1,		0.01)
U0       = OptParam(f'{modstr}U0',	0.02,		0.001,		10.0,		0.001)
UA       = OptParam(f'{modstr}UA',	0.3,		0.0,		100.0,		0.1)
ETAMOB   = OptParam(f'{modstr}ETAMOB',	2,		0,		100,		2)
EU       = OptParam(f'{modstr}EU',	2.5,		0.1,		10.0,		0.1)
VSAT     = OptParam(f'{modstr}VSAT',	100000,		10000,		600000,		10000)
VSAT1    = OptParam(f'logvsat1',	5.0,		3.0,		5.5,		0.1)
PTWG	 = OptParam(f'logptwg',		0.3,		-5.0,		1.7,		0.01)
KSATIV   = OptParam(f'{modstr}KSATIV',	1,		-5,		5,		0.1)
MEXP	 = OptParam(f'logmexp',		0.3,		-5.0,		1.0,		0.1)
PVAG     = OptParam(f'{modstr}PVAG',	1,		0,		100,		0.1)
PDIBL2	 = OptParam(f'logpdibl2',	-4.0,		-20.0,		1.0,		0.01)
DVTP0    = OptParam(f'{modstr}DVTP0', 	-0.01, 		-0.5, 		0.1, 		0.005)
RDSWMIN	 = OptParam(f'{modstr}RDSWMIN',	50.0,		10.0,		10000.0,	10)

Simulator.SetSimulationGMIN(1e-18)

# compact model parametersets for initial fit
Stage1Parameters = [DVTP0]
Stage2Parameters = [CDSCD]
Stage3Parameters  = [DVTP0,CDSCD]
Stage4Parameters = [PHIG,CDSC,DVTP0,CDSCD]
Stage5Parameters = [VSAT]
Stage6Parameters = [VSAT1]
Stage7Parameters = [PTWG]
Stage8Parameters  = [U0,UA]
Stage9Parameters  = [KSATIV,MEXP,PVAG,PDIBL2]
StageAllParameters  = [CDSC,PHIG,ETAMOB,EU,U0,UA,CDSCD,DVTP0,KSATIV,MEXP,PDIBL2,PTWG,PVAG,VSAT,VSAT1]

isvg_error=1000.0
isvd_error=1000.0
x=0.0
# Extraction Strategy

while (x < 3 and  (isvg_error > 3.5 or isvd_error > 3.5)):
    ExtractionUtils.DoStage("HD_step1", Model, Simulator, Stage1Parameters, Optimiser, [Ioff_sat], verbose=mystic_verbose)
    ExtractionUtils.DoStage("HD_step2", Model, Simulator, Stage2Parameters, Optimiser, [IsVghd_BelowVt], verbose=mystic_verbose)
    ExtractionUtils.DoStage("HD_step3", Model, Simulator, Stage3Parameters, Optimiser, [IsVghd_BelowVt], verbose=mystic_verbose)
    ExtractionUtils.DoStage("HD_step4", Model, Simulator, Stage4Parameters, Optimiser, [IsVghd_BelowVt, IsVgld_BelowVt], verbose=mystic_verbose)
    ExtractionUtils.DoStage("HD_step5", Model, Simulator, Stage5Parameters, Optimiser, [IsVghd_MidInv], verbose=mystic_verbose)
    ExtractionUtils.DoStage("HD_step6", Model, Simulator, Stage6Parameters, Optimiser, [IsVghd_onFoM], verbose=mystic_verbose)
    ExtractionUtils.DoStage("HD_step7", Model, Simulator, Stage7Parameters, Optimiser, [IsVghd_StrongInv], verbose=mystic_verbose)
    ExtractionUtils.DoStage("HD_step8", Model, Simulator, Stage8Parameters, Optimiser, [IsVgld_AboveVt], verbose=mystic_verbose)
    ExtractionUtils.DoStage("HD_step9", Model, Simulator, Stage9Parameters, Optimiser, [IsVd], verbose=mystic_verbose)
    isvg_error = ExtractionUtils.PrintErrors("HD_step9_error", IsVg, Simulator, Model, ErrorMethod)
    isvd_error = ExtractionUtils.PrintErrors("HD_step9_error", IsVd, Simulator, Model, ErrorMethod)
    x+=1

Optimiser.SetMethod("least_squares")
ExtractionUtils.DoStage("HD_step_polish", Model, Simulator, StageAllParameters, Optimiser, [IsVg,IsVd,IsVd_vdd],verbose=mystic_verbose)

isvg_error = ExtractionUtils.PrintErrors("HD_step_IsVg_error", IsVg, Simulator, Model, ErrorMethod)
isvd_error = ExtractionUtils.PrintErrors("HD_step_IsVd_error", IsVd, Simulator, Model, ErrorMethod)

mdb.StoreFitData(IsVg, Model, error=isvg_error)
mdb.StoreFitData(IsVd, Model, error=isvd_error)

Optimiser.write_parameter_csv('@pwd@/@nodedir@/n@node@-idvg-hd-pars')
ExtractionUtils.PrintErrors("HD_step_IdVg_error", IdVg, Simulator, Model, ErrorMethod)
ExtractionUtils.PrintErrors("HD_step_IdVd_error", IdVd, Simulator, Model, ErrorMethod)
IdVg.WritePLTFile('@pwd@/@nodedir@/n@node@-idvg-hd')
IdVd.WritePLTFile('@pwd@/@nodedir@/n@node@-idvd-hd')

