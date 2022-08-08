import numpy as np
import pandas as pd
import math, copy
pd.set_option('display.max_columns', 4)

def cal_Vth_shift_Ioff(dev_name, IdVg_list, Ioff_target, drain_con, previous_vth_shift, pMOS=False):
	out_vth_shift = list()
	for IdVg, target, p_vth_shift in zip(IdVg_list, Ioff_target, previous_vth_shift):
		temp_df = pd.DataFrame({"Vg":IdVg[0].index.values, "Id": np.log10(np.abs(IdVg[0][f'i{drain_con}-fit'].values))})
		temp_df.sort_values(by=["Vg"], inplace=True)
		Vg = temp_df["Vg"].values
		Id = temp_df["Id"].values
		print(temp_df)
		
		if pMOS:
			slope = -1.0*(Id[-1]-Id[-2])/(Vg[-1]-Vg[-2])
			intercept = Id[-1]-slope*Vg[-1]
		else:
			slope = (Id[1]-Id[0])/(Vg[1]-Vg[0])
			intercept = Id[0]-slope*Vg[0]

		if math.log10(abs(target)) < min(Id): # extrapolation
			out_vth_shift.append((math.log10(abs(target))-intercept)/slope + p_vth_shift)
		else: # interpolation
			if pMOS:	out_vth_shift.append(IdVg[0].Vt(ic=abs(target), col='fit')*-1.0  + p_vth_shift)
			else:		out_vth_shift.append(IdVg[0].Vt(ic=abs(target), col='fit')  + p_vth_shift)

	return out_vth_shift

def cal_Vth_shift_Ion(dev_name, IdVg_list, Ion_target, Idsat_ratio, drain_con, Vdd, previous_vth_shift, pMOS=False):
	out_vth_shift = list()
	for name, IdVg, ion_t, p_vth_shift in zip(dev_name, IdVg_list, Ion_target, previous_vth_shift):
		current_ion_tcad = max( np.abs(IdVg[0][f'i{drain_con}'].values) )
		current_ion = max( np.abs(IdVg[0][f'i{drain_con}-fit'].values) )

		temp_df = pd.DataFrame({"Vg":IdVg[0].index.values, "Id": np.abs(IdVg[0][f'i{drain_con}-fit'].values)})
		temp_df.sort_values(by=["Vg"], inplace=True)
		Vg = temp_df["Vg"].values
		Id = temp_df["Id"].values

		if pMOS:
			slope = (Id[0]-Id[1])/(Vg[0]-Vg[1])
			intercept = Id[0]-slope*Vg[0]
			target = abs(ion_t/Idsat_ratio)
		else:
			slope = (Id[-1]-Id[-2])/(Vg[-1]-Vg[-2])
			intercept = Id[-1]-slope*Vg[-1]
			target = abs(ion_t*Idsat_ratio)
		
		if target > current_ion_tcad: print(f"WARNING: Because {name}'s target {target} is larger than Ion of TCAD data {current_ion_tcad}, extrapolation will be performed to estimate the ON-state current. This may not be correct.") 
		if target <= current_ion : ## interpolation
			if pMOS:
				out_vth_shift.append( Vdd - IdVg[0].Vt(ic=target, col='fit') + p_vth_shift )
			else:
				out_vth_shift.append( IdVg[0].Vt(ic=target, col='fit') - Vdd + p_vth_shift )
		else: ## extrapolation
			if pMOS:
				out_vth_shift.append( Vdd - (target-intercept)/slope + p_vth_shift )
			else:
				out_vth_shift.append( (target-intercept)/slope - Vdd + p_vth_shift )

	return out_vth_shift
			
