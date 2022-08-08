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
vdd_cgg           = 0.0

# Simulation parameters
mystic_verbose    = False

# terminal mapping
drain_con 	= "@acdrain_con@"
gate_con 	= "@acgate_con@"
source_con	= "@acsource_con@"
bulk_con	= "@acbulk_con@"

ivdrain_con 	= "@drain_con@"
ivgate_con 	= "@gate_con@"
ivsource_con	= "@source_con@"
ivbulk_con	= "@bulk_con@"

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
Optimiser.SetMethod("least_squares")

# Load the data/model from the previous stage
Model = mdb.GetFitModel()
# ------------------------------------------------------------------- #
Model.SetModelParameter(f'{modstr}cfs',1e-11)
Model.SetModelParameter(f'{modstr}cfd',1e-11)
Model.SetModelParameter(f'{modstr}cgsl',1e-11)
Model.SetModelParameter(f'{modstr}cgdl',1e-11)

Model.SetModelParameter(f'{modstr}dlc',-2.5e-9)
Model.SetModelParameter(f'{modstr}qmtcencv',0.5)

# Load the data
CV_raw  =mdb.Load(dvar=f'c({gate_con},{gate_con})', dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom).resample(step=0.05)

# Filterring high drain CV data as only the low drain CV data is required for extraction
CV_raw_ld	= 	CV_raw.FilterData(		'eq', 	vdd_cgg, 	dtype=f"bias.{drain_con}")

# Filter off extra data
#if "@Type@" == "nMOS"
AboveAccu = 	('ge', -0.1, "ivar")
BelowInv  = 	('le', 0.3,   "ivar")
AboveInv  = 	('ge', 0.4,   "ivar")
HighGate  = 	('le', vdd_nom,   "ivar")
#else if "@Type@" == "pMOS"
AboveAccu = 	('le', 0.1,  "ivar")
BelowInv  = 	('ge', -0.3, "ivar")
AboveInv  = 	('le', -0.4, "ivar")
HighGate  = 	('ge', vdd_nom, "ivar")
#endif


CV_filtered_ld = CV_raw_ld.FilterData(*HighGate).FilterData(*AboveAccu)
CV_BelowInv_ld = CV_filtered_ld.FilterData(*BelowInv)
CV_AboveInv_ld = CV_filtered_ld.FilterData(*AboveInv)

# Setup CV parameters 
deltawcv = OptParam(		f'{modstr}deltawcv',	0,	-30e-9, 30e-9,	1e-8)
nbody = OptParam(		f'{modstr}nbody',	2e20,	2e18, 2e22,	1e23)

#if "@Type@" == "nMOS"
cfs     = OptParam(		f'{modstr}cfs',	1e-11,	1e-15,	1e-8,	1e-11)
cfd     = LinkedOptParam(	f'{modstr}cfd',cfs)
cgsl     = OptParam(		f'{modstr}cgsl',	1e-11,	1e-15,	1e-8,	1e-11)
cgdl     = LinkedOptParam(	f'{modstr}cgdl',cgsl)
ckappas  = OptParam(		f'{modstr}ckappas',	0.6,	0.05,	200,	2)
ckappad  = LinkedOptParam(	f'{modstr}ckappad',ckappas) 
dlc      = OptParam(		f'{modstr}dlc',		-0.5e-9,	-8e-9,	-0.5e-9,	1.0e-9)
qmtcencv = OptParam(		f'{modstr}qmtcencv',	0.5,	1e-6,	20,	1)
qm0      = OptParam(		f'{modstr}qm0',		0.001,	1e-8,	10,	0.1) 
#else if "@Type@" == "pMOS"
cfs     = OptParam(		f'{modstr}cfs',	1e-11,	1e-15,	1e-8,	1e-11)
cfd     = LinkedOptParam(	f'{modstr}cfd',cfs)
cgsl     = OptParam(		f'{modstr}cgsl',	1e-11,	1e-15,	1e-8,	1e-11)
cgdl     = LinkedOptParam(	f'{modstr}cgdl',cgsl)
ckappas  = OptParam(		f'{modstr}ckappas',	0.6,	0.05,	200,	1)
ckappad  = LinkedOptParam(	f'{modstr}ckappad',ckappas) 
dlc      = OptParam(		f'{modstr}dlc',		-0.5e-9,	-8e-9,	-0.5e-9,	1.0e-9)
qmtcencv = OptParam(		f'{modstr}qmtcencv',	0.5,	1e-6,	20,	1)
qm0      = OptParam(		f'{modstr}qm0',		0.001,	1e-8,	10,	0.1)  
#endif
pqm	 = OptParam(		f'{modstr}pqm',		0.66,	0.1,	2.0,	0.01)
delvfbacc = OptParam(		f'{modstr}delvfbacc',	0.0,	-0.1,	0.1,	0.001)

# Setup Parametersets
CVParameters_BelowInv    	= [dlc,cgsl,cgdl,cfs,cfd,ckappas,ckappad]
CVParameters_AboveInv    	= [qmtcencv,qm0,dlc,cgsl,cgdl,pqm]
AllPars                 	= [cfs,cfd,ckappas,cgsl,ckappad,cgdl,dlc,qmtcencv,qm0,pqm,delvfbacc]
x=0
fit_error=1e9
# Run Extraction
while (x<2 and fit_error>1):
    for j in range(1): ExtractionUtils.DoStage("CV_step1", Model, Simulator, CVParameters_BelowInv, Optimiser, [CV_BelowInv_ld])
    for j in range(1): ExtractionUtils.DoStage("CV_step2", Model, Simulator, CVParameters_AboveInv, Optimiser, [CV_AboveInv_ld])
    fit_error = ExtractionUtils.PrintErrors("CV_step2_error", CV_filtered_ld, Simulator, Model, ErrorMethod)
    x+=1


ExtractionUtils.DoStage("CV_step3", Model, Simulator, AllPars, Optimiser, [CV_filtered_ld,CV_AboveInv_ld],[1,3], verbose=mystic_verbose)


print("\n Final Errors: ")
print(CV_filtered_ld)
fit_error = CV_filtered_ld.CalculateSingleError()
print(fit_error)
fit_error = ExtractionUtils.PrintErrors("CV_final_error", CV_filtered_ld, Simulator, Model, ErrorMethod)
print(CV_filtered_ld)


# Store fit data and params in the DB
for d in CV_filtered_ld:
   d.metadata["bias"][drain_con]=0.0
   d.metadata["bias"][source_con]=0.0
   d.metadata["bias"][bulk_con]=0.0
mdb.StoreFitData(CV_filtered_ld, Model, error=fit_error)

Optimiser.write_parameter_csv('@pwd@/@nodedir@/n@node@-cv-pars')
CV_filtered_ld.WritePLTFile('@pwd@/@nodedir@/n@node@-cv')


