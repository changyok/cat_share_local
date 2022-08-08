#
# PE-Raphael FX Flow v2.3
#

set layoutlayers {
    nwell  5:1
    active 7:7
    fin    7:8
    poly  9:7
    gatetext 9:100
    ca    7:8
#    ca    "10:1 10:2"
    sdtext 10:1
    pins "30:2 30:12 50:12 50:10"
    bbox @bbox_layer@
}

set layoutparams {
    inputgds @pwd@/@gds@
    outputgds n@node@_rph.oasis
    outputgdsformat oasis
    cell @cell@
    orientation 1 
}

set contactparams {
    # sdtextdisplacement 4.5
    sdtextanchor ca
}

set netlistparams {
    vbp VBP
    vbn VBN
    # pname XP
    # nname XN
    rcnet __placeholder.spi
    outputnetlist n@node@_rph.spi
}
set a 1
set result [rcnetgen layoutlayers= $layoutlayers layoutparams= $layoutparams netlistparams= $netlistparams contactparams= $contactparams]

# exec cp @pwd@/@gds@.mac n@node@_rph.oasis.mac

puts "DOE: devices \{[lrange $result 0 2]\}"
#set bbox x
puts "DOE: bbox [lindex $result 3]"
#set pins x
puts "DOE: pins \"[lindex $result 4]\""

exit

