* icrit sweep

.param supply=@vddc@
.param peri=@vddp@
.param sweep_voltage=0

#set __Q__  iQ1:p1d
#set __NQ__  iQ2:p1g
#set __BL__ blu
#define __Q__  iQ1:p1d 
#define __NQ__  iQ2:p1g
#define __BL__ blu

${MPV_params}

${INC_FILE}

**.SUBCKT array BLBD BLBU BLD BLU VDD VSS WLL WLR VBP VBN
xSRAM BLBD BLBU BLD BLU VDD VSS WLL WLR VBP VBN @cell@:RAND


* bias
vvdd    vdd     0       'supply'
vvss    vss     0       0
vvbp    VBP     0       'supply'
vvbn    VBN     0       0


* stim
vwl     wll     0       'supply'
vnbl    blbu    0       'peri'
vbl     blu     0       'peri'

* assume Q is connected to bl
.ic v(xsram.__Q__)=0.0

.OPTIONS NOMOD NOPAGE INGOLD=2 AUTOSTOP measdgt=8 runlvl=6 method=gear maxord=2 REDEFSUB=1 

.dc sweep peri 0 '@vddp@' @vddp@

.meas dc iread find '-1*i(vbl)' when v(__BL__)=@vddp@ cross=1

.end


