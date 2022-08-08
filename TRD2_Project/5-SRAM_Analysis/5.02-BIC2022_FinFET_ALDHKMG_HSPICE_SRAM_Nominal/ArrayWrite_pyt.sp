* array sim

.inc @incfile@
.inc @pwd@/@nodedir|ArrayTiling@/n@node|ArrayTiling@_sram_array.sp

.inc @nmos_mod@
.inc @pmos_mod@

.param vdd_val=0.65

*supplies
vvdd vdd 0 vdd_val
vvss vss 0 0
vvbp vbp 0 vdd_val
vvbn vbn 0 0

vvddwr_near vddwr_near  0 vdd_val
vvsswr_near vsswr_near  0 0
vvddwr_far  vddwr_far   0 vdd_val
vvsswr_far  vsswr_far   0 0

* overwrite the WL@activeWL@ stimulus
vwl_@activeWL@ nwl@activeWL@ 0 PWL 0 vdd_val 20n vdd_val 20.005n 0 25.005n 0 25.1n vdd_val

*wl driver inverter
xpmos @wl_l@@activeWL@_0 nwl@activeWL@ vdd vdd mos3p l= 0.018u nfin=@nfin_wldrv@ delvtrand0=0.3
xnmos @wl_l@@activeWL@_0 nwl@activeWL@ vss vss mos3n l= 0.018u nfin=@nfin_wldrv@ delvtrand0=0.3

*near write driver1
xpmoswr1 @nbl_b@@<nrows-1>@_0 vss vddwr_near vdd mos3p l= 0.018u nfin=10 delvtrand0=0.3
xnmoswr1 @nbl_b@@<nrows-1>@_0 vss vss        vss mos3n l= 0.018u nfin=10 delvtrand0=0.3
*near write driver0
xpmoswr3 @bl_b@@<nrows-1>@_0 vdd vdd vdd mos3p l= 0.018u nfin=10 delvtrand0=0.3
xnmoswr3 @bl_b@@<nrows-1>@_0 vdd vsswr_near vss mos3n l= 0.018u nfin=10 delvtrand0=0.3

*far write driver_pre
*near write driver1
xpmoswr01 @bl_b@@<nrows-1>@_@<ncolumns-1>@ vss vddwr_far vdd mos3p l= 0.018u nfin=10 delvtrand0=0.3
xnmoswr01 @bl_b@@<nrows-1>@_@<ncolumns-1>@ vss vss vss mos3n l= 0.018u nfin=10 delvtrand0=0.3
*near write driver0
xpmoswr03 @nbl_b@@<nrows-1>@_@<ncolumns-1>@ vdd vdd vdd mos3p l= 0.018u nfin=10 delvtrand0=0.3
xnmoswr03 @nbl_b@@<nrows-1>@_@<ncolumns-1>@ vdd vsswr_far vss mos3n l= 0.018u nfin=10 delvtrand0=0.3



.tran 1p 30n

.option nomod accurate NOPAGE INGOLD=2 measdgt=8 runlvl=6 method=gear maxord=2 lislvl=1 post


.meas tran rise_delay trig v(@wl_l@@activeWL@_0) rise=1 val="0.5*vdd_val" targ v(@wl_l@@activeWL@_@<ncolumns-1>@) rise=1 val="0.5*vdd_val"
.meas tran fall_delay trig v(@wl_l@@activeWL@_0) fall=1 val="0.5*vdd_val" targ v(@wl_l@@activeWL@_@<ncolumns-1>@) fall=1 val="0.5*vdd_val"
.meas tran write_near trig v(@wl_l@@activeWL@_0) rise=1 val="0.5*vdd_val" targ v(xcell0_0.iq1:n1d) fall=1 val="0.1*vdd_val"
.meas tran write_far trig  v(@wl_l@@activeWL@_0) rise=1 val="0.5*vdd_val" targ v(xcell0_@<ncolumns-1>@.iq1:n1d) fall=1 val="0.1*vdd_val"


.temp @sim_temp@

.end