def run_HSPICE(IdVg_list, dev_name, Model, vth_shift, Vdd):
	out_ion = list()
	out_ioff = list()
	for name, IdVg, shift in zip(dev_name, IdVg_list, vth_shift):
		## add (modify) the metadata
		IdVg[0].metadata['instances']['vtmode_adjust']=shift
		## run HSPICE
		ExtractionUtils.PrintErrors(name, IdVg, Simulator, Model, "rmsd")
		## save the result to PLT
		if Vdd > 0: IdVg.WritePLTFile(f'@pwd@/@nodedir@/n@node@-nmos-{name}')
		else: IdVg.WritePLTFile(f'@pwd@/@nodedir@/n@node@-pmos-{name}')

		out_ion.append( abs(IdVg[0].Ion(v=Vdd, col="fit", log=False, extrapolate=False)) )
		out_ioff.append( abs(IdVg[0].Ioff(v=0.0, col="fit", log=False, extrapolate=False)) )
	out_df = pd.DataFrame({"Vth_shift":vth_shift,"Ioff":out_ioff, "Ion":out_ion}, index=dev_name)
	return out_df

def cal_max_err(target, data):
	if len(target) != len(data): raise Exception(f"The length of two inputs must be the same.")
	err_list = list()
	for t, d in zip(target, data):
		err_list.append( abs(t-d)/t )
	return max(err_list)*100 # unit %

def check_target(target):
	if target not in ["Ioff", "Ion"]: return False
	return True

def nMOS_Vt_shift(target, target_value, dev_name, IdVg_HD_nmos, Model_nmos, MaxIter, Err_target, vdd_nom, Idsat_ratio):
	if check_target(target) == False: raise Exception(f"target ({target}) must be either Ioff or Ion")

	Vth_shift_nmos = [0.0]*len(dev_name)
	IdVg_nmos = list()
	for i in range(len(dev_name)):	IdVg_nmos.append(copy.deepcopy(IdVg_HD_nmos))

	for i in range(MaxIter):
		## calculate the Vth shift for nMOS
		if target == "Ioff":
			Vth_shift_nmos = cal_Vth_shift_Ioff(dev_name, IdVg_nmos, target_value, f"n{drain_con}", Vth_shift_nmos)
		elif target == "Ion":
			Vth_shift_nmos = cal_Vth_shift_Ion(dev_name, IdVg_nmos, target_value, Idsat_ratio, f"n{drain_con}", vdd_nom, Vth_shift_nmos)
		else:
			raise Exception("Please check the nMOS target. It should be either Ion or Ioff")

		print("NMOS Vt shift: ")
		for name, value in zip(dev_name, Vth_shift_nmos):
			print(f"   {name}\t\t{value}")

		## Run HSPICE simulation with Vth shift 
		nMOS_result = run_HSPICE(IdVg_nmos, dev_name, Model_nmos, Vth_shift_nmos, vdd_nom)
		if target == "Ioff":
			nMOS_result["Ioff_target"] = target_value
		elif target == "Ion":
			nMOS_result["Ion_target"] = target_value*Idsat_ratio

		print("nMOS result :")
		print(nMOS_result)

		if target == "Ioff":
			err = cal_max_err(target_value, nMOS_result["Ioff"].values)
		elif target == "Ion":
			err = cal_max_err(target_value*Idsat_ratio, nMOS_result["Ion"].values)

		if err < Err_target: 
			print(f"  Shifting Vth for nMOS is done. (error {err:.2f} % < target error {Err_target} %)")
			break
		else: 
			if i == MaxIter-1: print(f"  WARNING: {target} from HSPICE is still far from target (error = {err:.2f} %, target = {Err_target} %)")
			else:	print(f"  {target} from HSPICE is far from target (error = {err:.2f} %). So recaculate the Vth shift")
	return Vth_shift_nmos, nMOS_result

