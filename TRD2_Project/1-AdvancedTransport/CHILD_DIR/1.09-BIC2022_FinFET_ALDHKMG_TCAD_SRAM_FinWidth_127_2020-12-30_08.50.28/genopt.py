optimizer.parent = dict()
optimizer.parent["project_dir"] = "/nfs/pdx/disks/icf_sandp_gwa001/changyok/swb/SNPS_DTCO/TRD2/20201220/BIC2022/1-AdvancedTransport/1.09-BIC2022_FinFET_ALDHKMG_TCAD_SRAM_FinWidth"
optimizer.parent["node_dir"] = "results/nodes/127"
optimizer.parent["node"] = 127





import shutil

if shutil.which("qstat.real") is not None:
	optimizer.app.jm.waitcmd = "qstat.real"

import os
import time
import datetime

start = time.time()

m_si_v = TOptParam("vert_semi",  0.5, 1e-3, 2, Log10)
m_si_h = TOptParam("horiz_semi", 0.5, 1e-3, 3, Log10)
m_ox = TOptParam("ox",   0.5, 1e-3, 2, Log10)
WF = TOptParam("WF", 4.338, 4.338-0.05, 4.338+0.05, Linear(scale=1.0))


target_DG = set_optimization_target("DG_error")
target_Ninv = set_optimization_target("Ninv_error")

np.random.seed(195712)

optimizer.backend.set_method("minimize")
optimizer.backend.set_optimisation_parameters(kwargs={"eps": 1.e-3,"step_method": "rel"}, method='L-BFGS-B', options={'ftol': 1e-5,'maxfun': 200,'maxiter': 100,'disp': True})

opt_pars = optimizer.optimize([m_si_h, m_si_v, m_ox, WF], [target_DG, target_Ninv])

for key in opt_pars:
	print("DOE: %s_opt %.4f" % (key, opt_pars[key]))

end = time.time()
elapsedTime = str(datetime.timedelta(seconds=(end-start)))
print("")
print("Elapsed Time = %s " % elapsedTime)
print("")




