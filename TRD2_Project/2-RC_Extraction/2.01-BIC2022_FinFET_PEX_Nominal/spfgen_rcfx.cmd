#setdep @node|rcfx@

catch {exec cp @pwd@/rcnets.tbc .}

# insert rc netlist to _rph.spi 
exec cp @pwd@/@nodedir|rcnet@/n@node|rcnet@_rph.spi n@node@_tmp.spi
exec sed -i "s|__placeholder.spi|@pwd@/@nodedir|rcfx@/n@node|rcfx@_rcfx.rc1Matrix.spi|g" n@node@_tmp.spi

# cd @pwd@/@nodedir|rcfx@
set spi n@node@_tmp.spi
set lvs @pwd@/@lvs@
set out n@node@_rph.spf
set out1 n@node@_rph.spi

set cell @cell@

if { ([string first "sram" $cell] != -1) || ([string first "array" $cell] != -1) } {
rcnetgroup raphaelnet= $spi outputnet= $out1 pingroup= { WL {WLL WLR} BL {BLU BLD} BLB {BLBU BLBD} }
rcnetvalidate raphaelnet= $out1 referencenet= $lvs pingroup= { WL {WLL WLR} BL {BLU BLD} BLB {BLBU BLBD} }
rcnetmerge raphaelnet=$out1 referencenet= $lvs outputnet= $out pingroup= { WL {WLL WLR} BL {BLU BLD} BLB {BLBU BLBD} } cellnamefrom= raphaelfx pinsfrom= raphaelfx
} else {
rcnetgroup raphaelnet= $spi outputnet= $out1 skip= {xn xp}
rcnetvalidate raphaelnet= $out1 referencenet= $lvs
rcnetmerge raphaelnet=$out1 referencenet= $lvs concat= {../@node|spx@/n@node|spx@_par.spi} outputnet= $out
}

# cd @pwd@/@nodedir|spfgen@
# exec cp n@node@_rph.spf @pwd@/netlist_final/@cell@_@flow@_@selectivehighk@.spf

exit

