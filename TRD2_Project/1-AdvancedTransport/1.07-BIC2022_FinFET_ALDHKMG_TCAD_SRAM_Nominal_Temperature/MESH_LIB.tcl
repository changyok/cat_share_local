proc MeshWindow {args} {
#rem # MeshWindow - procedure to write the mesh refinement command
#rem # using
#rem # It take the following arguments:
#rem #  1. Name      - name of the polyhedron
#rem #  2. Center Coordinate List        - Cuboid center 
#rem #  3. Cuboid size List       - Cuboid size (width, height, length)
#rem #  4. Rc        - Corner radius (sharp corner when < 0)
#rem #  5. Channel (length) Direction - Cuboid legnth direction
#rem #  6. Tech type - BulkFinFET / FinFET / GAA

  if {[llength $args] != 5} {
     error "MeshWindow: wrong number of arguments"
     exit -1
  }

  set name          [lindex $args 0]
  set mwindow       [lindex $args 1]
  set mesh_size     [lindex $args 2]
  set mDir          [lindex $args 3]
  set Dir           [lindex $args 4]

  if { $Dir == "z" } {
    set window   $mwindow
    set mesh_dir $mDir
  } elseif { $Dir == "x" } {
    set window  [list [lindex $mwindow 4] [lindex $mwindow 5] [lindex $mwindow 2] [lindex $mwindow 3] [lindex $mwindow 0] [lindex $mwindow 1]]
    if { $mDir == "z" } {
      set mesh_dir "x"
    } elseif { $mDir == "x" } {
      set mesh_dir "z"
    } else {
      set mesh_dir $mDir
    }
  } elseif { $Dir == "y" } {
    set window  [list [lindex $mwindow 0] [lindex $mwindow 1] [lindex $mwindow 4] [lindex $mwindow 5] [lindex $mwindow 2] [lindex $mwindow 3]]
    if { $mDir == "z" } {
      set mesh_dir "y"
    } elseif { $mDir == "y" } {
      set mesh_dir "z"
    } else {
      set mesh_dir $mDir
    }
  } else {
    puts "Wrong channel direction !!!"
    exit
  }

  puts "    window \"${name}\"  $window "
  if { $mDir == "xyz" } {
    puts "    maxCellSize window \"${name}\" $mesh_size "
  } else {
    puts "    maxCellSize window direction \"${name}\" \"${mesh_dir}\" $mesh_size "
  }

}



