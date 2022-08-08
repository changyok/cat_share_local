#setdep @node|Mystic_Response_Surface:all@

if "@Type@" == "tbc" or "@midpoint@" != "True" or "@Type@" != "nMOS":
   import sys; sys.exit()


mystic_inputfile1 = "@pwd@/@nodedir@/pp@node@_mys.py1"
mystic_inputfile2 = "@pwd@/@nodedir@/pp@node@_mys.py2"
mystic_inputfile3 = "@pwd@/@nodedir@/pp@node@_mys.py3"
mystic_inputfile4 = "@pwd@/@nodedir@/pp@node@_mys.py4"
mystic_inputfile5 = "@pwd@/@nodedir@/pp@node@_mys.py5"
initial_modelcard = "@pwd@/@nodedir@/pp@node@_mys.mod"

# setup flow specific parameters
mystic.wait		= True

# stage 1 
mystic.inputfile	= mystic_inputfile1
mystic.args.model	= None
mystic(previous=None,   dataset=f"{node}-WFshift")





