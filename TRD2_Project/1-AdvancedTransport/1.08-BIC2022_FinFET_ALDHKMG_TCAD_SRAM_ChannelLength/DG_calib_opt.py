#setdep @node|DG_profiles@

#set vert_semi_opt       x
#set horiz_semi_opt      x
#set ox_opt              x
#set WF_opt              x

# --------------------------------- #
# --- Start optimization script --- #
# --------------------------------- #

##from common.optimizers.parameter_transform import DecimalLogarithmicTransform as Log10
##from common.optimizers.parameter_transform import LinearTransform

import shutil

if shutil.which("qstat.real") is not None:
	optimizer.app.jm.waitcmd = "qstat.real"

import os
import time
import datetime

## Time stamp to measure the elapsed time
start = time.time()

# Setting optimization parameters
# Parameter names must match parameters in the swb project
m_si_v = TOptParam("vert_semi",  @vert_semi@, 1e-3, 2, Log10)
m_si_h = TOptParam("horiz_semi", @horiz_semi@, 1e-3, 3, Log10)
m_ox = TOptParam("ox",   @ox@, 1e-3, 2, Log10)
WF = TOptParam("WF", @WF_init@, @WF_init@-0.05, @WF_init@+0.05, Linear(scale=1.0))


# Setting the target data
# Take from SWB variable "DG_error", minimise its distance to 0
target_DG = set_optimization_target("DG_error")
target_Ninv = set_optimization_target("Ninv_error")

# Optimization Setting
# Set a random seed for reproducibility
np.random.seed(195712)

# Set options for final local minimiser
optimizer.backend.set_method("minimize")
optimizer.backend.set_optimisation_parameters(kwargs={"eps": 1.e-3,"step_method": "rel"}, method='L-BFGS-B', options={'ftol': 1e-5,'maxfun': 200,'maxiter': 100,'disp': True})
##optimizer.backend.enable_verbose(2)

# Run optimization
opt_pars = optimizer.optimize([m_si_h, m_si_v, m_ox, WF], [target_DG, target_Ninv])

for key in opt_pars:
	print("DOE: %s_opt %.4f" % (key, opt_pars[key]))

#### Calculate elapsed time
end = time.time()
elapsedTime = str(datetime.timedelta(seconds=(end-start)))
print("")
print("Elapsed Time = %s " % elapsedTime)
print("")


