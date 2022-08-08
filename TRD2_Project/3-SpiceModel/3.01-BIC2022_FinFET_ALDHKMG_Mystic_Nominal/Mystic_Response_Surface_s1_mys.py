from libfromage.data import Data
Data.set_options(error_method="log_rel")

# ----------- PARAMETRISATION FROM GLOBAL AND SPLIT OPTIONS, OR DEFAULTS -----------

# Device split parameters
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

# Set defaults for optional parameters
mystic_verbose = True

# Set Mystic project and output label for this stage of the flow
mysticProjectName = "@node@"					# Name of Mystic project in database

# terminal mapping
drain_con 	= "@drain_con@"
gate_con 	= "@gate_con@"
source_con	= "@source_con@"
bulk_con	= "@bulk_con@"
# terminal mapping
acdrain_con 	= "@acdrain_con@"
acgate_con 	= "@acgate_con@"
acsource_con	= "@acsource_con@"
acbulk_con	= "@acbulk_con@"

modstr		= "mosmod."
# ---------------------------- MYSTIC EXECUTION SCRIPT -----------------------------

Simulator.SetAdditionalSpiceArguments(['-C'])

# Use mean percentage error over the range of data.
ErrorMethod = "rmsd"
# Turn on the fast jacobian calculation.
Optimiser.SetOptimisationParameter("jac", True)
eps=1e-5
Optimiser.SetOptimisationParameter("eps1",eps)
Optimiser.SetOptimisationParameter("eps2",eps)
Optimiser.SetOptimisationParameter("eps3",eps)
Optimiser.SetOptimisationParameter("eps4",eps)
Optimiser.SetOptimisationParameter("eps5",eps)
Optimiser.SetOptimisationParameter("eps6",eps)
Optimiser.SetOptimisationParameter("delta",1.0)
Optimiser.SetOptimisationParameter("jacobian_eps",1e-3)
Optimiser.SetOptimisationParameter("kwargs",{"eps":1e-3,"step_type":"rel","step_method":"cd"})

Optimiser.SetMethod("least_squares")

# ------------------------------------------------------------------- #
# Load the data/model from the previous stage
Model = mdb.GetFitModel()
# this will always be the first stage here, so we
# set overwrite to True
mdb.StoreInitialModel(Model, overwrite=True)
# ------------------------------------------------------------------- #

# pick up Geom params
Model.SetModelParameter(f'{modstr}TFIN',tfin)
Model.SetModelParameter(f'{modstr}HFIN',hfin)
Model.SetModelParameter(f'phigvar',0.0)

# IdVg data
IdVg  	= mdb.Load(dvar=f'i{drain_con}',  ivar=f'v{gate_con}',  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom)
##[d.resample(step=0.025,log=True) for d in IdVg]
IdVgall	= mdb.Load(dvar=f'i{drain_con}',  ivar=f'v{gate_con}',  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom)
##[d.resample(step=0.025,log=True) for d in IdVgall]
IdVg_LD	= mdb.Load(dvar=f'i{drain_con}',  ivar=f'v{gate_con}',  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom, bias={f"{drain_con}":vdd_lin})
##[d.resample(step=0.025,log=True) for d in IdVg_LD]
IdVg_HD	= mdb.Load(dvar=f'i{drain_con}',  ivar=f'v{gate_con}',  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom, bias={f"{drain_con}":vdd_nom})
##[d.resample(step=0.025,log=True) for d in IdVg_HD]

# IdVd data
IdVdall	= mdb.Load(dvar=f'i{drain_con}',  ivar=f'v{drain_con}',  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom)
##[d.resample(step=0.025,log=False) for d in IdVdall]
IdVd_VDD = mdb.Load(dvar=f'i{drain_con}',  ivar=f'v{drain_con}',  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom, bias={f"{gate_con}":vdd_nom})
##[d.resample(step=0.025,log=False) for d in IdVd_VDD]

# CV Data
CggVgall = mdb.Load(dvar=f"c({acgate_con},{acgate_con})",  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom)
for d in CggVgall:
   d.metadata["bias"][acdrain_con]=0.0
   d.metadata["bias"][acsource_con]=0.0
   d.metadata["bias"][acbulk_con]=0.0
CggVg_LD = mdb.Load(dvar=f"c({acgate_con},{acgate_con})",  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom, bias={f"{acdrain_con}":0.0}).resample(step=0.05)

# Data filters
# Calculate VtGmMax
vt_gm_val = float(IdVg_LD.VtGmMaxFinal())

