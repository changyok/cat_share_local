
models_path="@pwd@/../5.01-BIC2022_FinFET_ALDHKMG_RS2_SRAM_Corners_TX/CORNER_MODELS"

nmos_mod = f"{models_path}/@vt_mode@_@corner@_nmos_@sim_temp@.sp"
pmos_mod = f"{models_path}/@vt_mode@_@corner@_pmos_@sim_temp@.sp"

#set nmos_mod tbc
print(f"DOE: nmos_mod {nmos_mod}")
#set pmos_mod tbc
print(f"DOE: pmos_mod {pmos_mod}")
