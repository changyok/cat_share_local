# Don't send back the calibration parameters to the parent project, send them to the output parameter section instead. Need to specify a parameter which is not changed during the calibration.
opt_params = ["Threads"]

# Tools to be run during the optimization.
opt_tools = ["Garand_xNinvVg", "DG_profiles"]

# Queue to be used in child deck.
# opt_queue = "local:default"

# Files/folders to copy to child deck.
files_to_copy = ["gqueues.dat", "gtooldb.tcl"]

# Path to child projects.
opt_folder = "@pwdout@" + "/../CHILD_DIR"

