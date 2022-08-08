
.option PARHIER = LOCAL
.option ACCT  AUTOSTOP
.option METHOD = trap
.option RUNLVL = 6
.option WL = 1
**.option post
**.option probe=1
**.probe tran v(a1) v(enb) isub(VDD)
.OPTIONS NOMOD NOPAGE INGOLD=2

.temp @sim_temp@
${INCLUDE}

********************************************************************************

* Stimuli   : 
********************************************************************************

.param esup=0.65

vvss VSS 0 dc=0
vvdd VDD 0 dc='esup'
vvbn VBN 0 dc=0
vvbp VBP 0 dc='esup'

${RO_STAGE}

${FULL_RO}

* enable high
.param scalefact='(esup/(esup**esup))**2.5'
venb enb 0 dc='esup' pwl ( 0 0 0.2n 0.0 0.3n "esup"  '10n/scalefact' "esup" '0.2n+10n/scalefact' 0)


* init
.ic v(a1)=0 

.tran .1p '25n/scalefact' sweep esup 0.65 0.65 0.65


.option opfile=1 split_dp=1 delmax=1p absmos=1e-15 abstol=1e-15


.measure tran ro_period trig v(a1) val='esup/2' rise=3
+                       targ v(a1) val='esup/2' rise=4

* stage delay tr+tf = ro_period/N; stage_delay= ro_period/N/2
.measure stage_delay PARAM= 'ro_period/(4-3)/@nstage@/2'

.measure tran trise     trig v(a1) val='esup/2' fall=3
+                       targ v(a2) val='esup/2' rise=3
.measure tran tfall     trig v(a1) val='esup/2' rise=3
+                       targ v(a2) val='esup/2' fall=3

* stage energy
.measure tran t3 trig at=0 targ v(a1) val='esup/2' rise=3
.measure tran t8 trig at=0 targ v(a1) val='esup/2' rise=5
.measure tran iavg1 avg isub(xro5.x1.VDD) from='t3' to='t8' 
.measure stage_energy PARAM= 'iavg1*esup*stage_delay*@nstage@'

.measure tran tlast trig at=0 targ v(a1) val='esup/2' fall=1 reverse
.measure tran ileak0 avg isub(xro5.x1.VDD) from='tlast+10e-9' to='tlast+15e-9'
.measure tran ileak1 avg isub(xro6.x1.VDD) from='tlast+10e-9' to='tlast+15e-9'
.measure tran ileak2 avg isub(xro7.x1.VDD) from='tlast+10e-9' to='tlast+15e-9'
.measure tran ileak3 avg isub(xro8.x1.VDD) from='tlast+10e-9' to='tlast+15e-9'

.measure ileak PARAM='(ileak0+ileak1+ileak2+ileak3)/4'

.end
