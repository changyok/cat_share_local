.param VDD = 0.00
.param VDNOM = @Vdd_nom@

* include models
.inc @pwd@/CORNER_MODELS/@vt_mode@_@corner@_nmos_@sim_temp@.sp
.inc @pwd@/CORNER_MODELS/@vt_mode@_@corner@_pmos_@sim_temp@.sp

* supplies
vvdrain_n  vdrain_n  0 vddval
vvsource_n vsource_n 0 0
vvbulk_n   vbulk_n   0 0

vvdrain_p  vdrain_p  0 vddval*-1
vvsource_p vsource_p 0 0
vvbulk_p   vbulk_p   0 0

vgs gs 0

xmn vdrain_n gs vsource_n vbulk_n  mos3n nfin=1 
xmp vdrain_p gs vsource_p vbulk_p  mos3p nfin=1 

.data vddvals vddval 0.05 @Vdd_nom@

.DC vgs '-1.1*VDNOM' '1.1*VDNOM' 0.01 DATA=vddvals

.print i(vvdrain_n) i(vvdrain_p) 


.OPTIONS NOMOD NOPAGE INGOLD=2 gmin=1e-18  gmindc=1e-18
.TEMP @sim_temp@


.END
