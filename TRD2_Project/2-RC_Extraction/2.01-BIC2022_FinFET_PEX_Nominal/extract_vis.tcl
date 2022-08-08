#setdep @node|hspice@

set fmt0 [open "n@node|hspice@_spi.mt0" "r"]

set fdata [read $fmt0]
set data [split $fdata "\n"]
set lastline [lindex $data end-1]
set trf [lindex $lastline 0]
set trf [expr $trf*1e12]
puts "DOE: trf $trf"

set tfr [lindex $lastline 1]
set tfr [expr $tfr*1e12]
puts "DOE: tfr $tfr"

close $fmt0
