#setdep @node|SaveCornerModels@

# do not save corner models if LV is on
#if "@lv@" == "True"
#noexec
#endif

import re
from common.SPICE.simulator import SimulationResult
SimulationResult.rwav = re.compile("IGNOREWAVEFORMS")
SimulationResult.ralter = re.compile("IGNOREALTERS")

# pre-processed netlist path
netlist_pp = "@pwd@/@nodedir@/pp@node@_pyt.sp"

############################################################
# Lauch Hspice simulation as a Python subprocess
# exec command will be:
# > hspice @pwd@/pp@node@_pyt.sp -o n@node@_hsp
############################################################
from common.SPICE.simulator import HSPICESimulator
simulator = HSPICESimulator()
simulator.timeout = False
simulator.workdir = "./"
result = simulator.run(netlist_pp)
result.check_errors()
print(result.outputs)

ld = result.outputs.iloc[:,:3]
hd = result.outputs.iloc[:,3:]

ld.to_csv("n@node@_ld.csv")
hd.to_csv("n@node@_hd.csv")
