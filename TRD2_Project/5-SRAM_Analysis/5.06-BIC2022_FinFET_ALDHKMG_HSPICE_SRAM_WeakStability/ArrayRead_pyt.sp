* array sim

.inc @incfile@
.inc @pwd@/@nodedir|ArrayTiling@/n@node|ArrayTiling@_sram_array.sp

*.inc @nmos_mod@
*.inc @pmos_mod@

.param vdd_val=@Vdd@

*supplies
vvdd vdd 0 vdd_val
vvss vss 0 0
vvbp vbp 0 vdd_val
vvbn vbn 0 0

* overwrite the WL@activeWL@ stimulus
vwl_@activeWL@ nwl@activeWL@ 0 PWL 0 vdd_val 0.01n vdd_val 0.015n 0 5.005n 0 5.1n vdd_val

*wl driver inverter
xpmos @wl_l@@activeWL@_0 nwl@activeWL@ vdd vdd mos3p l= 0.018u nfin=@nfin_wldrv@ delvtrand0=0.2
xnmos @wl_l@@activeWL@_0 nwl@activeWL@ vss vss mos3n l= 0.018u nfin=@nfin_wldrv@ delvtrand0=0.2


.tran 1p 10n

.option nomod post accurate NOPAGE INGOLD=2 measdgt=8 runlvl=6 method=gear maxord=2 lislvl=1 fsdb=1


.meas tran rise_delay trig v(@wl_l@@activeWL@_0) rise=1 val="0.5*vdd_val" targ v(@wl_l@@activeWL@_@<ncolumns-1>@) rise=1 val="0.5*vdd_val"
.meas tran fall_delay trig v(@wl_l@@activeWL@_0) fall=1 val="0.5*vdd_val" targ v(@wl_l@@activeWL@_@<ncolumns-1>@) fall=1 val="0.5*vdd_val"
.meas tran read_near trig v(@wl_l@@activeWL@_0) rise=1 val="0.5*vdd_val" targ v(@bl_b@@<nrows-1>@_0) fall=1 val="0.7*vdd_val"
.meas tran read_far trig v(@wl_l@@activeWL@_0) rise=1 val="0.5*vdd_val" targ v(@nbl_b@@<nrows-1>@_@<ncolumns-1>@) fall=1 val="0.7*vdd_val"
.meas tran wl_far_pw trig v(@wl_l@@activeWL@_@<ncolumns-1>@) rise=1 val="0.9*vdd_val" targ v(@wl_l@@activeWL@_@<ncolumns-1>@) fall=1 val="0.9*vdd_val"
.meas tran vbump_near max v(xcell@activeWL@_0.iq1:n1d)
.meas tran vbump_far max v(xcell@activeWL@_@<ncolumns-1>@.iq1:n1d)

.temp @sim_temp@

.end
