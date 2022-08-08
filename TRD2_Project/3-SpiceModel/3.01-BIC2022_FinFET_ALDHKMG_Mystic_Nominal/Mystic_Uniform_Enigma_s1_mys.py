from libfromage.data import Data
Data.set_options(error_method="log_rel")

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
vdd_lin           = @Vdd_lin@					# Linear drain bias [V]
vg_max           = @Vdd_nom@					# Linear drain bias [V]

# Set defaults for optional parameters
mystic_verbose = False

# terminal mapping
drain_con 	= "@drain_con@"
gate_con 	= "@gate_con@"
source_con	= "@source_con@"
bulk_con	= "@bulk_con@"

modstr		= "mosmod."
# ---------------------------- MYSTIC EXECUTION SCRIPT -----------------------------

# Store the initial model to the project
# this will always be the first stage here, so we
# set overwrite to True
mdb.StoreInitialModel(Model, overwrite=True)

Simulator.SetAdditionalSpiceArguments(['-C'])

# Use mean percentage error over the range of data.
ErrorMethod = "rmsd"
# Turn on the fast jacobian calculation.
Optimiser.SetOptimisationParameter("jac", True)

eps=1e-3
Optimiser.SetOptimisationParameter("eps1",eps)
Optimiser.SetOptimisationParameter("eps2",eps)
Optimiser.SetOptimisationParameter("eps3",eps)
Optimiser.SetOptimisationParameter("eps4",eps)
Optimiser.SetOptimisationParameter("eps5",eps)
Optimiser.SetOptimisationParameter("eps6",eps)
Optimiser.SetOptimisationParameter("jacobian_eps",1e-3)
Optimiser.SetOptimisationParameter("kwargs",{"eps":1e-3,"step_type":"abs","step_method":"cd"})

# setup the Fin geometry parameters
Model.SetModelParameter(f'{modstr}TFIN',tfin)
Model.SetModelParameter(f'{modstr}HFIN',hfin)
Model.SetModelParameter(f'{modstr}PHIG',wf0)
Model.SetModelParameter(f'{modstr}TNOM',tnom-273)
Model.SetModelParameter(f'{modstr}LSP',tspacer)
Model.SetModelParameter(f'{modstr}eot',eot)

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

# Some strategy defaults
Model.SetModelParameter('r_sc',0.0)
Model.SetModelParameter('r_dc',0.0)
Model.SetModelParameter(f'{modstr}ETA0', 0.0)
Model.SetModelParameter(f'{modstr}DVTP1',1.0)
Model.SetModelParameter(f'{modstr}CGSL', 1e-20)
Model.SetModelParameter(f'{modstr}UD', 0.0)
Model.SetModelParameter(f'{modstr}CGSO', 0.0)
Model.SetModelParameter(f'{modstr}CGDO', 0.0)

# Stress effects
Model.SetModelParameter('slope_vt_strain', @stress_vt@)
Model.SetModelParameter('slope_id_strain', @stress_cur@)
Model.SetModelParameter('strain_nom', avgStrainNom)


IdVg   = mdb.Load(dvar=f'i{drain_con}',  ivar=f'v{gate_con}',  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom)
#[d.resample(step=0.025,log=True) for d in IdVg]
IsVg   = mdb.Load(dvar=f'i{source_con}', ivar=f'v{gate_con}',  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom)
#[d.resample(step=0.025,log=True) for d in IsVg]
IsVd   = mdb.Load(dvar=f'i{source_con}', ivar=f'v{drain_con}',  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom)
#[d.resample(step=0.025,log=True) for d in IsVd]


# Store fit data and params in the DB
for d in IdVg:
   d.metadata["bias"][source_con]=0.0
   d.metadata["bias"][bulk_con]=0.0

IdVgld 		    = IdVg.FilterData('eq', vdd_lin, dtype=f"bias.{drain_con}")

print(IdVgld)

vt_gm_val = float(IdVgld.VtGmMaxFinal())
print(vt_gm_val)

