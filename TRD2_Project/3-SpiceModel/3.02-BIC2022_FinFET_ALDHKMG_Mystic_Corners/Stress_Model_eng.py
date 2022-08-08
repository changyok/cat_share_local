#setdep @node|SetupVariables@

import sys, copy
import numpy as np
from scipy.interpolate import UnivariateSpline
from scipy.optimize import least_squares

if "@Type@" == "tbc" or "@midpoint@" != "True":
	sys.exit()

# Device physical parameters
tfin              = @tfin@					# Physical fin thickness [m]
hfin              = @hfin@					# Physical fin height [m]
lgate		  = @lgate@
dtype             = "@Type@"
tnom		  = @tnom@
vdd               = @Vdd_nom@
vdlin             = @Vdd_lin@
avgStrains        = "@avgStrains@".split()
avgStrainNom      = float(@avgStrainNom@)

# terminal mapping
drain_con 	= "@drain_con@"
gate_con 	= "@gate_con@"
source_con	= "@source_con@"
bulk_con	= "@bulk_con@"

## do not need to run this because there is no strain dependence data
if len(avgStrains) < 2 : 
	if float(avgStrains[0]) != float(avgStrainNom): raise Exception(f"Strain information is wrong!!")
	print(f"DOE: stress_vt 0.0")
	print(f"DOE: stress_cur 0.0")
	sys.exit()

## read the data
strain_hd_data_list = list()
strain_ld_data_list = list()
strain_list = list()
strain_Vt_list = list()
for st in avgStrains:
	if float(st) != avgStrainNom:
		data = Data.from_db(dvar=f'i{drain_con}',  ivar=f'v{gate_con}',  bias={f"{drain_con}":vdd}, dtype=dtype, instances={"l":lgate, "avgStrain":float(st)}, tfin=tfin, temperature=tnom)
		strain_Vt_list.append(data[0].Vt())
		strain_hd_data_list.append(data)
		strain_list.append(float(st))
		data = Data.from_db(dvar=f'i{drain_con}',  ivar=f'v{gate_con}',  bias={f"{drain_con}":vdlin}, dtype=dtype, instances={"l":lgate, "avgStrain":float(st)}, tfin=tfin, temperature=tnom)
		strain_ld_data_list.append(data)

## read the data (nominal strain)
Nomstrain_hd = Data.from_db(dvar=f'i{drain_con}',  ivar=f'v{gate_con}',  bias={f"{drain_con}":vdd}, dtype=dtype, instances={"l":lgate, "avgStrain":float(avgStrainNom)}, tfin=tfin, temperature=tnom)
Vt_nom = Nomstrain_hd[0].Vt()
Nomstrain_ld = Data.from_db(dvar=f'i{drain_con}',  ivar=f'v{gate_con}',  bias={f"{drain_con}":vdlin}, dtype=dtype, instances={"l":lgate, "avgStrain":float(avgStrainNom)}, tfin=tfin, temperature=tnom)

##x[0] = DeltaVt, x[1] = Idboost
# just calculate error from two points
def fun_error(x):
	out = list()
	fnom_hd = UnivariateSpline(Nomstrain_hd[0].index.values, np.log10(np.abs(Nomstrain_hd[0][f"i{drain_con}"].values)), s=0, k=2, ext=0)
	fnom_ld = UnivariateSpline(Nomstrain_ld[0].index.values, np.log10(np.abs(Nomstrain_ld[0][f"i{drain_con}"].values)), s=0, k=2, ext=0)
	for hd, ld, s in zip(strain_hd_data_list,strain_ld_data_list,strain_list):
		## high drain
		fstrain = UnivariateSpline(hd[0].index.values, np.log10(np.abs(hd[0][f"i{drain_con}"].values)), s=0, k=2, ext=0)
		## high gate
		newi_strain = (10**fstrain(vdd))
		newi_nom = 10**fnom_hd(vdd+(x[0]*(s - avgStrainNom)))*(x[1]*(s-avgStrainNom)+1.0)
		out.append((newi_nom-newi_strain)/newi_nom)
		## low gate
		newi_strain = 10**fstrain(0.0)
		newi_nom = 10**fnom_hd((x[0]*(s - avgStrainNom)))*(x[1]*(s-avgStrainNom)+1.0)
		out.append((newi_nom-newi_strain)/newi_nom)

		## low drain
		fstrain = UnivariateSpline(ld[0].index.values, np.log10(np.abs(ld[0][f"i{drain_con}"].values)), s=0, k=2, ext=0)
		## high gate
		newi_strain = (10**fstrain(vdd))
		newi_nom = 10**fnom_ld(vdd+(x[0]*(s - avgStrainNom)))*(x[1]*(s-avgStrainNom)+1.0)
		out.append((newi_nom-newi_strain)/newi_nom)
		## low gate
		newi_strain = 10**fstrain(0.0)
		newi_nom = 10**fnom_ld((x[0]*(s - avgStrainNom)))*(x[1]*(s-avgStrainNom)+1.0)
		out.append((newi_nom-newi_strain)/newi_nom)	
	return np.array(out)

## initial value
x0 = [(Vt_nom-strain_Vt_list[0])/(strain_list[0]-avgStrainNom), 0.0]
res = least_squares(fun_error, x0)

print(f"DOE: stress_vt {res.x[0]}")
print(f"DOE: stress_cur {res.x[1]}")
