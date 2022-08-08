#if "@Type@" == "nMOS"
.subckt mos3n d g s b l=@lgate@ nfin=1 rgc_en=1 rdc_en=1 rsc_en=1 delvtrand0=0 vtmode_adjust=0 avgStrain=@avgStrainNom@

.param r_gc	=0
.param rgc_fin	='r_gc/nfin*rgc_en'
.param r_sc	=0
.param rsc_fin	='r_sc/nfin*rsc_en'
.param r_dc	=0
.param rdc_fin	='r_dc/nfin*rdc_en'

rd	d	d_i	rdc_fin
rs	s	s_i	rsc_fin
rg	g	g_i	rgc_fin


* to inject extra VT variation
.param phigvar = 0.0

* stress effects (Vt)
.param strain_nom = 0.0
.param slope_vt_strain = 0.0
.param vtshift_strain = '-1.0*slope_vt_strain*(avgStrain-strain_nom)'
* stress effects (Idboost)
.param slope_id_strain = 0.0
.param idboost_strain = 'slope_id_strain*(avgStrain-strain_nom)+1.0'

* calculate final VT deltas
.param final_delvtrand="delvtrand0 + vtmode_adjust + phigvar + vtshift_strain"

.param logvsat1=4.9
.param logpdibl2=-4
.param logmexp=0.3
.param logptwg=0.3

mos d_i g_i s_i b mosmod l=l nfin=nfin delvtrand=final_delvtrand ids0mult=idboost_strain M=0.5
.model mosmod nmos
+ DEVTYPE=1
+ EASUB = 4.0727
+ NI0SUB = 1.1055e16
+ BG0SUB = 1.1242
+ NC0SUB = 2.9951e25
+ EOT = 1.0E-9
+ PHIG = 4
+ RDSW = 0
+ RDSWMIN = 50
+ CDSCD = 1e-10
+ VSAT = 80000
+ VSAT1 = "10**logvsat1"
+ U0 = 0.02
+ UA = 0.1
+ PDIBL2 = "10**logpdibl2"
+ PCLM = 1e-10
+ PCLMG = 0.0
#else if "@Type" == "pMOS"
.subckt mos3p d g s b l=@lgate@ nfin=1 rgc_en=1 rdc_en=1 rsc_en=1 delvtrand0=0 vtmode_adjust=0 avgStrain=@avgStrainNom@ 

.param r_gc	=0
.param rgc_fin	='r_gc/nfin*rgc_en'
.param r_sc	=0
.param rsc_fin	='r_sc/nfin*rsc_en'
.param r_dc	=0
.param rdc_fin	='r_dc/nfin*rdc_en'


rd	d	d_i	rdc_fin
rs	s	s_i	rsc_fin
rg	g	g_i	rgc_fin



* to inject extra VT variation
.param phigvar = 0.0

* stress effects (Vt)
.param strain_nom = 0.0
.param slope_vt_strain = 0.0
.param vtshift_strain = '-1.0*slope_vt_strain*(avgStrain-strain_nom)'
* stress effects (Idboost)
.param slope_id_strain = 0.0
.param idboost_strain = 'slope_id_strain*(avgStrain-strain_nom)+1.0'

* calculate final VT deltas
.param final_delvtrand="delvtrand0 + vtmode_adjust + phigvar + vtshift_strain"

.param logvsat1=4.9
.param logpdibl2=-4
.param logmexp=0.3
.param logptwg=0.3

mos d_i g_i s_i b mosmod l=l nfin=nfin delvtrand=final_delvtrand ids0mult=idboost_strain m=0.5
.model mosmod pmos
+ DEVTYPE=0
+ EASUB = 4.0727
+ NI0SUB = 1.1055e16
+ BG0SUB = 1.1242
+ NC0SUB = 2.9951e25
+ PHIG = 4.71037658684
+ EOT = 1.0E-9
+ RDSW = 0
+ RDSWMIN = 10
+ CDSCD = 0.01
+ VSAT = 80000
+ VSAT1 = "10**(logvsat1)"
+ U0 = 0.01
+ UA = 0.1
+ PDIBL2 = "10**logpdibl2"
+ PCLM = 1e-9
+ PCLMG = 0.1
+ CHARGEWF = 0
#endif
+ level=72
+ VERSION=110
+ BULKMOD=1
+ CAPMOD=1
+ IGCMOD=0
+ IGBMOD=0
+ GIDLMOD=0
+ COREMOD=0
+ GEOMOD=1
+ CGEOMOD=0
+ IIMOD=0
+ RDSMOD = 0
+ TNOM = 25
+ XL = 0
+ LINT = 0e-9
+ LL = 0
+ LLC = 0
+ LLN = 1
+ DLC = 0
+ TFIN=5.0e-09
+ HFIN=14.0e-09
+ FPITCH=3e-08
+ FECH=1
+ NF = 1
+ NFIN = 1
+ NBODY=2e20
+ NSD=2e26
+ NGATE = 0
+ LPHIG = 0
+ LRDSW=0
+ ARDSW=0
+ BRDSW=1e-8
+ PRWG=0
+ CIT = 0
+ CDSC = 0.1
+ LCDSC = 0
+ LCDSCD = 0
+ DVT0 = 0.0
+ LDVT0 = 0
+ DVT1 = 0.7
+ LDVT1 = 0
+ PHIN = 0
+ LPHIN = 0
+ ETA0 = 10.0
+ LETA0 = 0
+ DSUB = 1.06
+ LDSUB = 0
+ K1RSCE = 0
+ LK1RSCE = 0
+ LPE0 = 0
+ LLPE0 = 0
+ QMFACTOR = 1.0
+ QM0 = 1e-3
+ LVSAT = 0
+ AVSAT = 0
+ BVSAT = 6e-8
+ AVSAT1 = 0
+ BVSAT1 = 6e-8
+ KSATIV = 1
+ LKSATIV = 0
+ DELTAVSAT = 1.0
+ MEXP = "2+10**logmexp"
+ LMEXP = 0
+ AMEXP = 0
+ BMEXP = 1
+ PTWG = "10**logptwg"
+ LPTWG = 0
+ APTWG = 0
+ BPTWG = 6e-8
+ LU0 = 0
+ ETAMOB = 2
+ UP = 0
+ LUP = 0
+ LPA = 1
+ LUA = 0
+ AUA = 0
+ BUA = 6e-8
+ EU = 2.5
+ LEU = 0
+ UD = 0.1
+ LUD = 0
+ AUD = 0
+ BUD = 0.00000005
+ UCS = 1
+ LUCS = 0
+ PDIBL1 = 0
+ LPDIBL1 = 0
+ LPDIBL2 = 0
+ DROUT = 1.06
+ LDROUT = 0
+ PVAG = 1
+ LPVAG = 0
+ LPCLM = 0.0
+ CFS=0
+ PRWGS = 1.0
.ends
