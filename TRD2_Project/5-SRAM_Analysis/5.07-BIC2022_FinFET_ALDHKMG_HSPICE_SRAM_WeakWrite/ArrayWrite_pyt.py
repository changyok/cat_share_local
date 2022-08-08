#setdep @node|ppwl@
import re
from common.SPICE.simulator import SimulationResult
SimulationResult.rwav = re.compile("IGNOREWAVEFORMS")

# pre-processed netlist path
netlist_pp = "@pwd@/@nodedir@/pp@node@_pyt.sp"

############################################################
# Lauch Hspice simulation as a Python subprocess
# exec command will be:
# > hspice @pwd@/pp@node@_pyt.sp -o n@node@_hsp
############################################################
#set write_near tba
#set write_far tba
from common.SPICE.simulator import HSPICESimulator
simulator = HSPICESimulator()
simulator.timeout = False
simulator.spiceargs = ["-mt 8 -hpp"]
simulator.workdir = "./"
result = simulator.run(netlist_pp)
result.check_errors()
print(result.measures)
result.measures[0].to_csv("n@node@_parsed.csv")


############################################################
# convert every measure to a SWB variable
#############################################################
for col in result.measures[0].columns:
   print(f"DOE: {col} {result.measures[0][col][0]:.5}")

node_prj.metadata["hspice_output"]=result.measures[0]
node_prj.save()

