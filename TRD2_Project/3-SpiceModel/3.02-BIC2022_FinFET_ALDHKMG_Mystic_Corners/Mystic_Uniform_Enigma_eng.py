#setdep @node|Stress_Model@

if "@Type@" == "tbc" or "@midpoint@" != "True":
   import sys; sys.exit()


mystic_inputfile1 = "@pwd@/@nodedir@/pp@node@_mys.py1"
mystic_inputfile2 = "@pwd@/@nodedir@/pp@node@_mys.py2"
mystic_inputfile3 = "@pwd@/@nodedir@/pp@node@_mys.py3"
mystic_inputfile4 = "@pwd@/@nodedir@/pp@node@_mys.py4"
mystic_inputfile5 = "@pwd@/@nodedir@/pp@node@_mys.py5"
initial_modelcard = "@pwd@/@nodedir@/pp@node@_mys.mod"

# setup flow specific parameters
mystic.wait		= True

# stage 1 (LD)
mystic.inputfile	= mystic_inputfile1
mystic.args.model	= initial_modelcard
mystic(previous=None,   dataset=f"{node}-low-drain")

# stage 2 (HD)
mystic.inputfile	= mystic_inputfile2
mystic.args.model	= None
mystic(previous=f"{node}-low-drain", dataset=f"{node}-high-drain")

# stage 3 (CV)
mystic.inputfile	= mystic_inputfile3
mystic.args.model	= None
mystic(previous=f"{node}-high-drain", dataset=f"{node}-cv")

# stage 4 (temp dep fitting)
mystic.inputfile	= mystic_inputfile4
mystic.args.model	= None
if @lowT@ != @highT@:
    mystic(previous=f"{node}-cv", dataset=f"{node}-temp")


# stage 5 (stress effect)
mystic.inputfile	= mystic_inputfile5
mystic.args.model	= None
if @lowT@ != @highT@:
    mystic(previous=f"{node}-temp", dataset=f"{node}-stress")
else:
    mystic(previous=f"{node}-cv", dataset=f"{node}-stress")



