# Physics model parameters for SiGe as a function of xGe
# This file should be sourced before first Solve 

# Compute valley occupancies
proc calcValleyOcc { Nsubbands } {
  # Valleys that will contribute to occupancies by name
  set OccValleyList(GammaC)   [list GammaC]
  set OccValleyList(L)        [list L1 L2 L3 L4]
  set OccValleyList(X)        [list X1 X2 X3]


  # Compute total Ninvin each occ valley set
  set totalSum 0.0
  foreach {occName valleyList} [array get OccValleyList] {
    set sum 0.0
    foreach valley $valleyList {
      set sums 0.0
      for {set i 0} {$i<$Nsubbands} {incr i} {
        set subbandNinv 0.0
        catch { set subbandNinv [Extract model=${valley}_${i}_SubbandDensity integral nonlocal=NL1] }
        set sum [expr $sum + $subbandNinv]
        set sums [expr $sums + $subbandNinv]
      }
      if { $occName != "GammaC" } {
        set OccValleySum($valley) $sums
      }
    }
    set OccValleySum($occName) $sum
    set totalSum [expr $totalSum + $sum]
  }

  # Debug
  #puts "totalSum=$totalSum, Ninv_in_well0=[GetLast name=Ninv_in_well0]"
  
  # Compute occupancy in each occ valley set and write to logfile
  foreach {occName Ninv} [array get OccValleySum] {
    set occ [expr $Ninv/$totalSum]
    AddToLogFile name=${occName}_occ value=$occ
    puts "Occupancy of $occName = $occ"
  }


}



# Read ascii table of parameters
proc readTable { filename } {

  set table [list]
  set fileID [open $filename r]
  while { [gets $fileID line] >=0} {
    set c [string index $line 0]
    if { $c=="#" } { continue }
    lappend table $line
  }
  close $fileID

  puts "Read parameter table: ${filename}"

  return $table
}


# Use piecewise linear interpolation for molefraction x for desired quantity from parameter table
proc piecewiseLinearInterp { table quantity target_x } {
  # Validate domain of target_x. x assumed to be in column 0
  set Nrow [llength $table]
  set min_x [lindex [lindex $table 1] 0]
  set max_x [lindex [lindex $table [expr $Nrow-1]] 0]
  if { $target_x<$min_x || $target_x>$max_x } {
    # throw exception
    return -code error "xMolefrac=$target_x is out of domain"
  }

  # Determine column for desired quantity in table
  set row  [lindex $table 0]
  set Ncol [llength $row]
  set iCol -1
  for {set i 0} {$i<$Ncol} {incr i} {
    if { [string compare $quantity [lindex $row $i]]==0 } {
      set iCol $i
      break
    }
  }

  if { $iCol<0 } {
   # Throw exception
   return -code error "Did not find $quantity in parameter table"
  }

  # Now find x values in table that bracket target_x
  for {set i 1} {$i<[expr $Nrow-1]} {incr i} {
    set row0 [lindex $table [expr $i+0]]
    set row1 [lindex $table [expr $i+1]]
    set x0 [lindex $row0 0]
    set x1 [lindex $row1 0]
    if { $target_x>=$x0 && $target_x<=$x1 } { 
      # Found bracket. Do interp
      set value0 [lindex $row0 $iCol]
      set value1 [lindex $row1 $iCol]
      set value [expr $value0 + (($value1-$value0)/($x1-$x0))*($target_x-$x0)]
      return $value
    }
  }

  # Throw exception
  return -code error "Did not find proper xMolefrac bracket for xMolefrac=$target_x"
}


