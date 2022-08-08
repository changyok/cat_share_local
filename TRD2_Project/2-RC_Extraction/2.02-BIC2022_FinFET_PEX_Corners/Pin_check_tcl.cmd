#setdep @node|spx@
set ok 0
set pins @pins@

if {@checkpins@ == 1} {
set fp [open "../@node|spx@/n@node|spx@_spx.out" r]
set file_data [read $fp]
close $fp

set data [split $file_data "\n"]
foreach line $data {
# Substring search
foreach pin $pins {
if {[string first "$pin is outside the clip" $line] != -1} {
puts $line
exit 1
}
}
}
}

exit $ok