def pMOS_Vt_shift(target, target_value, dev_name, IdVg_HD_pmos, Model_pmos, MaxIter, Err_target, vdd_nom, Idsat_ratio):
	if check_target(target) == False: raise Exception(f"target ({target}) must be either Ioff or Ion")

	Vth_shift_pmos = [0.0]*len(dev_name)
	IdVg_pmos = list()
	for i in range(len(dev_name)): 	IdVg_pmos.append(copy.deepcopy(IdVg_HD_pmos))

	for i in range(MaxIter):
		## calculate the Vth shift for pMOS
		if target == "Ion": ## Ion nMOS_result["Ion"].values
			Vth_shift_pmos = cal_Vth_shift_Ion(dev_name, IdVg_pmos, target_value, Idsat_ratio, f"p{drain_con}", -vdd_nom, Vth_shift_pmos, pMOS=True)
		elif target == "Ioff" : ## Ioff
			Vth_shift_pmos = cal_Vth_shift_Ioff(dev_name, IdVg_pmos, target_value, f"p{drain_con}", Vth_shift_pmos, pMOS=True)
		else:
			raise Exception("Please check the pMOS target. It should be either Ion or Ioff")

		## print the Vt shift result
		print("PMOS Vt shift: ")
		for name, value in zip(dev_name, Vth_shift_pmos):
			print(f"   {name}\t\t{value}")

		## Run HSPICE simulation with Vth shift 
		pMOS_result = run_HSPICE(IdVg_pmos, dev_name, Model_pmos, Vth_shift_pmos, -vdd_nom)

		if target == "Ion": ## Ion
			pMOS_result["Ion_target"] = target_value/Idsat_ratio
		elif target == "Ioff": ## Ioff
			pMOS_result["Ioff_target"] = target_value

		print("pMOS result :")
		print(pMOS_result)

		if target == "Ion": ## Ion
			err = cal_max_err(target_value/Idsat_ratio, pMOS_result["Ion"].values)
		elif target == "Ioff": ## Ioff
			err = cal_max_err(target_value, pMOS_result["Ioff"].values)

		if err < Err_target: 
			print(f"  Shifting Vth for pMOS is done. (error {err:.2f} % < target error {Err_target} %)")
			break
		else: 
			if i == MaxIter-1: print(f"  WARNING: {target} from HSPICE is still far from target (error = {err*100:.2f} %, target = {Err_target} %)")
			else:	print(f"  {target} from HSPICE is far from target (error = {err:.2f} %). So recaculate the Vth shift")
	return Vth_shift_pmos, pMOS_result

def get_modelcard_file_name(devtype, vtmode, metadata_dic, key_params):
	out = devtype+"_"+vtmode
	for key in key_params:
		out = out + "_"+key+str(metadata_dic[key])
	return out

def save_model_card(nMOS_result, pMOS_result, key_params):
	if (nMOS_result.index.values == pMOS_result.index.values).all() == False:
		raise Exception("The number of vt_modes in nMOS and pMOS are different!")
	vtmode_list = nMOS_result.index.values
	nMOS_vthshift = nMOS_result["Vth_shift"].values
	pMOS_vthshift = pMOS_result["Vth_shift"].values

	for vtmode, nMOS_vth, pMOS_vth in zip(vtmode_list, nMOS_vthshift, pMOS_vthshift):
		for devtype in ["nMOS", "pMOS"]:
			mos_list = mdb.get_project(swb__Type=devtype, swb__tool_label="Mystic_Response_Surface")
			if type(mos_list) is not list: mos_list = [mos_list]
			for mos in mos_list:
				## grap model card
				mosModel = mdb.GetFitModel(dataset=f"{mos.name}-RSM", project=mos.name)
				if devtype == "nMOS":
					mosModel.SetModelParameter(f'phigvar', nMOS_vth)
				else:
					mosModel.SetModelParameter(f'phigvar', pMOS_vth)
				## get file name
				fname = get_modelcard_file_name(devtype, vtmode, mos.metadata["swb"], key_params)
				mosModel.WriteModel(f"@pwd@/@nodedir@/{fname}.sp")


# ----------- PARAMETRISATION FROM GLOBAL AND SPLIT OPTIONS, OR DEFAULTS -----------

# Set Ioff target (A)
vt_modes = {"svt":3e-12, "lvt":0.5e-9, "ulvt":2.0e-9}