# Setup bias points for gm evalution
#if "@Type@" == "nMOS"
AboveAccu = 	('ge', -0.1, "ivar")
BelowVDD     = ('le', vdd_nom*1.2,    "ivar")
AboveVt      = ('ge', vt_gm_val+0.05, "ivar")
BelowVt      = ('le', vt_gm_val-0.05, "ivar")
Ioff_bias    = ('le', 0.0,            "ivar")
AboveVDDnom  = ('ge', vdd_nom,        "ivar")
HighGate     = ('ge', vdd_nom-0.2,    "ivar")
AboveVDDnomCV_lower  = ('ge', vdd_nom-0.05,        "ivar")
AboveVDDnomCV_upper  = ('le', vdd_nom+0.05,        "ivar")
AboveHalfVDD = ('ge', vdd_nom/2.0,    "ivar")
LowCurrentFilter = ('lt', -1e-13,     "dvar")
IdVd_filter  = ('lt', -1e-6,     "dvar")
#elif "@Type@" == "pMOS"
AboveAccu = 	('le', 0.1, "ivar")
BelowVDD     = ('ge', 1.2*vdd_nom,    "ivar")
AboveVt      = ('le', vt_gm_val-0.05, "ivar")
BelowVt      = ('ge', vt_gm_val+0.05, "ivar")
Ioff_bias    = ('ge', 0.0,            "ivar")
AboveVDDnom  = ('le', vdd_nom,        "ivar")
HighGate     = ('le', vdd_nom+0.2,    "ivar")
AboveVDDnomCV_lower  = ('le', vdd_nom+0.05,        "ivar")
AboveVDDnomCV_upper  = ('ge', vdd_nom-0.05,        "ivar")
AboveHalfVDD = ('le', vdd_nom/2.0,    "ivar")
LowCurrentFilter = ('gt', 1e-13, "dvar")
IdVd_filter  = ('gt', 1e-6,     "dvar")
#endif

# idvg filters
IdVg    = IdVg.FilterData(*BelowVDD)
IdVg_LD = IdVg_LD.FilterData(*LowCurrentFilter)
IdVg_HD = IdVg_HD.FilterData(*LowCurrentFilter)
IdVg_LD = IdVg_LD.FilterData(*BelowVDD)
IdVg_HD = IdVg_HD.FilterData(*BelowVDD)
Ioff_HD = IdVg_HD.FilterData(*Ioff_bias)
Ioff_LD = IdVg_LD.FilterData(*Ioff_bias)
Ion_LD = IdVg_LD.FilterData(*HighGate)
Ion_HD = IdVg_HD.FilterData(*HighGate)

IdVg_BelowVt = IdVg.FilterData(*BelowVt)
IdVg_AboveVt = IdVg.FilterData(*AboveVt)
IdVg_LD_BelowVt = IdVg_LD.FilterData(*BelowVt)
IdVg_LD_AboveVt = IdVg_LD.FilterData(*AboveVt)
IdVg_HD_BelowVt = IdVg_HD.FilterData(*BelowVt)
IdVg_HD_AboveVt = IdVg_HD.FilterData(*AboveVt)
IdVd_VDD = IdVd_VDD.FilterData(*IdVd_filter)
IdVdall = IdVdall.FilterData(*IdVd_filter)

# accu filter
CggVg_LD = CggVg_LD.FilterData(*AboveAccu)
CggVg_LD_belowVt = CggVg_LD.FilterData(*BelowVt)
CggVg_LD_AboveVDDnom = CggVg_LD.FilterData(*AboveVDDnomCV_lower).FilterData(*AboveVDDnomCV_upper)

print(CggVg_LD_AboveVDDnom)

# Set up parameters
PHIG 	= OptParam(f'{modstr}PHIG', 4.55656, 3, 6, 4)
CDSC 	= OptParam(f'{modstr}CDSC', 0.0147204, 0.0001, 10, 1)
CDSCD 	= OptParam(f'{modstr}CDSCD',7e-3,-1,1,1)
DVTP0 	= OptParam(f'{modstr}DVTP0', -0.01, -0.5, 0.1, 0.1)
U0   	= OptParam(f'{modstr}U0', 0.0279515, 0.0, 1.0, 0.0001)
UA   	= OptParam(f'{modstr}UA', 0, 0.0, 100, 1.0)
EU      = OptParam(f'{modstr}EU', 2.5,	0.1, 10.0, 1)
ETAMOB  = OptParam(f'{modstr}ETAMOB', 2, 0, 10, 2)
VSAT 	= OptParam(f'{modstr}VSAT', 120000, 20000, 600000, 10000)
VSAT1    = OptParam(f'logvsat1',	5.0,		3.0,		6.0,		0.1)
PTWG	 = OptParam(f'logptwg',		0.3,		-5.0,		1.7,		0.01)
# Added for IdVd
KSATIV  = OptParam(f'{modstr}KSATIV',1,-5,5,1)
MEXP	 = OptParam(f'logmexp',		0.3,		-5.0,		1.0,		0.1)
PVAG    = OptParam(f'{modstr}PVAG',1,0,100,1)
PDIBL2	 = OptParam(f'logpdibl2',	-4.0,		-20.0,		1.0,		0.01)
# Added for CggVg
dlc      = OptParam(f'{modstr}dlc',-0.5e-9,-30e-9, 30e-9,1e-10)
cfs     = OptParam(f'{modstr}cfs',	1e-11,	1e-15,	1e-8,	1e-11)
cfd     = LinkedOptParam(f'{modstr}cfd',cfs)
qmtcencv = OptParam(f'{modstr}qmtcencv',	0.5,	1e-6,	20,	1)

