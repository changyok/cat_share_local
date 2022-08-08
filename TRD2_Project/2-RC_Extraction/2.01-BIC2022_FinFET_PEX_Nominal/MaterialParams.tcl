mater add name=Oxide1 new.like=Oxide
pdbSet Oxide1 Potential Permittivity 3.9
mater add name=Oxide2 new.like=Oxide
pdbSet Oxide2 Potential Permittivity 3.9
mater add name=Oxide3 new.like=Oxide
pdbSet Oxide3 Potential Permittivity 3.9
mater add name=Oxide4 new.like=Oxide
pdbSet Oxide4 Potential Permittivity 3.9
mater add name=Oxide5 new.like=Oxide
pdbSet Oxide5 Potential Permittivity 3.9
mater add name=OxideBOX new.like=Oxide
pdbSet OxideBOX Potential Permittivity 3.9
mater add name=OxidePMD new.like=Oxide
mater add name=OxidePMD2 new.like=Oxide
mater add name=OxideThermal new.like=Oxide
mater add name=Void new.like=Oxide
pdbSet Void Potential Permittivity 1.0
mater add name=SiON new.like=Nitride
pdbSet SiON Potential Permittivity 4.3
pdbSet Nitride Potential Permittivity 4.3
mater add name=Nitride2 new.like=Nitride
mater add name=NitrideARC new.like=Nitride
pdbSet NitrideARC Potential Permittivity 5
mater add name=LowK new.like=Oxide
pdbSet LowK Potential Permittivity 3.0
mater add name=NAPF new.like=Oxide
pdbSet NAPF Potential Permittivity 2.5
mater add name=LowK0 new.like=Oxide
pdbSet LowK0 Potential Permittivity 2.8
mater add name=LowK1 new.like=Oxide
pdbSet LowK1 Potential Permittivity 2.8
mater add name=OxideThermal new.like=Oxide
mater add name=OxideHM new.like=Oxide
mater add name=SOC new.like=Oxide
mater add name=SOG new.like=Oxide
mater add name=ODL new.like=Nitride
mater add name=SiN new.like=Nitride
mater add name=CESL new.like=Nitride
mater add name=SiOC new.like=Oxide
mater add name=BARC new.like=Oxide
mater add name=SiCN new.like=Oxide
mater add name=SiOCN new.like=Oxide

pdbSet OxideThermal Potential Permittivity 5.8
pdbSet HfO2         Potential Permittivity 20
pdbSet Oxide        Potential Permittivity 4.5
pdbSet SiOC         Potential Permittivity 4.5
pdbSet SiOCN        Potential Permittivity 4.5
pdbSet Nitride2     Potential Permittivity 4.5
pdbSet OxidePMD     Potential Permittivity 3
pdbSet OxidePMD2     Potential Permittivity 3


mater add name=AmorphousSilicon new.like=PolySilicon
pdbSet AmorphousSilicon Conductor 1

pdbSet Silicon Conductor 0

mater add name=SiliconSOI new.like=Silicon
pdbSet SiliconSOI Conductor 0

## SiGe channel treated as dielectric
mater add name=SiliconGermanium new.like=Silicon
pdbSet SiliconGermanium Conductor 1
pdbSet SiliconGermanium Potential Conductivity 100000

mater add name=SiliconP new.like=Silicon
pdbSet SiliconP Conductor 1
pdbSet SiliconP Potential Conductivity 100000

mater add name=SiliconN new.like=Silicon
pdbSet SiliconN Conductor 1
pdbSet SiliconN Potential Conductivity 100000

mater add name=SiGeB new.like=Silicon
pdbSet SiGeB Conductor 1
pdbSet SiGeB Potential Conductivity 100000

mater add name=SiGeP new.like=Silicon
pdbSet SiGeP Conductor 1
pdbSet SiGeP Potential Conductivity 100000

mater add name=SDexclude new.like=Silicon
pdbSet SDexclude Conductor 1
pdbSet SDexclude Potential Conductivity 100000

mater add name=PolySilicon new.like=Silicon
pdbSet PolySilicon Conductor 1
pdbSet PolySilicon Potential Conductivity 100000

pdbSet Tungsten Potential Conductivity 179000
pdbSet Aluminum Potential Conductivity 350000
pdbSet Cobalt   Potential Conductivity 166000
pdbSet TiNitride Potential Conductivity 35000
pdbSet TiSi2    Potential Conductivity  55555


# Copper rho at 10nm = 11 uOhm-cm
# Copper rho at 30nm =  5 uOhm-cm
# Copper rho at 40nm =  4 uOhm-cm
# Copper rho at 60nm =  3 uOhm-cm
# Siemens (1/ohm-cm) = rho/uOhm-cm * 1e6
# pdbSet Copper   Potential Conductivity 596000 ;# bulk
pdbSet Copper   Potential Conductivity 250000 ;# Cu 40nm 
mater add name= Copper2 new.like=Copper
pdbSet Copper2   Potential Conductivity 250000

# Extension copper, with 10x conductivity
mater add name= CopperExt new.like=Copper
pdbSet CopperExt   Potential Conductivity 2500000

# Ru rho at 10nm = 15 uOhm-cm
# Ru rho at 20nm = 12 uOhm-cm
# Ru rho at 40nm = 11 uOhm-cm
mater add name= Ru new.like=Tungsten
pdbSet Ru       Potential Conductivity  90909 ;# Ru 40nm

