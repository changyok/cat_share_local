
.param VDD = 0.00
.param VDNOM = ${VDD_NOM}

* supplys

vvdrain_n  vdrain_n  0 vddval
vvsource_n vsource_n 0 0
vvbulk_n   vbulk_n   0 0

vvdrain_p  vdrain_p  0 vddval*-1
vvsource_p vsource_p 0 0
vvbulk_p   vbulk_p   0 0

vgs gs 0

xmn vdrain_n gs vsource_n vbulk_n  ${N_DEV_NAME}
+ ${N_DOE_STR}
+ nfin=1 rsc_en=0 rdc_en=0
xmp vdrain_p gs vsource_p vbulk_p  ${P_DEV_NAME}
+ ${P_DOE_STR}
+ nfin=1 rsc_en=0 rdc_en=0

.data vddvals vddval 0 ${VDD_LIN} ${VDD_NOM}

.DC vgs '-1.5*VDNOM' '1.5*VDNOM' 0.01 DATA=vddvals

.print i(vvdrain_n) i(vvdrain_p) CGG(xmn.mos) CGG(xmp.mos)


.OPTIONS NOMOD NOPAGE INGOLD=2
.TEMP @sim_temp@


.END
