from libfromage.data import Data
Data.set_options(data_mask=True)


import numpy as np
def log10(data):
    return np.log10(abs(data))

Model.SetModelParameter("mosmod.EU",1) # needed to stop -ve current increase
Model.SetModelParameter("mosmod.UP",1e-9)  # Gate L length dependence of U0
Model.SetModelParameter("mosmod.LPA",1.5)  # Gate L length dependence of U0
Model.SetModelParameter("mosmod.BUA",1e-9)  # Gate L length dependence of UA
Model.SetModelParameter("mosmod.AUA",1.0)  # Gate L length dependence of UA


IdVg   = mdb.Load(dvar=f'i{drain_con}',  ivar=f'v{gate_con}', Type='pMOS', tfin=8e-9)

IdVgld = IdVg.FilterData('eq', vdd_lin, dtype=f"bias.{drain_con}")

IdVgld_lgs = {}
for lg in [2.3e-08,2.5e-08,2.7e-08]:
    #IdVgld_lgs[f"IdVgld_l{lg}"] = IdVgld.FilterData('eq', lg, dtype="instances.l")
    #IdVgld_lgs[f"IdVgld_l{lg}"].interactive = True
    ExtractionUtils.PrintErrors(f"IdVgld_l{lg}",IdVgld_lgs[f"IdVgld_l{lg}"],Simulator, Model, ErrorMethod)

IdVgld_lgs_log10 = {}
for lg in [2.3e-08,2.5e-08,2.7e-08]:
    IdVgld_lgs_log10[f"IdVgld_l{lg}"] = IdVgld_lgs[f"IdVgld_l{lg}"].MakeFoMTarget(log10)

IdVgld_lgs_d = {}
for lg in [2.3e-08,2.5e-08,2.7e-08]:
    IdVgld_lgs_d[f"IdVgld_l{lg}"] = IdVgld_lgs[f"IdVgld_l{lg}"].MakeFoMTarget("derivative")
    IdVgld_lgs_d[f"IdVgld_l{lg}"].interactive=True
    # plotting transforms seems currently broken
    ExtractionUtils.PrintErrors(f"IdVgld_l{lg}",IdVgld_lgs_d[f"IdVgld_l{lg}"],Simulator, Model, ErrorMethod)

# VT params
phigval     = Model.GetModelParameter(f'{modstr}PHIG')
PHIG        = OptParam(f'{modstr}PHIG',		phigval,phigval-0.5,	phigval+0.5,	1)
CDSC        = OptParam(f'{modstr}CDSC',		0.001,	0.0,		10.0,		5)

#basic mobility params
U0          = OptParam(f'{modstr}U0',		0.02,	0.004,		1.0,		0.01)
UA          = OptParam(f'{modstr}UA',		0.3,	0.0,		100.0,		1.0)
ETAMOB      = OptParam(f'{modstr}ETAMOB',	2,	0,		10,		2)
EU          = OptParam(f'{modstr}EU',		2.5,	0.1,		10.0,		1)

# l-dependent mobility params
UP          = OptParam(f'{modstr}UP',		0.0,	-1e-8,		1e-8,		1e-6)
LPA         = OptParam(f'{modstr}LPA',		1.0,	0,		100.0,		1)
BUA          = OptParam(f'{modstr}BUA',		0.0,	-5e-8,		5e-8,		1e-8)
AUA         = OptParam(f'{modstr}AUA',		1.0,	0,		100.0,		1)


# fit VT first - no need for Lg dependence of VT fitting in this examples
ExtractionUtils.DoStage("LD_step1", Model, Simulator, [PHIG,CDSC], Optimiser, [IdVgld_lgs_log10["IdVgld_l2.7e-08"]],verbose=True)
ExtractionUtils.DoStage("LD_step1", Model, Simulator, [PHIG,CDSC], Optimiser, [IdVgld_lgs_log10["IdVgld_l2.7e-08"],IdVgld_lgs_log10["IdVgld_l2.5e-08"],IdVgld_lgs_log10["IdVgld_l2.3e-08"]],verbose=True)

# fit basic mobility params first
ExtractionUtils.DoStage("LD_step1", Model, Simulator, [U0,UA,ETAMOB], Optimiser, [IdVgld_lgs["IdVgld_l2.7e-08"],
IdVgld_lgs_d["IdVgld_l2.7e-08"]],verbose=True)
ExtractionUtils.DoStage("LD_step1", Model, Simulator, [U0,UA,ETAMOB,EU], Optimiser, [IdVgld_lgs["IdVgld_l2.7e-08"],
IdVgld_lgs_d["IdVgld_l2.7e-08"]],verbose=True)
ExtractionUtils.DoStage("LD_step1", Model, Simulator, [U0,UA,ETAMOB,EU,PHIG], Optimiser, [IdVgld_lgs["IdVgld_l2.7e-08"],
IdVgld_lgs_d["IdVgld_l2.7e-08"]],verbose=True)

# fit Lg dependence of U0
ExtractionUtils.DoStage("LD_step1", Model, Simulator, [UP, LPA,U0,UA,ETAMOB,EU,PHIG], Optimiser, [IdVgld_lgs["IdVgld_l2.7e-08"],IdVgld_lgs["IdVgld_l2.5e-08"],IdVgld_lgs["IdVgld_l2.3e-08"],
IdVgld_lgs_d["IdVgld_l2.7e-08"],IdVgld_lgs_d["IdVgld_l2.5e-08"],IdVgld_lgs_d["IdVgld_l2.3e-08"]],verbose=True)

# fit Lg dependence of U0/UA
ExtractionUtils.DoStage("LD_step1", Model, Simulator, [UP, LPA, AUA,BUA], Optimiser, [IdVgld_lgs["IdVgld_l2.7e-08"],IdVgld_lgs["IdVgld_l2.5e-08"],IdVgld_lgs["IdVgld_l2.3e-08"]],verbose=True)

ExtractionUtils.DoStage("LD_step1", Model, Simulator, [AUA, BUA,UP, LPA,U0,UA,ETAMOB,EU,PHIG], Optimiser, [IdVgld_lgs["IdVgld_l2.7e-08"],IdVgld_lgs["IdVgld_l2.5e-08"],IdVgld_lgs["IdVgld_l2.3e-08"],
IdVgld_lgs_d["IdVgld_l2.7e-08"],IdVgld_lgs_d["IdVgld_l2.5e-08"],IdVgld_lgs_d["IdVgld_l2.3e-08"]],verbose=True)

