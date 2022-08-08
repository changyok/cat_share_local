.subckt mos3p d g s b l_fs=1.28056e-08 nfin=1 rgc_en=1 rdc_en=0 rsc_en=0 delvtrand0=0 vtmode_adjust=-0.0264932 avgStrain=-2.5 gen_mosmod_cdsc=0.00204902 gen_mosmod_cdscd=1.27243e-05 gen_mosmod_cfd=-3.471e-12 gen_mosmod_cfs=-3.471e-12 gen_mosmod_dlc=-4.78233e-10 gen_mosmod_dvtp0=-0.0132579 gen_mosmod_hfin=1.32349e-23 gen_mosmod_phig=-3.00029e-05 gen_mosmod_tfin=1.11115e-10 gen_mosmod_u0=0.000811647 gen_mosmod_ua=-4.02978e-10 gen_mosmod_vsat=-3670.3 gen_phigvar=0.005 tfin=5.11112e-09 phigvar=0.005
.param r_gc = 0
.param rgc_fin = 'r_gc/nfin*rgc_en'
.param r_sc = 0
.param rsc_fin = 'r_sc/nfin*rsc_en'
.param r_dc = 0
.param rdc_fin = 'r_dc/nfin*rdc_en'

rd d d_i rdc_fin
rs s s_i rsc_fin
rg g g_i rgc_fin

* to inject extra VT variation
.param phigvar = "0 + gen_phigvar"
* stress effects (Vt)
.param strain_nom = -2.5
.param slope_vt_strain = 0
.param vtshift_strain = '-1.0*slope_vt_strain*(avgStrain-strain_nom)'
* stress effects (Idboost)
.param slope_id_strain = 0
.param idboost_strain = 'slope_id_strain*(avgStrain-strain_nom)+1.0'
* calculate final VT deltas
.param final_delvtrand = "delvtrand0 + vtmode_adjust + phigvar + vtshift_strain"
.param logvsat1 = 5.30076
.param logpdibl2 = -3.85543
.param logmexp = 0.276462
.param logptwg = 0.3
mos d_i g_i s_i b mosmod l='l_fs' nfin=nfin delvtrand=final_delvtrand ids0mult=idboost_strain m=0.5
.model mosmod pmos
+DEVTYPE=0
+EASUB=4.0727
+NI0SUB=1.1055e+16
+BG0SUB=1.1242
+NC0SUB=2.9951e+25
+phig="4.86749 + gen_mosmod_phig"
+eot=8.9767e-10
+RDSW=0
+RDSWMIN=10
+cdscd="1e-12 + gen_mosmod_cdscd"
+vsat="83487.2 + gen_mosmod_vsat"
+VSAT1="10**(logvsat1)"
+u0="0.0178049 + gen_mosmod_u0"
+ua="0.0002437 + gen_mosmod_ua"
+PDIBL2="10**logpdibl2"
+PCLM=1e-09
+PCLMG=0.1
+CHARGEWF=0
+level=72
+VERSION=110
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
+tnom=27
+XL=0
+LINT=0
+LL=0
+LLC=0
+LLN=1
+dlc="-3.30315e-09 + gen_mosmod_dlc"
+tfin="5e-09 + gen_mosmod_tfin"
+hfin="5e-08 + gen_mosmod_hfin"
+FPITCH=3e-08
+FECH=1
+NF=1
+NFIN=1
+NBODY=2e+20
+NSD=2e+26
+NGATE=0
+LPHIG=0
+LRDSW=0
+ARDSW=0
+BRDSW=1e-08
+PRWG=0
+CIT=0
+cdsc="0.093936 + gen_mosmod_cdsc"
+LCDSC=0
+LCDSCD=0
+DVT0=0
+LDVT0=0
+DVT1=0.7
+LDVT1=0
+PHIN=0
+LPHIN=0
+eta0=0
+LETA0=0
+DSUB=1.06
+LDSUB=0
+K1RSCE=0
+LK1RSCE=0
+LPE0=0
+LLPE0=0
+QMFACTOR=1
+qm0=0.0134975
+LVSAT=0
+AVSAT=0
+BVSAT=6e-08
+AVSAT1=0
+BVSAT1=6e-08
+ksativ=1.37411
+LKSATIV=0
+DELTAVSAT=1
+MEXP="2+10**logmexp"
+LMEXP=0
+AMEXP=0
+BMEXP=1
+PTWG="10**logptwg"
+LPTWG=0
+APTWG=0
+BPTWG=6e-08
+LU0=0
+etamob=0.114836
+UP=0
+LUP=0
+LPA=1
+LUA=0
+AUA=0
+BUA=6e-08
+eu=9.96444
+LEU=0
+ud=0
+LUD=0
+AUD=0
+BUD=5e-08
+UCS=1
+LUCS=0
+PDIBL1=0
+LPDIBL1=0
+LPDIBL2=0
+DROUT=1.06
+LDROUT=0
+pvag=3.81229
+LPVAG=0
+LPCLM=0
+cfs="2.70788e-10 + gen_mosmod_cfs"
+PRWGS=1
+at=-0.000437615
+cfd="2.70788e-10 + gen_mosmod_cfd"
+cgdl=7.24436e-11
+cgdo=0
+cgsl=7.24436e-11
+cgso=0
+ckappad=0.369401
+ckappas=0.369401
+delvfbacc=0
+dvtp0="-0.0941962 + gen_mosmod_dvtp0"
+dvtp1=1
+iit=0
+kt1=0.0293651
+lsp=7.5e-09
+pqm=0.612001
+prt=0
+ptwgt=0
+qmtcencv=0.378261
+tss=-0.00013492
+ua1=0
+uc1=0
+ucste=0
+ute=-1.4271
+utl=0
.ends