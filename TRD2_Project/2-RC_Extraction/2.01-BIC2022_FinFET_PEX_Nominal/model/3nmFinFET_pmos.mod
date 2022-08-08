* Sub-circuit definition
.subckt mos14p d g s b l=1e-08 nfin=1 rgc_en=1 rdc_en=1 rsc_en=1 tfinin=4e-09 strain_dep=0 lod=0 diffedge=0

******************* Calculate strain dependence based on tfin+lod+diffedge  ***********************
.PARAM i_boost_factor  = '8.69e7*tfinin-0.127' 

.PARAM lod_fac  = 'lod/300e-9' 
.PARAM diffedge_fac  = 'diffedge/45e-9' 
.PARAM strain_LLE_dep  = '(1-(1/(lod_fac+1)**2))*(1-(1/(diffedge_fac+1)**2.5))' 

.PARAM boostfactor  = '1+(i_boost_factor*strain_LLE_dep)*strain_dep' 
.PARAM vt_adder  = 'strain_LLE_dep*0.070*strain_dep' 

******************* section to handle contact resistance based on L ***********************
.PARAM resistivity  = 1e-9 
.PARAM l_contact_nom  = 16e-9 
.PARAM l_gate_nom  = 16e-9 
.PARAM delta_l  = 'l_gate_nom-l' 
.PARAM l_contact  = '(l_contact_nom+(delta_l/2))*100' 
.PARAM w_contact  = '16e-9*100' 
.PARAM rgc  = 0 
.PARAM rgc_fin  = rgc*rgc_en 
.PARAM rsc  = 'resistivity/(l_contact*w_contact)' 
.PARAM rsc_fin  = rsc*rsc_en 
.PARAM rdc  = 'resistivity/(l_contact*w_contact)' 
.PARAM rdc_fin  = rdc*rdc_en 
******************* section to handle contact resistance based on L ***********************

rd d d_i rdc_fin 
rs s s_i rsc_fin 
rg g g_i rgc_fin 

mos d_i g_i s_i b mosmod l=l nfin=nfin u0mult='boostfactor' delvtrand='vt_adder' 

.model mosmod PMOS
+DEVTYPE=0
+EASUB=4.1312
+NI0SUB=4.3638e+16
+BG0SUB=1.0379
+NC0SUB=2.0734e+25
+PHIG=4.72542
+RDSW=30
+RDSWMIN=0
+CDSCD=0.01
+VSAT=130000
+UA=0.3
+PDIBL2=0.000272548
+PCLM=1e-09
+PCLMG=0.1
+CHARGEWF=0
+level=72
+VERSION=108
+BULKMOD=1
+CAPMOD=1
+IGCMOD=0
+IGBMOD=0
+GIDLMOD=0
+COREMOD=0
+GEOMOD=1
+CGEOMOD=0
+IIMOD=0
+RDSMOD=0
+TNOM=25
+XL=0
+LINT=0
+LL=0
+LLC=0
+LLN=1
+DLC=0
+EOT=8e-10
+TFIN='tfinin'
+HFIN=5e-08
+FPITCH=3e-08
+FECH=1
+NF=1
+NFIN=1
+NBODY=2e+24
+NSD=2e+26
+NGATE=0
+LPHIG=0
+LRDSW=0
+ARDSW=0
+BRDSW=1e-08
+PRWG=0
+CIT=0
+CDSC=0.109577
+LCDSC=0
+LCDSCD=0
+DVT0=0
+LDVT0=0
+DVT1=0.7
+LDVT1=0
+PHIN=0
+LPHIN=0
+ETA0=0
+DVTP0=-0.143712
+DVTP1=1
+LETA0=0
+DSUB=1.06
+LDSUB=0
+K1RSCE=0
+LK1RSCE=0
+LPE0=0
+LLPE0=0
+QMFACTOR=1
+QM0=0.001
+LVSAT=0
+AVSAT=0
+BVSAT=6e-08
+AVSAT1=0
+BVSAT1=6e-08
+KSATIV=8.11952
+LKSATIV=0
+DELTAVSAT=1
+MEXP=2
+LMEXP=0
+AMEXP=0
+BMEXP=1
+PTWG=0
+LPTWG=0
+APTWG=0
+BPTWG=6e-08
+U0=0.00596109
+LU0=0
+ETAMOB=2
+UP=0
+LUP=0
+LPA=1
+LUA=0
+AUA=0
+BUA=6e-08
+EU=1
+LEU=0
+UD=0
+LUD=0
+AUD=0
+BUD=5e-08
+UCS=1
+LUCS=0
+PDIBL1=1e-09
+LPDIBL1=0
+LPDIBL2=0
+DROUT=1.06
+LDROUT=0
+PVAG=1
+LPVAG=0
+LPCLM=0
+CFS=0
+CGSL=1e-20
.ends
