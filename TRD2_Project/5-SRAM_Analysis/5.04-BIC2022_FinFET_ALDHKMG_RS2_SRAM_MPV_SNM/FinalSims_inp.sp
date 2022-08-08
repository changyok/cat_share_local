* icrit sweep

.param supply=${vddc}
.param peri=${vddp}
.param sweep_voltage=0

${MPV_params}

${INC_FILE}

**.SUBCKT array BLBD BLBU BLD BLU VDD VSS WLL WLR VBP VBN
xSRAM BLBD BLBU BLD BLU VDD VSS WLL WLR VBP VBN @cell@


* bias
vvdd    vdd     0       'supply'
vvss    vss     0       0
vvbp    VBP     0       'supply'
vvbn    VBN     0       0


* stim
vwl     wll     0       'supply'
vnbl    blbu    0       'peri'
vbl     blu     0       'peri'

vsmu    xsram.@__Q__@  0  'sweep_voltage'

.OPTIONS NOMOD NOPAGE INGOLD=2 AUTOSTOP measdgt=8 runlvl=6 method=gear maxord=2 REDEFSUB=1 

.dc sweep sweep_voltage 0 'supply' 0.005

.print '-1*i(vsmu)' v(xsram.@__NQ__@)

.meas dc Vzero find v(xsram.@__Q__@) when i(vsmu)=0 cross=1
.meas dc Vtrip find v(xsram.@__Q__@) when i(vsmu)=0 cross=2
.meas dc Vcrit param="Vzero-Vtrip"
.meas dc icr   min  i(vsmu) from="Vzero" to="Vtrip"
.meas dc icrit0 param="-1*icr"
.meas dc Pcr   integ  i(vsmu) from="Vzero" to="Vtrip"
.meas dc Pcrit param="-1*Pcr"

.temp @sim_temp@

.alter opposite sweep

vsmu    xsram.@__NQ__@  0  'sweep_voltage'
.print '-1*i(vsmu)' v(xsram.@__Q__@)

.meas dc Vzero find v(xsram.@__NQ__@) when i(vsmu)=0 cross=1
.meas dc Vtrip find v(xsram.@__NQ__@) when i(vsmu)=0 cross=2

.end


