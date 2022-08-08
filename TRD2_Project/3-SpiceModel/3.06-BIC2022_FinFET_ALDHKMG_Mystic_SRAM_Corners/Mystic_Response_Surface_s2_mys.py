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
mystic_verbose = False

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

# ------------------------------------------------------------------- #
# Load the data/model from the previous stage
Model = mdb.GetFitModel()
# ------------------------------------------------------------------- #

# IdVg data
IdVg  	= mdb.Load(dvar=f'i{drain_con}',  ivar=f'v{gate_con}',  dtype=dtype, instances={"l":lgate, "avgStrain":avgStrainNom}, tfin=tfin, temperature=tnom)

temp_range = [@lowT@, @tnom@, @highT@]

for t in temp_range:
    t=int(int(t)-273)
    for d in IdVg:
        d.metadata["bias"][source_con]=0.0
        d.metadata["bias"][bulk_con]=0.0
        d.metadata["temperature"]=t
    e = ExtractionUtils.PrintErrors(mysticProjectName, IdVg, Simulator, Model, ErrorMethod)
    IdVg.WritePLTFile(f'@pwd@/@nodedir@/n@node@_idvg_temp{t}')