# Apply fiters
#if "@Type@" == "nMOS"
IsVg		= IsVg.FilterData(		'gt',   1e-13,		dtype="dvar")
IsVgld		= IsVg.FilterData(		'eq', 	vdd_lin,	dtype=f"bias.{drain_con}")
IsVgld_BelowVt 	= IsVgld.FilterData(		'le', 	vt_gm_val-0.1,	dtype="ivar")
IsVgld_AboveVt 	= IsVgld.FilterData(		'ge', 	vt_gm_val,	dtype="ivar")
IsVgld_MidInv 	= IsVgld_AboveVt.FilterData(	'le', 	vg_max-0.1,	dtype="ivar")
IsVgld_StrongInv= IsVgld.FilterData(		'ge', 	vg_max-0.1,	dtype="ivar")
IsVgld_U0 	= IsVgld_AboveVt.FilterData(	'lt', 	vt_gm_val+0.25,	dtype="ivar")
IsVd		= IsVd.FilterData(		'gt',   1e-7, 		dtype="dvar")
#elif "@Type@" == "pMOS"
IsVg		= IsVg.FilterData(		'lt', 	-1e-13, 	dtype="dvar")
IsVgld		= IsVg.FilterData(		'eq', 	vdd_lin, 	dtype=f"bias.{drain_con}")
IsVgld_BelowVt	= IsVgld.FilterData(		'ge', 	vt_gm_val+0.1,	dtype="ivar")
IsVgld_AboveVt	= IsVgld.FilterData(		'le', 	vt_gm_val,	dtype="ivar")
IsVgld_StrongInv= IsVgld.FilterData(		'le', 	vg_max+0.1,	dtype="ivar")
IsVgld_MidInv 	= IsVgld_AboveVt.FilterData(	'ge', 	vg_max+0.1,	dtype="ivar")
IsVgld_U0 	= IsVgld_AboveVt.FilterData(	'gt', 	vt_gm_val-0.25,	dtype="ivar")
IsVd		= IsVd.FilterData(		'lt', 	-1e-7,		dtype="dvar")
#endif
d_IsVgld	= IsVg.MakeFoMTarget("derivative")

#Set up parameters
phigval     = Model.GetModelParameter(f'{modstr}PHIG')
PHIG        = OptParam(f'{modstr}PHIG',		phigval,phigval-0.5,	phigval+0.5,	1)
CDSC        = OptParam(f'{modstr}CDSC',		0.001,	0.0,		10.0,		5)
QMFACTOR    = OptParam(f'{modstr}QMFACTOR',	1.0,	0,		100,		1)
U0          = OptParam(f'{modstr}U0',		0.02,	0.004,		1.0,		0.01)
UA          = OptParam(f'{modstr}UA',		0.0,	0.0,		100.0,		1.0)
ETAMOB      = OptParam(f'{modstr}ETAMOB',	2,	0,		10,		2)
EU          = OptParam(f'{modstr}EU',		2.5,	0.1,		10.0,		1)
RDSWMIN	    = OptParam(f'{modstr}RDSWMIN',	50.0,	10.0,		10000.0,	10)

Simulator.SetSimulationGMIN(1e-18)

Stage1Parameters=[PHIG,CDSC]
Stage2Parameters=[U0]
Stage3bParameters=[UA,EU]
Stage4Parameters=[PHIG,CDSC,U0,UA,ETAMOB,EU]


fit_error=1000
x=0
while (x < 3 and fit_error>1.5):
    ExtractionUtils.DoStage("LD_step1", Model, Simulator, Stage1Parameters, Optimiser, [IsVgld_BelowVt],verbose=mystic_verbose)
    ExtractionUtils.DoStage("LD_step2", Model, Simulator, Stage2Parameters, Optimiser, [IsVgld_U0],verbose=mystic_verbose)
    ExtractionUtils.DoStage("LD_step3", Model, Simulator, Stage3bParameters, Optimiser, [IsVgld_StrongInv],verbose=mystic_verbose)
    fit_error=ExtractionUtils.PrintErrors("LD_step4_error", IsVgld, Simulator, Model, ErrorMethod)
    x+=1

Optimiser.SetMethod("least_squares")
ExtractionUtils.DoStage("LD_step4", Model, Simulator, Stage4Parameters, Optimiser, [IsVgld],verbose=mystic_verbose)

ExtractionUtils.PrintErrors("LD_step_IsVg_error", IsVg,   Simulator, Model, ErrorMethod)
ExtractionUtils.PrintErrors("LD_step_IsVd_error", IsVd,   Simulator, Model, ErrorMethod)

mdb.StoreFitData(IsVg, Model, error=fit_error)
mdb.StoreFitData(IsVd, Model, error=fit_error)

Optimiser.write_parameter_csv('@pwd@/@nodedir@/n@node@-idvg-ld-pars')
ExtractionUtils.PrintErrors("LD_step_IdVgld_error", IdVgld, Simulator, Model, ErrorMethod)
IdVgld.WritePLTFile('@pwd@/@nodedir@/n@node@-idvg-ld')

