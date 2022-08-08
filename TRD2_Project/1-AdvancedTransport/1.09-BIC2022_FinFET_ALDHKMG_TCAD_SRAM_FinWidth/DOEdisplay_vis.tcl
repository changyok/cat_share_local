#setdep @node|DG_calib@


#if "@SplitID@" == "ChannelLength"
#if "@TechType@" == "BulkFinFET"
#if  @SelectiveGate@
set fname "@pwd@/../1.06-BIC2022_FinFET_SelectiveDepoHKMG_TCAD_SRAM_Nominal/nominal_@Type@.dat"
#else
set fname "@pwd@/../1.06-BIC2022_FinFET_ALDHKMG_TCAD_SRAM_Nominal/nominal_@Type@.dat"
#endif
#endif
while { [file exists $fname] != 1} {
  after 1000
}
#else
set fname @nodedirpath|DG_calib@/n@node|DG_calib@_opt.out
#endif

if { [file exists $fname] == 1} {
  set f [open $fname]
  set lines [split [read $f] \n]
  close $f

#if "@SplitID@" == "Nominal"
  set dg_fname "@pwd@/nominal_@Type@.dat"
  set dgf [open $dg_fname w]
#endif

  foreach line $lines {
   if [regexp "DOE:" $line]==1 {
    puts $line
#if "@SplitID@" == "Nominal"
    puts $dgf $line
#endif
   }
  }
#if "@SplitID@" == "Nominal"
  close $dgf
#endif
} else {
  puts "File $fname doesn't exist!!"
}