# Compute strain tensor for uniaxial stress along direction
proc computeUniaxialStrain { material xMolefrac stress direction } {
 
  # Set compliance tensor components for xMolefrac=0 and xMolefrac=1
  if { [string compare $material SiGe]==0 } {
    set xMolefracName xGe
    Elasticity name=E0 type=Cubic s11=0.762451 s12=-0.213158 s44=1.25;    # Si units are %/GPa
    Elasticity name=E1 type=Cubic s11=0.956757 s12=-0.26127  s44=1.49701; # Ge units are %/GPa
  } elseif { [string compare $material InGaAs]==0 } {
    set xMolefracName xIn
    Elasticity name=E0 type=Cubic s11=1.173 s12=-0.366  s44=1.684; # GaAs units are %/GPa. [Adachi 2009]
    Elasticity name=E1 type=Cubic s11=1.945 s12=-0.6847 s44=2.526; # InAs units are %/GPa. [Adachi 2009]
  } elseif { [string compare $material InGaSb]==0 } {
    set xMolefracName xIn
    Elasticity name=E0 type=Cubic s11=1.583 s12=-0.4955 s44=2.315; # GaSb units are %/GPa. [Adachi 2009]
    Elasticity name=E1 type=Cubic s11=2.410 s12=-0.8395 s44=3.304; # InSb units are %/GPa. [Adachi 2009]
  } else {
   # Throw exception
   return -code error "Tried to computeUniaxialStrain for unknown material=$material"
 }
 
 # Interpolate compliance tensor components
 Elasticity name=E e1=E0 e2=E1 x2=$xMolefrac
 puts "Compliance Tensor for $material: $xMolefracName = $xMolefrac"
 puts [E status]

 # Compute strainTensor
 set strainTensor [E uniaxialStrain dir=$direction stress=$stress]
 puts "strainTensor: $strainTensor"

 # Clean up
 E0 destroy
 E1 destroy
 E  destroy

 return $strainTensor
}

# Compute relaxed lattice constant in cm
proc computeRelaxedLatticeParameter { material xMolefrac  } {
 
  # Compute relaxed lattice constant per material
  if { [string compare $material SiGe]==0 } {
    set xMolefracName xGe
    set aSi 5.43; # Angstrom [SBand default]
    set aGe 5.64; # Angstrom  [SBand default]
    set a0 [expr $aSi + 0.200326 * $xMolefrac * (1.0-$xMolefrac) + ($aGe-$aSi) * $xMolefrac * $xMolefrac]
  } elseif { [string compare $material InGaAs]==0 } {
    set xMolefracName xIn
    set aGaAs 5.6533; # Angstrom [Adachi 2009]
    set aInAs 6.0583; # Angstrom [Adachi 2009]
    set a0 [expr $aGaAs*(1-$xMolefrac) + $aInAs*$xMolefrac]
  } elseif { [string compare $material InGaSb]==0 } {
    set xMolefracName xIn
    set aGaSb 6.09593; # Angstrom [Adachi 2009]
    set aInSb 6.47937; # Angstrom [Adachi 2009]
    set a0 [expr $aGaSb*(1-$xMolefrac) + $aInSb*$xMolefrac]
  } else {
   # Throw exception
   return -code error "Tried to computeRelaxedLatticeConstant for unknown material=$material"
 }
 
 # convert to cm
 set a0 [expr 1.0e-8*$a0]
 
 # Print out result
 puts "Relaxed Lattice Constant for $material: $xMolefracName = $xMolefrac.  a0 = [format "%.3e" $a0] cm"
 
 return $a0
}



# Set insulator parameters based on semiconductor material
proc setupInsulatorParameters { semiMaterial } {
  # Set some electrostatic params for pure HfO2 from Barraud, JAP 104,73725 (2008).
#  Physics material=HfO2 Permittivity epsilon=19.0
#  Physics material=HfO2 Bandgap      Eg=6.0
#  Physics material=HfO2 Affinity     chi=2.

  # Setup ValleyModels in Oxide for wavefunction penetration based on semiMaterial
  if { [string compare $semiMaterial SiGe]==0 } {
    set oxMass 0.4
    set oxGamma 2.5
  } elseif { [string compare $semiMaterial InGaAs]==0 } {
    # Use small mass to supress oxide penetration due to uncertainty in value
    set oxMass  1.0e-5
    set oxGamma 1.0e5
  } elseif { [string compare $semiMaterial InGaSb]==0 } {
    # Use small mass to supress oxide penetration due to uncertainty in value
    set oxMass  1.0e-5
    set oxGamma 1.0e5
  }
  
  puts "Oxide Schrodinger parameters for ${semiMaterial}:"
  puts "... oxMass=$oxMass"
  puts "... oxGamma=$oxGamma"

  # Setup conduction valleys
  foreach valley [list GammaC L1 L2 L3 L4 X1 X2 X3] {
    Physics material=Oxide ValleyModel=ConstantEllipsoid name=$valley \
            degeneracy=2 kl=[list 1 0 0] kt1=[list 0 1 0] kt2=[list 0 0 1] \
            ml=$oxMass mt1=$oxMass mt2=$oxMass alpha=0.0 Eshift=0.0 useForEBulkDensity=0
  }

  # Setup valence valley
  Physics material=Oxide ValleyModel=6kpValley name=Gamma \
          degeneracy=1 gamma1=$oxGamma gamma2=0.0 gamma3=0.0 delta=0.0 \
          a_v=0.0 b=0.0 d=0.0 useForHBulkDensity=0   
  
}



