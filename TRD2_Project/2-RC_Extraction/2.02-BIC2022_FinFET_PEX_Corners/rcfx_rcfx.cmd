## About this node:
## 1. Source the 1st half of the Raphael command file produced by previous node
## 2. Add new settings or modify old settings 
## 3. Source the 2nd half of the Raphael command file produced by previous node

#setdep @node|Pin_check@

# Source the 1st half of the Raphael command file
source @pwd@/@nodedir|spx@/n@node|spx@_@flow@_RCX_meas_RC_rcfx.tcl

set tdrFileName @pwd@/@nodedir|spx@/n@node|spx@_@flow@_RCX_meas_RC.tdr

# Number of tiles and ambit for capacitance as SWB DOE parameters
option number.of.tiles= $numberOfTiles ambit.size= $ambitSize

# MPI log
option mpi.log

# Multi-threading
math numThreads= @threads@

### DOE Begin #############################
# permittivity
# conductivity

# Contact size (default: 10nm)
set contact_size @cnt_size@

# lumped materials
option lumped.materials = { "Cobalt2 TiN2" "Tungsten1 TiN1 TaN1 TiAlN1" "Cobalt3 TiN3" "Cobalt4 TaN3 Copper2" "Cobalt5 TaN2 Copper"} ;# boundary.contacts

# exclude auto contacts
option exclude.auto.contacts =  { "SiGeB SDexclude" "SiliconN SDexclude" "Gexclude Tungsten1" "Copper CopperExt" "Cobalt5 CopperExt"}

##  Exclude epi-epi and gate-epi capacitance
#   Do Not use newlines to delimit pairs
#if  @excludeC@ == 1
set cap_exclude { "Gexclude SDexclude" "Gexclude SiGeB" "Gexclude SiliconN"}
#endif

### DOE End #############################

refinebox name= metalBulk \
    resistance.only \
    xrefine= 0.002 yrefine= 0.002 zrefine= 0.002 \
    materials= {
                conductors 
}


# Change the output file name to conform to the current node number
set outputFileName n@node@_rcfx

# Source the 2nd half of the Raphael command file
source @pwd@/@nodedir|spx@/n@node|spx@_@flow@_RCX_meas_RC_rcfx.cmd

