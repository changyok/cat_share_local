#setdep @node|spfgen@

 

extract_netlist = "@pwd@/@nodedir|spfgen@/n@node|spfgen@_rph.spf" 

 

node_prj.metadata["netpath"]=extract_netlist
node_prj.save()