Err_target = 1.0 # the target error %
MaxIter = 5 # the maximum number of iterations

# Idsat ratio: if Idsat_ratio > 1: Idsat of PMOS is larger than that of NMOSs
Idsat_ratio = @Idsat_ratio@
if Idsat_ratio <= 0.0 : raise Exception(f"Idsat_ratio ({Idsat_ratio}) must be larger than 0.0")

# Device split parameters
tfin_n            = @tfin@					# Physical fin thickness [m] nMOS
hfin              = @hfin@					# Physical fin height [m]
lgate		  = @lgate@
key_params	  = ["lgate", "tfin"]			# Structural varaition parameter names to print the model cards.

# other parameters
wf0               = @workfn@					# workfunction
tnom		  = @tnom@

# Bias parameters
vdd_nom           = @Vdd_nom@					# Supply Voltage [V]
avgStressNom_n      = @avgStrainNom@
avgStressNoms      = list(set("@avgStrainNom:all@".split()))

# pMOS target
pMOS_target = "@pMOS_target@"
nMOS_target = "@nMOS_target@"

if pMOS_target == "Ioff" and nMOS_target == "Ioff" : Vth_shift_mode = 0
elif pMOS_target == "Ion" and nMOS_target == "Ioff" : Vth_shift_mode = 1
elif pMOS_target == "Ioff" and nMOS_target == "Ion" : Vth_shift_mode = 2
else:
	raise Exception(f"WARNING: pMOS_target and nMOS_targer must be either Ioff or Ion. And pMOS_target==nMOS_target==Ion is not acceptable")


## find the averageStress nominal value
if 'tbc' in avgStressNoms: avgStressNoms.remove('tbc')

if len(avgStressNoms) > 1:
	if float(avgStressNoms[0]) == avgStressNom_n: avgStressNom_p = float(avgStressNoms[1])
	else: avgStressNom_p = float(avgStressNoms[0])
else: avgStressNom_p = avgStressNom_n

## find the tFin for pMOS (nominal tFin values for nMOS and pMOS are different)
type_list = "@Type:all@".split()
tFin_list = "@tfin:all@".split()
tfin_df = pd.DataFrame({"type":type_list, "tFin": tFin_list})
tfin_df = tfin_df[ tfin_df["type"] == "pMOS" ]
tfs = [float(v) for v in list(set(tfin_df['tFin'].values))]
tfs.sort()
middle_index = int(len(tfs)/2)
tfin_p = tfs[middle_index]

# Set Mystic project and output label for this stage of the flow
mysticProjectName = "@node@"					# Name of Mystic project in database

# terminal mapping
drain_con 	= "@drain_con@"[1:]
gate_con 	= "@gate_con@"[1:]
source_con	= "@source_con@"[1:]
bulk_con	= "@bulk_con@"

ErrorMethod = "rmsd"

## find the project
nmos_node_prj = mdb.get_project(swb__Type="nMOS", \
                               swb__tool_label="Mystic_Response_Surface", \
                               swb__midpoint="True")
pmos_node_prj = mdb.get_project(swb__Type="pMOS", \
                               swb__tool_label="Mystic_Response_Surface", \
                               swb__midpoint="True")

## load model cards
Model_nmos = mdb.GetFitModel(dataset=f"{nmos_node_prj.name}-RSM", project=nmos_node_prj.name)
Model_pmos = mdb.GetFitModel(dataset=f"{pmos_node_prj.name}-RSM", project=pmos_node_prj.name)

if @skip@ == True:
	## upload the Vth shift results to DB
	prj = mdb.get_project("@node@")
	prj.metadata['vtmode_adjust']={}

	mode_name = "lvt"
	prj.metadata['vtmode_adjust'][mode_name]={}
	prj.metadata['vtmode_adjust'][mode_name]['nmos']=0.0
	prj.metadata['vtmode_adjust'][mode_name]['pmos']=0.0
	prj.save()


	## save models for each VT model to disk
	nMOS_result = pd.DataFrame({"Vth_shift":[0.0]}, index=[mode_name])
	pMOS_result = pd.DataFrame({"Vth_shift":[0.0]}, index=[mode_name])
	save_model_card(nMOS_result, pMOS_result, key_params)