# Setup material, xMolefrac, and strain dependent parameters for the indicated region
proc setupMaterialParameters { material regionName xMolefrac strainTensor} {
 # Load parameter tables based on material
 global BandParamTable
 global ElectrostaticParamTable
 if { [string compare $material SiGe]==0 } {
   set xMolefracName xGe
   set BandParamTable          [readTable ./Materials/SiGe_BandParams.txt]
   set ElectrostaticParamTable [readTable ./Materials/SiGe_SDeviceElectrostaticParams.txt]
 } elseif { [string compare $material InGaAs]==0 } {
   set xMolefracName xIn
   set BandParamTable          [readTable ./Materials/InGaAs_BandParams.txt]
   set ElectrostaticParamTable [readTable ./Materials/InGaAs_SDeviceElectrostaticParams.txt]
 } elseif { [string compare $material InGaSb]==0 } {
   set xMolefracName xIn
   set BandParamTable          [readTable ./Materials/InGaSb_BandParams.txt]
   set ElectrostaticParamTable [readTable ./Materials/InGaSb_SDeviceElectrostaticParams.txt]
 } else {
   # Throw exception
   return -code error "Tried to setupMaterialParameters for unknown material=$material"
 }




 puts "*********************************************************"
 puts "* Material Parameters for region=$regionName. $material: $xMolefracName=$xMolefrac"
 puts "*********************************************************"

 # Basic Electrostatics Parameters
 set thisPermittivity [piecewiseLinearInterp $ElectrostaticParamTable Permittivity $xMolefrac]
 Physics region=$regionName Permittivity epsilon=$thisPermittivity

 set thisNc [piecewiseLinearInterp $ElectrostaticParamTable Nc300 $xMolefrac]
 Physics region=$regionName eBulkDensity=eFermiDensity Nc=$thisNc

 set thisNv [piecewiseLinearInterp $ElectrostaticParamTable Nv300 $xMolefrac]
 Physics region=$regionName hBulkDensity=hFermiDensity Nv=$thisNv

 set thisBandgap [piecewiseLinearInterp $ElectrostaticParamTable Bandgap $xMolefrac]
 Physics region=$regionName Bandgap  Eg=$thisBandgap

 set thisAffinity [piecewiseLinearInterp $ElectrostaticParamTable Affinity $xMolefrac]
 Physics region=$regionName Affinity chi=$thisAffinity

 # Compute relaxed lattice parameter in cm
 set a0 [computeRelaxedLatticeParameter $material $xMolefrac]

 puts "...thisBandgap      = $thisBandgap \[eV\]" 
 puts "...thisAffinity     = $thisAffinity \[eV\]"
 puts "...thisPermittivity = $thisPermittivity \[eps0\]"
 puts "...thisNc           = $thisNc \[cm-3\]"
 puts "...thisNv           = $thisNv \[cm-3\]"
 puts "...lattice constant = [expr $a0*1e7] \[nm\]\n"

 # Valence Band Parameters
 puts "...kp parameters..."
 set thisGamma1  [piecewiseLinearInterp $BandParamTable gamma1 $xMolefrac]
 set thisGamma2  [piecewiseLinearInterp $BandParamTable gamma2 $xMolefrac]
 set thisGamma3  [piecewiseLinearInterp $BandParamTable gamma3 $xMolefrac]
 puts "   ...Gamma1=$thisGamma1, Gamma2=$thisGamma2, Gamma3=$thisGamma3\n"

 set thisDelta  [piecewiseLinearInterp $BandParamTable DeltaSO $xMolefrac]
 set this_a_v   [piecewiseLinearInterp $BandParamTable a_v     $xMolefrac]
 set this_b     [piecewiseLinearInterp $BandParamTable b       $xMolefrac]
 set this_d     [piecewiseLinearInterp $BandParamTable d       $xMolefrac]
 puts "...spin-orbit split-off potential..."
 puts "   ...thisDelta = $thisDelta \[eV\]\n"
 puts "...valence strain deformation potentials..."
 puts "   ...this_a_v  =  $this_a_v \[eV\]"
 puts "   ...this_b    = $this_b \[eV\]"
 puts "   ...this_d    = $this_d \[eV\]\n"

 Physics region=$regionName  ValleyModel=6kpValley name=Gamma useForHBulkDensity=1 \
         a0=$a0 degeneracy=1 \
         gamma1=$thisGamma1 gamma2=$thisGamma2 gamma3=$thisGamma3 \
         delta=$thisDelta  a_v=$this_a_v  b=$this_b d=$this_d 


 # For SiGe, create 3 X Valleys based on the 2kpEllipsoid ValleyModel
 if { [string compare $material SiGe]==0 } {
   set X_ml     [piecewiseLinearInterp $BandParamTable X_ml     $xMolefrac]
   set X_mt     [piecewiseLinearInterp $BandParamTable X_mt     $xMolefrac]
   set X_alpha  [piecewiseLinearInterp $BandParamTable X_alpha  $xMolefrac]
   set X_Eshift [piecewiseLinearInterp $BandParamTable X_Eshift $xMolefrac]
   set X_Xi_d   [piecewiseLinearInterp $BandParamTable X_Xi_d   $xMolefrac]
   set X_Xi_u   [piecewiseLinearInterp $BandParamTable X_Xi_u   $xMolefrac]
   set X_Xi_s   [piecewiseLinearInterp $BandParamTable X_Xi_s   $xMolefrac]
   set X_k0     [piecewiseLinearInterp $BandParamTable X_k0     $xMolefrac]
   set X_M      [piecewiseLinearInterp $BandParamTable X_M      $xMolefrac]

   puts "Conduction X Valleys: 2kp Ellipsoid Model"
   puts "...ml     = $X_ml"
   puts "...mt     = $X_mt"
   puts "...alpha  = $X_alpha"
   puts "...Eshift = $X_Eshift"
   puts "...Xi_d   = $X_Xi_d"
   puts "...Xi_u   = $X_Xi_u"
   puts "...Xi_s   = $X_Xi_s"
   puts "...k0     = $X_k0"
   puts "...M      = $X_M"

  
   Physics region=$regionName ValleyModel=2kpEllipsoid name=X1 \
           longAxis=100 degeneracy=2 useForEBulkDensity=1 \
           a0=$a0 ml=$X_ml mt=$X_mt alpha=$X_alpha alphaZ=$X_alpha Eshift=$X_Eshift \
           Xi_d=$X_Xi_d Xi_u=$X_Xi_u M=$X_M k0=$X_k0 Xi_s=$X_Xi_s

   Physics region=$regionName ValleyModel=2kpEllipsoid name=X2 \
           longAxis=010 degeneracy=2 useForEBulkDensity=1 \
           a0=$a0 ml=$X_ml mt=$X_mt alpha=$X_alpha alphaZ=$X_alpha Eshift=$X_Eshift \
           Xi_d=$X_Xi_d Xi_u=$X_Xi_u M=$X_M k0=$X_k0 Xi_s=$X_Xi_s

   Physics region=$regionName ValleyModel=2kpEllipsoid name=X3 \
           longAxis=001 degeneracy=2 useForEBulkDensity=1 \
           a0=$a0 ml=$X_ml mt=$X_mt alpha=$X_alpha alphaZ=$X_alpha Eshift=$X_Eshift \
           Xi_d=$X_Xi_d Xi_u=$X_Xi_u M=$X_M k0=$X_k0 Xi_s=$X_Xi_s
 } else {
   # For non-SiGe, create 3 X Valleys based on the ConstantEllipsoid ValleyModel
   set X_ml     [piecewiseLinearInterp $BandParamTable X_ml     $xMolefrac]
   set X_mt     [piecewiseLinearInterp $BandParamTable X_mt     $xMolefrac]
   set X_alpha  [piecewiseLinearInterp $BandParamTable X_alpha  $xMolefrac]
   set X_Eshift [piecewiseLinearInterp $BandParamTable X_Eshift $xMolefrac]
   set X_Xi_d   [piecewiseLinearInterp $BandParamTable X_Xi_d   $xMolefrac]
   set X_Xi_u   [piecewiseLinearInterp $BandParamTable X_Xi_u   $xMolefrac]

   puts "Conduction X Valleys: Constant Ellipsoid Model"
   puts "...ml     = $X_ml"
   puts "...mt     = $X_mt"
   puts "...alpha  = $X_alpha"
   puts "...Eshift = $X_Eshift"
   puts "...Xi_d   = $X_Xi_d"
   puts "...Xi_u   = $X_Xi_u"
  
   Physics region=$regionName ValleyModel=ConstantEllipsoid name=X1 useForEBulkDensity=1  \
           degeneracy=1 kl=[list 1 0 0] kt1=[list 0 1 0] kt2=[list 0 0 1] \
           ml=$X_ml mt1=$X_mt mt2=$X_mt alpha=$X_alpha alphaZ=$X_alpha Eshift=$X_Eshift
   Physics region=$regionName ValleyModel=ConstantEllipsoid name=X2 useForEBulkDensity=1  \
           degeneracy=1 kl=[list 0 1 0] kt1=[list 0 0 1] kt2=[list 1 0 0] \
           ml=$X_ml mt1=$X_mt mt2=$X_mt alpha=$X_alpha alphaZ=$X_alpha Eshift=$X_Eshift
   Physics region=$regionName ValleyModel=ConstantEllipsoid name=X3 useForEBulkDensity=1  \
           degeneracy=1 kl=[list 0 0 1] kt1=[list 1 0 0] kt2=[list 0 1 0] \
           ml=$X_ml mt1=$X_mt mt2=$X_mt alpha=$X_alpha alphaZ=$X_alpha Eshift=$X_Eshift
 }


 # Create 4 L valleys
 set L_ml     [piecewiseLinearInterp $BandParamTable L_ml     $xMolefrac]
 set L_mt     [piecewiseLinearInterp $BandParamTable L_mt     $xMolefrac]
 set L_alpha  [piecewiseLinearInterp $BandParamTable L_alpha  $xMolefrac]
 set L_Eshift [piecewiseLinearInterp $BandParamTable L_Eshift $xMolefrac]
 set L_Xi_d   [piecewiseLinearInterp $BandParamTable L_Xi_d   $xMolefrac]
 set L_Xi_u   [piecewiseLinearInterp $BandParamTable L_Xi_u   $xMolefrac]

 puts "\n\nConduction L Valleys: Constant Ellipsoid Model"
 puts "...ml     = $L_ml"
 puts "...mt     = $L_mt"
 puts "...alpha  = $L_alpha"
 puts "...Eshift = $L_Eshift"
 puts "...Xi_d   = $L_Xi_d"
 puts "...Xi_u   = $L_Xi_u"


 Physics region=$regionName ValleyModel=ConstantEllipsoid name=L1 useForEBulkDensity=1  \
         degeneracy=1 kl=[list 1 1 1] kt1=[list -1 1 0] kt2=[list -1 -1 2] \
          ml=$L_ml mt1=$L_mt mt2=$L_mt alpha=$L_alpha alphaZ=$L_alpha Eshift=$L_Eshift

 Physics region=$regionName ValleyModel=ConstantEllipsoid name=L2 useForEBulkDensity=1  \
         degeneracy=1 kl=[list -1 1 1] kt1=[list -1 -1 0] kt2=[list 1 -1 2] \
         ml=$L_ml mt1=$L_mt mt2=$L_mt alpha=$L_alpha alphaZ=$L_alpha Eshift=$L_Eshift

 Physics region=$regionName ValleyModel=ConstantEllipsoid name=L3 useForEBulkDensity=1  \
         degeneracy=1 kl=[list 1 1 -1] kt1=[list -1 1 0] kt2=[list 1 1 2] \
         ml=$L_ml mt1=$L_mt mt2=$L_mt alpha=$L_alpha alphaZ=$L_alpha Eshift=$L_Eshift

 Physics region=$regionName ValleyModel=ConstantEllipsoid name=L4 useForEBulkDensity=1  \
         degeneracy=1 kl=[list -1 1 -1] kt1=[list -1 -1 0] kt2=[list -1 1 2] \
         ml=$L_ml mt1=$L_mt mt2=$L_mt alpha=$L_alpha alphaZ=$L_alpha Eshift=$L_Eshift


 # Create 1 GammaC valley
 set GammaC_m      [piecewiseLinearInterp $BandParamTable GammaC_m      $xMolefrac]
 set GammaC_alpha  [piecewiseLinearInterp $BandParamTable GammaC_alpha  $xMolefrac]
 set GammaC_Eshift [piecewiseLinearInterp $BandParamTable GammaC_Eshift $xMolefrac]
 set GammaC_Xi_d   [piecewiseLinearInterp $BandParamTable GammaC_Xi_d   $xMolefrac]

 puts "\n\nConduction GammaC Valleys: Constant Ellipsoid Model"
 puts "...m      = $GammaC_m"
 puts "...alpha  = $GammaC_alpha"
 puts "...Eshift = $GammaC_Eshift"
 puts "...Xi_d   = $GammaC_Xi_d"

 Physics region=$regionName ValleyModel=ConstantEllipsoid name=GammaC useForEBulkDensity=1  \
         degeneracy=1 kl=[list 1 0 0] kt1=[list 0 1 0] kt2=[list 0 0 1] \
         ml=$GammaC_m mt1=$GammaC_m mt2=$GammaC_m alpha=$GammaC_alpha alphaZ=$GammaC_alpha Eshift=$GammaC_Eshift


 # Reset bulk density models to simple Fermi models
 Physics region=$regionName eBulkDensity=eFermiDensity Nc=$thisNc
 Physics region=$regionName hBulkDensity=hFermiDensity Nv=$thisNv


 # Now set strain-dependent valley shifts
 setEShiftForAllValleys $material $regionName $xMolefrac $strainTensor
}


