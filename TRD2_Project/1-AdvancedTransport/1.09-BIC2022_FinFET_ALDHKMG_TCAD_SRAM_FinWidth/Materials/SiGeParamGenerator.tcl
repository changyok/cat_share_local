# Tcl procedure to generate SiGe parameters vs. xGe

proc min { a b } {
  if { $a<$b } {
    return $a
  } else {
    return $b
  }
}


# Compute the relaxed band edges vs. xGe from SNPS/IIT_Bombay JAP 2013 
# Return Gamma, Delta, L, GammaC
proc relaxedBandEdges { xGe } {
  # Relative to paper, made following changes:
  #  - Adjusted Delta value at xGe=0 to give Si value of 1.12, 
  #    adjusted linear term to give EPM value at xGe=1
  # - Adjusted Gamma C value to give better fit to EPM at xGe=1
  # - Adjusted L B value to give better fit to EPM at xGe=1
  set Gamma  [expr 0.0     + 0.65939*$xGe - 0.15641*$xGe*$xGe];#orig C=-0.15441
  set Delta  [expr 1.12    + 0.19211*$xGe + 0.0542*$xGe*$xGe];#orig A=1.10647,B=0.20564
  set L      [expr 2.0895  - 0.83580*$xGe - 0.0885*$xGe*$xGe];#orig B=-0.83880    
  set GammaC [expr 4.01956 - 2.74100*$xGe + 0.03969*$xGe*$xGe]

  # Determine Ec and level shifts relative to Ec
  set Ec [min $Delta $L]
  set Delta_Eshift  [expr $Delta - $Ec]
  set L_Eshift      [expr $L - $Ec]
  set GammaC_Eshift [expr $GammaC - $Ec]

  # Determine bandgap
  set Eg [expr $Ec - $Gamma]

  # Determine affinity. First set vacuum level based on Si Eg andaffinity
  set Evac [expr 1.12 + 4.05]
  set Affinity [expr $Evac - $Ec]  
  return [list $Gamma $Delta $L $GammaC $Eg $Affinity $Delta_Eshift $L_Eshift $GammaC_Eshift]
}


# Generate relaxed band edges
set table [list]
set fields [list xGe Gamma_E Delta_E L_E GammaC_E Eg Affinity Delta_Eshift L_Eshift GammaC_Eshift ]
foreach xGe [list 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0] {
  set row [concat $xGe [relaxedBandEdges $xGe]]
  lappend table $row
}

source writePlt.tcl
writePlt $table $fields "relaxedEnergies.plt"