mater add name= Cobalt1 new.like=Cobalt
pdbSet Cobalt1   Potential Conductivity 166000

mater add name= Cobalt2 new.like=Cobalt
pdbSet Cobalt2   Potential Conductivity 166000

mater add name= Cobalt3 new.like=Cobalt
pdbSet Cobalt3   Potential Conductivity 166000

mater add name= Cobalt4 new.like=Cobalt
pdbSet Cobalt4   Potential Conductivity 166000

mater add name= Cobalt5 new.like=Cobalt
pdbSet Cobalt5   Potential Conductivity 166000

mater add name= Tungsten1 new.like=Tungsten
pdbSet Tungsten1 Potential Conductivity 179000

mater add name= Tungsten1UUph new.like=Tungsten
pdbSet Tungsten1UUph Potential Conductivity 179000

mater add name= Tungsten2 new.like=Tungsten
pdbSet Tungsten2 Potential Conductivity 179000

mater add name=TaN new.like=TiNitride
pdbSet TaN      Potential Conductivity  35000

mater add name=TaN1 new.like=TiNitride
pdbSet TaN1     Potential Conductivity  35000

mater add name=TaN2 new.like=TiNitride
pdbSet TaN2     Potential Conductivity  35000

mater add name=TaN3 new.like=TiNitride
pdbSet TaN3     Potential Conductivity  35000

mater add name=TiN1 new.like=TiNitride
pdbSet TiN1     Potential Conductivity  35000

mater add name=TiN2 new.like=TiNitride
pdbSet TiN2     Potential Conductivity  35000

mater add name=TiN3 new.like=TiNitride
pdbSet TiN3     Potential Conductivity  35000

mater add name=Gexclude new.like=TiNitride
pdbSet Gexclude     Potential Conductivity  35000

mater add name=TiAlN new.like=TiNitride
pdbSet TiAlN    Potential Conductivity  35000

mater add name=TiAlN1 new.like=TiNitride
pdbSet TiAlN1   Potential Conductivity  35000

# contact resistivity = 1e-9 ohm*cm2
# TiSi thickness = 2nm 
# TiSi conductivity = 200 Siemens
mater add name=TiSi new.like=TiSi2
pdbSet TiSi    Potential Conductivity 200 

mater add name=T1 new.like=Tungsten
mater add name=T2 new.like=Tungsten
mater add name=T3 new.like=Tungsten
mater add name=T4 new.like=Tungsten
mater add name=T5 new.like=Tungsten

# AMAT wire width-dependent resistivity model.

set resistivity_model_parameters {
    Copper 2.20e4    16.0   800.0 -2.0
    Copper2 2.20e4    16.0   800.0 -2.0
    Cu     2.20e4    16.0   800.0 -2.0
    
    Cobalt  2.00e3    70.0   400.0 -1.0
    Cobalt1 2.00e3    70.0   400.0 -1.0
    Cobalt2 2.00e3    70.0   400.0 -1.0
    Cobalt3 2.00e3    70.0   400.0 -1.0
    Cobalt4 2.00e3    70.0   400.0 -1.0
    Cobalt5 2.00e3    70.0   400.0 -1.0
    Co      2.00e3    70.0   400.0 -1.0
    
    Molybdenum  0   145.0   145.0  0.0
    Mo          0   145.0   145.0  0.0
    
    Tungsten    0   280.0   280.0  0.0
    Tungsten1   0   280.0   280.0  0.0
    Tungsten2   0   280.0   280.0  0.0
    Tungsten3   0   280.0   280.0  0.0
    W           0   280.0   280.0  0.0
    
    TaN         0  4500.0  4500.0  0.0
    TaN1        0  4500.0  4500.0  0.0
    TaN2        0  4500.0  4500.0  0.0
    TaN3        0  4500.0  4500.0  0.0
    
    TiN         0  2000.0  2000.0  0.0
    TiN1        0  2000.0  2000.0  0.0
    TiN2        0  2000.0  2000.0  0.0
    TiN3        0  2000.0  2000.0  0.0
    TiNitride   0  2000.0  2000.0  0.0
    
    TiAlC       0 20000.0 20000.0  0.0
    TiAlC1      0 20000.0 20000.0  0.0
    TiAlC2      0 20000.0 20000.0  0.0
    TiAlC3      0 20000.0 20000.0  0.0
    
    TiAlN       0 20000.0 20000.0  0.0
    TiAlN1      0 20000.0 20000.0  0.0
    TiAlN2      0 20000.0 20000.0  0.0
    TiAlN3      0 20000.0 20000.0  0.0
}
 
# linear dependence
foreach "mat A B C pB" $resistivity_model_parameters {
    mater name= $mat add new.like= Copper
    pdbSet $mat Conductor 1
    pdbSet $mat Potential Conductivity "1.0e7/($B)"
    if {$A!=0} {
    pdbSet $mat Potential Wire.Size.Local 1
	set modelx "($A*(WireSize_x)^$pB+$B)"
	set modely "($A*(WireSize_y)^$pB+$B)"
	set modelz "($A*(WireSize_z)^$pB+$B)"
	set modelF "(($modelx)>($modely)?($modelx):($modely))"
	set modelF "(($modelF)>($modelz)?($modelF):($modelz))"
	set modelF "(($modelF)<($C)?($modelF):($C))"
	pdbSet $mat Potential Conductivity "1.0e7/($modelF)"
    }
}

