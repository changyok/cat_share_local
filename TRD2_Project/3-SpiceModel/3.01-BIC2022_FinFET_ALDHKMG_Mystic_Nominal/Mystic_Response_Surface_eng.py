#setdep @node|Mystic_Uniform_Enigma:all@

#if "@Type@" == "tbc" 
#noexec

#else
mystic_inputfile1 = "@pwd@/@nodedir@/pp@node@_mys.py1"
mystic_inputfile2 = "@pwd@/@nodedir@/pp@node@_mys.py2"
mystic_inputfile3 = "@pwd@/@nodedir@/pp@node@_mys.py3"
mystic_inputfile4 = "@pwd@/@nodedir@/pp@node@_mys.py4"
mystic_inputfile5 = "@pwd@/@nodedir@/pp@node@_mys.py5"
initial_modelcard = "@pwd@/@nodedir@/pp@node@_mys.mod"

# setup flow specific parameters
mystic.wait		= True
### ---------------------------------------------------------------- ###
node_prj.copy_metadata(dbi.get_project("@node|SetupVariables@"))
### ---------------------------------------------------------------- ###
print(node_prj.metadata)
# calculate the midpoing node to use as "previous"
mid_prj_node = dbi.get_project(swb__Type="@Type@", \
                               swb__tool_label="Mystic_Uniform_Enigma", \
                               swb__midpoint="True")

previous_dataset=list(mid_prj_node.datasets)[-2].name
print(previous_dataset)

# Setup the mystic inputs
mystic.inputfile	= mystic_inputfile1
mystic.args.model	= None
mystic(previous=previous_dataset, dataset=f"{node}-RSM")

# Temperature
mystic.inputfile	= mystic_inputfile2
mystic.args.model	= None
mystic(previous=f"{node}-RSM", dataset=f"{node}-temp")

# Stress
mystic.inputfile	= mystic_inputfile3
mystic.args.model	= None
mystic(previous=f"{node}-RSM", dataset=f"{node}-stress")

#endif