# Group parameters for the stages.
S1Parameters=ParameterSet([PHIG,CDSC])
S2Parameters=ParameterSet([U0])
S3Parameters=ParameterSet([UA])
S4Parameters=ParameterSet([DVTP0,CDSCD])
S4aParameters=ParameterSet([MEXP])
S4bParameters=ParameterSet([VSAT])

S5aParameters = ParameterSet([cfs,cfd])
S5Parameters = ParameterSet([cfd,cfs,dlc])

# Do the extraction.
results = dict()
e=100
e2=100
e3=100
i=0
while i<2 and (e>3 or e2>3 or e3>3):
    ExtractionUtils.DoStage(mysticProjectName, Model, Simulator, S1Parameters, Optimiser, [IdVg_LD_BelowVt], verbose=mystic_verbose)
    ExtractionUtils.DoStage(mysticProjectName, Model, Simulator, S2Parameters,  Optimiser, [IdVg_LD_AboveVt], verbose=mystic_verbose)
    ExtractionUtils.DoStage(mysticProjectName, Model, Simulator, S3Parameters,  Optimiser, [Ion_LD], verbose=mystic_verbose)
    for x in range(3):
       ExtractionUtils.DoStage(mysticProjectName, Model, Simulator, S4Parameters,  Optimiser, [IdVg_HD_BelowVt], verbose=mystic_verbose)
       for x in range(3): ExtractionUtils.DoStage(mysticProjectName, Model, Simulator, S4bParameters,  Optimiser, [Ion_HD], verbose=mystic_verbose)
    for x in range(3): ExtractionUtils.DoStage(mysticProjectName, Model, Simulator, S5aParameters,  Optimiser, [CggVg_LD_belowVt], verbose=mystic_verbose)
    for x in range(3): ExtractionUtils.DoStage(mysticProjectName, Model, Simulator, S5Parameters,  Optimiser, [CggVg_LD,CggVg_LD_AboveVDDnom], [1,10], verbose=mystic_verbose)
    i+=1

    e = ExtractionUtils.PrintErrors(mysticProjectName, IdVgall, Simulator, Model, ErrorMethod)
    e2 = ExtractionUtils.PrintErrors(mysticProjectName, IdVdall, Simulator, Model, ErrorMethod)
    e3 = ExtractionUtils.PrintErrors(mysticProjectName, CggVg_LD, Simulator, Model, ErrorMethod)

# Calculate the errors.
ExtractionUtils.PrintErrors(mysticProjectName, IdVg_LD_BelowVt, Simulator, Model, ErrorMethod)
ExtractionUtils.PrintErrors(mysticProjectName, IdVg_LD_AboveVt, Simulator, Model, ErrorMethod)
ExtractionUtils.PrintErrors(mysticProjectName, IdVg_HD_BelowVt, Simulator, Model, ErrorMethod)
ExtractionUtils.PrintErrors(mysticProjectName, IdVg_HD_AboveVt, Simulator, Model, ErrorMethod)

e = ExtractionUtils.PrintErrors(mysticProjectName, IdVgall, Simulator, Model, ErrorMethod)
e2 = ExtractionUtils.PrintErrors(mysticProjectName, IdVdall, Simulator, Model, ErrorMethod)
e3 = ExtractionUtils.PrintErrors(mysticProjectName, CggVgall, Simulator, Model, ErrorMethod)
print("Error_IdVg: {0}%".format(e))
print("Error_IdVd: {0}%".format(e2))
print("Error_CggVg: {0}%".format(e3))

mdb.StoreFitData(IdVgall, Model, description="RSM", error=e)

# output plts
IdVgall.WritePLTFile('@pwd@/@nodedir@/n@node@_idvg')
IdVdall.WritePLTFile('@pwd@/@nodedir@/n@node@_idvd')
CggVgall.WritePLTFile('@pwd@/@nodedir@/n@node@_cggvg')