else:

	## load Id-Vg curves
	IdVg_HD_nmos	= mdb.Load(dvar=f'in{drain_con}',  ivar=f'vn{gate_con}',  dtype="nMOS", instances={"l":lgate, "avgStrain":avgStressNom_n}, tfin=tfin_n, temperature=tnom, bias={f"n{drain_con}":vdd_nom})
	IdVg_HD_pmos	= mdb.Load(dvar=f'ip{drain_con}',  ivar=f'vp{gate_con}',  dtype="pMOS", instances={"l":lgate, "avgStrain":avgStressNom_p}, tfin=tfin_p, temperature=tnom, bias={f"p{drain_con}":-1.0*vdd_nom})


	## run HSPICE (initial)
	IdVg_HD_nmos[0].metadata['instances']['vtmode_adjust']=0.0
	ExtractionUtils.PrintErrors("HSPICE", IdVg_HD_nmos, Simulator, Model_nmos, ErrorMethod)
	IdVg_HD_pmos[0].metadata['instances']['vtmode_adjust']=0.0
	ExtractionUtils.PrintErrors("HSPICE", IdVg_HD_pmos, Simulator, Model_pmos, ErrorMethod)

	dev_name = list(vt_modes.keys())
	ioff_target = list(vt_modes.values())

	if Vth_shift_mode == 0 or Vth_shift_mode == 1:
		## nMOS
		print("\n-----nMOS-----")
		Vth_shift_nmos, nMOS_result = nMOS_Vt_shift("Ioff", ioff_target, dev_name, IdVg_HD_nmos, Model_nmos, MaxIter, Err_target, vdd_nom, Idsat_ratio)

		## pMOS
		print("\n-----pMOS-----")
		if Vth_shift_mode == 0:
			Vth_shift_pmos, pMOS_result = pMOS_Vt_shift("Ioff", ioff_target, dev_name, IdVg_HD_pmos, Model_pmos, MaxIter, Err_target, vdd_nom, Idsat_ratio)
		else: 
			Vth_shift_pmos, pMOS_result = pMOS_Vt_shift("Ion", nMOS_result["Ion"].values, dev_name, IdVg_HD_pmos, Model_pmos, MaxIter, Err_target, vdd_nom, Idsat_ratio)
	else:
		## pMOS
		print("\n-----pMOS-----")
		Vth_shift_pmos, pMOS_result = pMOS_Vt_shift("Ioff", ioff_target, dev_name, IdVg_HD_pmos, Model_pmos, MaxIter, Err_target, vdd_nom, Idsat_ratio)

		## nMOS
		print("\n-----nMOS-----")
		Vth_shift_nmos, nMOS_result = nMOS_Vt_shift("Ion", pMOS_result["Ion"].values, dev_name, IdVg_HD_nmos, Model_nmos, MaxIter, Err_target, vdd_nom, Idsat_ratio)

	print("\n------------------------")
	print("Final results:")
	print(" nMOS")
	print(nMOS_result)
	print(" pMOS")
	print(pMOS_result)

	## upload the Vth shift results to DB
	prj = mdb.get_project("@node@")
	prj.metadata['vtmode_adjust']={}
	for name, value in zip(dev_name, Vth_shift_nmos):
		prj.metadata['vtmode_adjust'][name]={}
		prj.metadata['vtmode_adjust'][name]['nmos']=value
	for name, value in zip(dev_name, Vth_shift_pmos):
		prj.metadata['vtmode_adjust'][name]['pmos']=value
	prj.save()


	## save models for each VT model to disk
	save_model_card(nMOS_result, pMOS_result, key_params)


