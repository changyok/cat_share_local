proc getSamples {vars method table scut isplit ncols} {

    set num_columns $ncols
    set num_vars [expr [llength $vars]/3]
    set count 0
    
    ## Actual sampling table: Ncols= $num_vars, Nrows=> with filter scut 
    set rtable [list]
    
    if { [string match $method sensitivity] } {
      ## Sensitivity Analysis
      set num_columns 10                ;# to overwrite default, if different
      set num_rows [expr $num_vars*6]   ;# 6 splits per variable in this example
      for {set i 0} {$i<=$num_rows} {incr i} {
        for {set j 0} {$j<$num_vars} {incr j} {
    	set element [lindex $table [expr $i*$num_columns+$j]]
    	lappend rtable $element
        }
        incr count
      }
    } else {
      ## Random Sampling 
      set num_rows [expr [llength $table] / $num_columns ]
      for {set i 0} {$i<$num_rows} {incr i} {
        set row [list]
        set flag 0
        for {set j 0} {$j<$num_vars} {incr j} {
    	set element [lindex $table [expr $i*$num_columns+$j]]
    	lappend row $element
    	if {abs($element)>=$scut} {
    	    set flag 1
    	}
        }
        if {$flag==1} {
    	echo "row=$row"
    	incr count
    	foreach element $row {
    	    lappend rtable $element
    	}
        }
      }
    }
    
    echo "count=$count"
    
    ## stop split if exceeding actual number of rows
    if {$isplit>[expr $count-1]} {
        exit
    }
    
    ## Assign variables according to the table
    set j 0
    set xs [list]
    foreach "name mean sigma" $vars {
        set x [lindex $rtable [expr $isplit*$num_vars+$j]]
        lappend xs $x
        set x [expr $mean+$x*$sigma]
        set $name $x
        dict set var_sample $name $x
        incr j
    }
    foreach "name mean sigma" $vars {
        echo [set $name]
    }
    # DEBUG
    puts "DOE: Sigma  $xs"
    
      return $var_sample

} ;# proc
