# User settings for Process Explorer (meas_RC) and Raphael

### Settings used by meas_RC
### Variable names are exact and case sensitive
### 
set keyGenCnt 0 ;# 0|1
set keyTdrOnly 1 ;# 0|1
set raphaelBinaryForPE "/slowfs/tprod5/geelhaar/raphael_fx/R-2020.09/bin/raphael_fx rcfx"
set allowMatParamsFromPEDB 0 ;# 0|1
set allowMatParamsFromFile 1 ;# 0|1
set allowMatParamsFromMeasRC 0 ;# 0|1
set materialParamsFile MaterialParams.tcl
set splitRaphaelCommand 1 ;# 0|1
set backwardCompatible 0 ;# 0|1
set refineContact 1 ;# 0|1
set autoTilingForCapacitance 1 ;# 0|1
set autoTilingTileSize 0.2
set autoTilingAmbitSize 0.10


### Settings used by Raphael
###

# Info level
pdbSet InfoDefault 1

# Interface refinement
# pdbSet Grid SnMesh min.normal.size 0.005
# Clear all default refineboxes
refinebox clear

# Interface refinement
refinebox name= metalInterface \
    resistance.only \
    min.normal.size= 0.002 \
    interface.materials= {
        Tungsten Tungsten1 Tungsten2
        TiNitride 
        TiN1 TiN2 TaN1 TiAlN1 TiSi
        Cobalt Cobalt2
        Copper
        Ru
        SiliconN SiliconP SiGeB SiGe 
    }
refinebox name= dielectricInterface \
    capacitance.only \
    min.normal.size= 0.002 \
    interface.materials= {
        Silicon 
        Oxide Oxide2 OxidePMD OxidePMD2 OxideThermal 
        SiON HfO2 LowK0 LowK Nitride Nitride2 Void
        BARC 
    }


# Contact size
set contact_size 0.010
set contact_offset 0.001

# Contact refinement
set contact_refine_size 0.015
set contact_refine_offset 0.005
set contact_refine 0.002

# Material groups
# Interface contacts are automatically generated at group interfaces for distributed RC network  
option lumped.materials= {
    "Tungsten1 TiN1 TiAlN1" 
    "Tungsten2 TiN2 TiAlN2" 
    "Tungsten TaN" 
    "SiliconP" 
    "SiliconN" 
    "Copper TaN1" 
    "Cobalt TaN2"
}