# van De Walles linear deformation model
proc calcDeltaEc { Xi_d Xi_u longitudinalDirection strainTensor } {
    # unit vector along longitudinal direction of valley
    set a [unitVec $longitudinalDirection]

    # Compute van De Walle's linear deformation model
    set Identity [list [list 1 0 0] [list 0 1 0] [list 0 0 1]]
    set sum 0.0
    for {set i 0} {$i<3} {incr i} {
      for {set j 0} {$j<3} {incr j} {

        set Identity_ij [lindex [lindex $Identity $i] $j]
	set Strain_ij   [lindex [lindex $strainTensor $i] $j]
        set Dyadic_ij   [expr [lindex $a $i]*[lindex $a $j]]

	set sum [expr $sum + $Xi_d*$Identity_ij*$Strain_ij + $Xi_u*$Dyadic_ij*$Strain_ij]
       
      }
    }
    return $sum
}


# Set Eshift due to relaxed shift and to strain for Constant Ellipsoid
proc setEShiftForAllValleys { material regionName xMolefrac strainTensor } {
  global BandParamTable

  puts "\n$regionName Strain-Dependent Energy Shifts for ConstantEllipsoid Valleys. xMolefrac=$xMolefrac"

  # For SiGe, the 2kpEllipsod ValleyModel handles strain dependence
  if { [string compare $material SiGe]==0 } {
    puts "...X valley strain dependence is computed by built-in models for SiGe"
  } else {
    # X valley shifts for non-SiGe
    set X_Eshift0 [piecewiseLinearInterp $BandParamTable X_Eshift $xMolefrac]
    set X_Xi_d    [piecewiseLinearInterp $BandParamTable X_Xi_d   $xMolefrac]
    set X_Xi_u    [piecewiseLinearInterp $BandParamTable X_Xi_u   $xMolefrac]

    set dEc1 [calcDeltaEc $X_Xi_d $X_Xi_u [list   1 0 0] $strainTensor]
    set dEc2 [calcDeltaEc $X_Xi_d $X_Xi_u [list   0 1 0] $strainTensor]
    set dEc3 [calcDeltaEc $X_Xi_d $X_Xi_u [list   0 0 1] $strainTensor]

    set X_Eshift1 [expr $X_Eshift0 + $dEc1]; 
    set X_Eshift2 [expr $X_Eshift0 + $dEc2]; 
    set X_Eshift3 [expr $X_Eshift0 + $dEc3]; 
  
    Physics region=$regionName ValleyModel name=X1 Eshift=$X_Eshift1
    Physics region=$regionName ValleyModel name=X2 Eshift=$X_Eshift2
    Physics region=$regionName ValleyModel name=X3 Eshift=$X_Eshift3

    puts "...X1 Eshift = $X_Eshift1"  
    puts "...X2 Eshift = $X_Eshift2"
    puts "...X3 Eshift = $X_Eshift3"
  }
  

  # L valleys
  set L_Eshift0 [piecewiseLinearInterp $BandParamTable L_Eshift $xMolefrac]
  set L_Xi_d    [piecewiseLinearInterp $BandParamTable L_Xi_d   $xMolefrac]
  set L_Xi_u    [piecewiseLinearInterp $BandParamTable L_Xi_u   $xMolefrac]

  set dEc1 [calcDeltaEc $L_Xi_d $L_Xi_u [list   1 1  1] $strainTensor]
  set dEc2 [calcDeltaEc $L_Xi_d $L_Xi_u [list  -1 1  1] $strainTensor]
  set dEc3 [calcDeltaEc $L_Xi_d $L_Xi_u [list   1 1 -1] $strainTensor]
  set dEc4 [calcDeltaEc $L_Xi_d $L_Xi_u [list  -1 1 -1] $strainTensor]

  set L_Eshift1 [expr $L_Eshift0 + $dEc1]; 
  set L_Eshift2 [expr $L_Eshift0 + $dEc2]; 
  set L_Eshift3 [expr $L_Eshift0 + $dEc3]; 
  set L_Eshift4 [expr $L_Eshift0 + $dEc4];
  
  Physics region=$regionName ValleyModel name=L1 Eshift=$L_Eshift1
  Physics region=$regionName ValleyModel name=L2 Eshift=$L_Eshift2
  Physics region=$regionName ValleyModel name=L3 Eshift=$L_Eshift3
  Physics region=$regionName ValleyModel name=L4 Eshift=$L_Eshift4
  puts "...L1 Eshift = $L_Eshift1"
  puts "...L2 Eshift = $L_Eshift2"
  puts "...L3 Eshift = $L_Eshift3"
  puts "...L4 Eshift = $L_Eshift4"


  # Gamma valley
  set GammaC_Eshift0 [piecewiseLinearInterp $BandParamTable GammaC_Eshift $xMolefrac]
  set GammaC_Xi_d    [piecewiseLinearInterp $BandParamTable GammaC_Xi_d   $xMolefrac]

  set dEc [calcDeltaEc $GammaC_Xi_d 0.0 [list 0 0 1] $strainTensor]

  set GammaC_Eshift [expr $GammaC_Eshift0 + $dEc]
  
  Physics region=$regionName ValleyModel name=GammaC Eshift=$GammaC_Eshift
  puts "...GammaC Eshift = $GammaC_Eshift"
}

