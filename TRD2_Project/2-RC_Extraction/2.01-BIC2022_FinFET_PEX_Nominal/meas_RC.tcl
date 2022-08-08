################################################################################
##                       SYNOPSYS CONFIDENTIAL                                ##
## This is an unpublished, proprietary work of Synopsys, Inc., and is fully   ##
## protected under copyright and trade secret laws. You may not view, use,    ##
## disclose, copy, or distribute this file or any information contained       ##
## herein except pursuant to a valid written license from Synopsys.           ##
##                                                                            ##
## Copyright (C) 2014-2020 by Synopsys, Inc.                                  ##
################################################################################

### UTILITIES ###

# Returns true if $q is a tuple of two, where first is a number.
proc maybe_quantity { q } {
    set len [llength $q]
    if { $len != 2 } {
        return 0
    }
    if { [catch { set num [expr double([lindex $q 0])] }] } {
        return 0
    }
    return 1
}

# Note: a value from the Process Explorer material library typically is a tuple
# (value, unit), but in case the user set up his properties as string, it is
# just a single value which when converted to number is assumed to also be of
# unit ohm*m in case of Resistivity.
# If the $val looks like it already is a tuple (value,unit), it is returned as-is.
proc quantity_from_string {val unit} {
    if { [catch { set num [expr double($val)] }] } {
        set maybe_q [maybe_quantity $val]
        if { $maybe_q } {
            return $val
        } else {
            error "value \"$val\" is not a quantity"
        }
    } else {
        return [list $num $unit]
    }
}

# print meas_RC version number
proc measRCVersion {} {
    puts "meas_RC.tcl version 2.5 (R-2020.09)"
}

### meas_RC rcfx function body ###

proc meas__RCExec_rcfx {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    global tcl_platform

    # Windows is not supported right now, return early.
    if {[string equal $tcl_platform(os) "Windows NT"]} {
        echo "NOTE: meas_RC with Approach=[dict get $in Approach] is not supported on $tcl_platform(os)."
	exit 1
        return [dict create]
    }
    puts ""

    # 
    array set rfxobj {}

    # Default settings
    defaultSettings $in $doeIdParam $routeIdParam $flowIdParam $moduleIdParam $stepIdParam

    # Import settings from user configuration file
    if {[info exists rfxobj(configFile)]&&[file exists $rfxobj(configFile)]} {
	userSettingsFromConfigFile $in $doeIdParam $routeIdParam $flowIdParam $moduleIdParam $stepIdParam
    }

    # Import user settings from PE
    userSettingsFromPECMDFile $in $doeIdParam $routeIdParam $flowIdParam $moduleIdParam $stepIdParam

    # Backward compatibility
    if {$rfxobj(backwardCompatible)!=0} {
	backwardCompatibility $in $doeIdParam $routeIdParam $flowIdParam $moduleIdParam $stepIdParam
    }

    # Output settings 
    printMessage "Default + User settings + Backward compatibility (if apply):"   
    putsPrintList
    # printSettings $in $doeIdParam $routeIdParam $flowIdParam $moduleIdParam $stepIdParam

    # Retrieve data from PE
    retrieveDatafromPE $in $doeIdParam $routeIdParam $flowIdParam $moduleIdParam $stepIdParam

    # Retrieve material parameters from PE
    retrieveMatParamsfromPE $in $doeIdParam $routeIdParam $flowIdParam $moduleIdParam $stepIdParam

    # 
    resolveParamsConflict $in $doeIdParam $routeIdParam $flowIdParam $moduleIdParam $stepIdParam

    # Retrieve and process contacts
    retrieveContactfromPE $in $doeIdParam $routeIdParam $flowIdParam $moduleIdParam $stepIdParam

    # Compute number.of.tiles according to the domain size and the tile size
    if {$rfxobj(autoTilingForCapacitance)==1} {
	autoTilingForCapacitance
    }

    # Export $rfxobj(toolName) command file
    set fsi [open $rfxobj(commandFile) w]
    set rfxobj(fsi) $fsi
    set rfxobj(fsi2) $fsi
    set rfxobj(fsi3) $fsi
    if {$rfxobj(splitRaphaelCommand)==1||$rfxobj(splitRaphaelCommand)==2} {
	set rfxobj(fsi2) [open $rfxobj(settingFile) w]
    }
    if {$rfxobj(splitRaphaelCommand)==2} {
	set rfxobj(fsi3) [open $rfxobj(solveFile) w]
    }
    exportRaphaelCommand $in $doeIdParam $routeIdParam $flowIdParam $moduleIdParam $stepIdParam
    close $rfxobj(fsi)
    if {$rfxobj(splitRaphaelCommand)==1||$rfxobj(splitRaphaelCommand)==2} {
	close $rfxobj(fsi2)
    }
    if {$rfxobj(splitRaphaelCommand)==2} {
	close $rfxobj(fsi3)
    }

    if {$rfxobj(splitRaphaelCommand)==1} {
	if {$rfxobj(verbose)>=3} {
	    printMessage "Export $rfxobj(toolName) setting file: $rfxobj(settingFile)"
	    puts [exec cat -n $rfxobj(settingFile)]
	    puts ""
	}
    }
    if {$rfxobj(verbose)>=3} {
	printMessage "Export $rfxobj(toolName) command file: $rfxobj(commandFile)"
	puts [exec cat -n $rfxobj(commandFile)]
	puts ""
    }

    # Export contacts to file?
    if {$rfxobj(keyGenCnt)} {
	set fi [open $rfxobj(contactFile) "w"]
	if {$rfxobj(extractType)=="capacitance"} {
	    exportContact2FileforCapacitance $fi
	} else {
	    exportContact2FileforResistance $fi
	}
	close $fi
	if {$rfxobj(verbose)>=3} {
	    printMessage "Export contact file: $rfxobj(contactFile):"
	    puts [exec cat -n $rfxobj(contactFile)]
	    puts ""
	}
    }

    # Tdr only?
    if {$rfxobj(keyTdrOnly)==1} {
	if {$rfxobj(verbose)>=0} {
	    printMessage "Tdr and $rfxobj(toolName) command file are generated. We now exit meas_RC function."
	    puts ""
	}
        return [dict create]	
    }

    # Other checks before calling Raphael?

    # Call Raphael 
    printMessage "Call $rfxobj(toolName) to solve:"
    array set tmp [list \
	"$rfxobj(toolName) binary:" $rfxobj(raphaelBinaryForPE) \
	"$rfxobj(toolName) command file:" $rfxobj(commandFile) \
	"$rfxobj(toolName) log file:" $rfxobj(logFile) \
		   ]
    putsArray "  " tmp
    printMessage "$rfxobj(toolName) is in working. Check the progress in the log file $rfxobj(logFile) ...\n"
    set logOUTRaphael [eval exec -ignorestderr $rfxobj(raphaelBinaryForPE) $rfxobj(commandFile)]
    # if {[catch {eval exec $rfxobj(raphaelBinaryForPE) $rfxobj(commandFile)} logOUTRaphael]} {
    # 	puts "$rfxobj(toolName) exits with the following error:\n"
    # 	puts $logOUTRaphael
    # 	if {$rfxobj(errorOutWhenRaphaelFail)==1} {
    # 	    exit 1
    # 	} else {
    # 	    return [dict create]	
    # 	}
    # }

    # Return to Process Explorer
    printMessage "$rfxobj(toolName) ends successfully. The following results are returned to Process Explorer:"   
    processRaphaelResult4PE
    putsList "  " $rfxobj(spiResult)

    puts $logOUTRaphael
    puts ""

    if {$rfxobj(Revin)<6} {
	return [dict set out out_rc $rfxobj(spiResult)]
    } 

    return [dict set out Output $rfxobj(spiResult)]
     
}

proc resolveParamsConflict {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    upvar rfxobj rfxobj
    # if keyTdrOnly==0, do not split Raphael command file
    if {$rfxobj(keyTdrOnly)==0} {
	set rfxobj(splitRaphaelCommand) 0
    }
    
    set rootFileName $rfxobj(rootFileName)
    set postfixName $rfxobj(postfixName)
    set rfxobj(commandFile) ${rootFileName}_${postfixName}.cmd
    set rfxobj(settingFile) ${rootFileName}_${postfixName}.tcl
    set rfxobj(solveFile) ${rootFileName}_${postfixName}.con
    set rfxobj(logFile) ${rootFileName}_${postfixName}.log
    set rfxobj(finalTdrFile) ${rootFileName}_${postfixName}.tdr
    set rfxobj(contactFile) ${rootFileName}_cnt.tcl

    set rfxobj(autoSegmentForResistanceCapacitance) 1
    set rfxobj(verbose) 0  
}

proc autoTilingForCapacitance {} {
    upvar rfxobj rfxobj
    foreach "xmin ymin xmax ymax" $rfxobj(bbox) {}
    set width [expr $xmax-$xmin]
    set height [expr $ymax-$ymin]
    set width [expr int(($width+$rfxobj(autoTilingAmbitSize))/$rfxobj(autoTilingTileSize))]
    set height [expr int(($height+$rfxobj(autoTilingAmbitSize))/$rfxobj(autoTilingTileSize))]
    if {$width<1} {
	set width 1
    }
    if {$height<1} {
	set height 1
    }
    set numberoftiles [expr $width*$height]
    if {$numberoftiles<1} {
	set numberoftiles 1
    }
    if {$numberoftiles!=1&&$numberoftiles%2==1} {
	incr numberoftiles 1
    }    
    set rfxobj(autoTilingNumberOfTiles) $numberoftiles
}

proc defaultSettings {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    upvar rfxobj rfxobj
    set rfxobj(PEVersion) [version]
    set rfxobj(Revin) [dict get $in rev]
    set rfxobj(measRCVersion) "2.5 (R-2020.09)"
    set defaultSettings {
	allowMatParamsFromFile 1
	allowMatParamsFromMeasRC 0
	allowMatParamsFromPEDB 0
	autoSegmentForResistance 0
	autoSegmentForResistanceCapacitance 1
	autoTilingAmbitSize 0.1
	autoTilingForCapacitance 1
	autoTilingTileSize 0.2
	backwardCompatible 0
	errorOutWhenRaphaelFail 1
	includeSettingInCommand 0
	keyGenCnt 0
	keyTdrOnly 0
	materialParamsFile MaterialParams.tcl
	postfixName rcfx
	raphaelBinaryForPE "raphael_fx rfcx"
	refineContact 0
	refineContactType box
	regionHandlingFile RegionHandling.tcl
	rootFileName ""
	splitRaphaelCommand 0
	toolName "Raphael FX"
	toolRelease "R-2020.09"
	verbose 0
	printRCModelList na
	userPostProcessingFunction userPostProcessingFunction
	lumpAllConductorsForCapacitance 1
	allowMatAlias 1
	mergeLumpedMaterialForCapacitance 0
	contactAttachment {}
	printMaterialPropertiesToLogFile 0
	contactSpecs {}
    }

    set rfxobj(defaultSettings) $defaultSettings
    foreach "var val" $defaultSettings {
	set rfxobj($var) $val
    }
    
    # Configuration file
    # 
    global env
    if {[info exists env(PERaphaelConfigFile)]} {
	set rfxobj(configFile) $env(PERaphaelConfigFile)
    }     
    if {[file exists PERaphaelConfig.tcl]} {
 	set rfxobj(configFile) PERaphaelConfig.tcl 
    }
    global PERaphaelConfigFile
    if {[info exists PERaphaelConfigFile]} {
	set rfxobj(configFile) $PERaphaelConfigFile
    }     
    if {![info exists rfxobj(configFile)]} {
	puts "Warning: PERaphaelConfig file location could not be deduced! Use all default settings"
	puts "Warning: You can set the path to PERaphaelConfig file:"
	puts "Warning:   1. By an environmental variable \"PERaphaelConfigFile\""
	puts "Warning:   2. Place file \"PERaphaelConfig.tcl\" in the project directory"
	puts "Warning:   3. By a global variable \"PERaphaelConfigFile\" before invoking meas_RC step function in Process Explorer"
    } elseif {![file exists $rfxobj(configFile)]} {
	puts "Warning: User-specified PERaphaelConfig file \"$rfxobj(configFile)\" does not exists!"
    } else {
	puts "Found PERaphaelConfig file \"$rfxobj(configFile)\" ok"
    }
    puts ""

    set printList {
	measRCVersion
	allowMatParamsFromFile
	allowMatParamsFromMeasRC
	allowMatParamsFromPEDB
	autoSegmentForResistance
	autoTilingAmbitSize
	autoTilingForCapacitance
	autoTilingTileSize
	backwardCompatible
	keyGenCnt
	keyTdrOnly
	materialParamsFile
	raphaelBinaryForPE
	refineContact
	splitRaphaelCommand
    }
    foreach var "PEVersion Revin measRCVersion" {
	lappend printList $var
    }
    set printList [lsort -unique $printList]
    set rfxobj(printList) $printList
    printMessage "Default settings by tool:"   
    putsPrintList

    return [array get rfxobj]
}

proc backwardCompatibility {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    upvar rfxobj rfxobj
    set varList [list]
    set files {
	keyTdrOnly 
	keyGenCnt 
	run.raphael
	MathSettings.tcl 
	RC_DistProcessing.tcl 
	MaterialParams.tcl 
	C_MaterialParams.tcl 
	R_MaterialParams.tcl
	BNDExtraction.tcl
	MeshSettings.tcl
	C_MeshSettings.tcl
	R_MeshSettings.tcl
	C_MergeMaterials.tcl
	R_MergeMaterials.tcl
	R_ContactSize.tcl
	RC_LumpedMaterials.tcl
	RC_ExcludeCap.tcl
	PrintDistRC.tcl
	RC_PrintRC.tcl
    }
    set files [lsort -unique $files]
    foreach f $files {
	if { [file exists $f] } {
	    set rfxobj($f) 1
	    lappend varList "[format "%30s" $f]     exists"
	} else {
	    if {$f=="keyTdrOnly"||$f=="keyGenCnt"} {
#		set rfxobj($f) 0
		lappend varList "[format "%30s" $f] not exists; take setting from $rfxobj(configFile)"
	    } else {
		set rfxobj($f) 0
		lappend varList "[format "%30s" $f] not exists"
	    }
	}
    }
    if {$rfxobj(run.raphael)==1} {
       set cmd_raph [exec cat ./run.raphael | grep -v "^ *#" | grep -v "^ *$"]
       if { [exec echo $cmd_raph | wc -l] == 1 } {
    	   set rfxobj(raphaelBinaryForPE) "$cmd_raph"
       }	
    }
    printMessage "Backward compatibility:"
    putsList "" $varList

    return [array get rfxobj]
}

proc userSettingsFromConfigFile {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    upvar rfxobj rfxobj

    # Dump the config file
    if {$rfxobj(verbose)>=3} {
	printMessage "$rfxobj(configFile):"
	puts [exec cat -n $rfxobj(configFile)]
	puts ""
    }

    set varList [list]
    foreach "var val" $rfxobj(defaultSettings) {
	set val [extractVarFromConfigFile $var $rfxobj(configFile)]
	if {$val!="variableNotFound"} {
	    set rfxobj($var) $val
	    lappend varList [list $var $val]
	}
    }

    set varList [lsort -unique $varList]
    printMessage "Settings in configuration file $rfxobj(configFile):"
    putsList "" $varList
    
    return [array get rfxobj]
}

proc userSettingsFromPECMDFile {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    upvar rfxobj rfxobj

    set varList [list]
    foreach "var val" $rfxobj(defaultSettings) {
	global $var
	if {[info exists $var]} {
	    set val [set $var]
	    set rfxobj($var) $val
	    lappend varList [list $var $val]
	}
    }
    
    set varList [lsort -unique $varList]
    printMessage "Settings inside Process Explorer:"
    putsList "" $varList

    return [array get rfxobj]
}

proc exportRaphaelCommand {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    upvar rfxobj rfxobj
    set fsi $rfxobj(fsi)
    set fsi2 $fsi
    set fsi3 $fsi
    if {$rfxobj(splitRaphaelCommand)==1||$rfxobj(splitRaphaelCommand)==2} {
	set fsi2 $rfxobj(fsi2)
    }    
    if {$rfxobj(splitRaphaelCommand)==2} {
	set fsi3 $rfxobj(fsi3)
    }    
    set rootFileName $rfxobj(rootFileName)

    exportComment $fsi2 "Command file exported by Process Explorer for $rfxobj(toolName) $rfxobj(toolRelease)"
    exportComment $fsi2 "Process Explorer Version: $rfxobj(PEVersion)"
    exportComment $fsi2 "meas_RC Version: $rfxobj(measRCVersion)"  
    exportComment $fsi2 "[exec date]"  
    exportLine $fsi2 ""

    exportComment $fsi2 "Data from Process Explorer"  
    set rfxobj(materials) [lsearch -all -inline -not -exact $rfxobj(material_names) Gas]
     foreach var "bbox extractType rout_id flow_id  modu_id step_id rootFileName tdrFileName materials" {
	exportLine $fsi2 "set $var \"$rfxobj($var)\""	
    }
    exportLine $fsi2 ""

    exportContactCoordsforResistance $fsi2

    if {$rfxobj(autoTilingForCapacitance)==1} {
	exportComment $fsi2 "Estimated number of tiles for capacitance extraction" 
	exportComment $fsi2 "  Domain: {$rfxobj(bbox)}" 
	exportComment $fsi2 "  Tile size: $rfxobj(autoTilingTileSize)" 
	exportComment $fsi2 "  Ambit size: $rfxobj(autoTilingAmbitSize)" 
	exportLine $fsi2 "set numberOfTiles $rfxobj(autoTilingNumberOfTiles)" 
	exportLine $fsi2 "set tileSize $rfxobj(autoTilingTileSize)" 
	exportLine $fsi2 "set ambitSize $rfxobj(autoTilingAmbitSize)" 
	exportLine $fsi2 "" 
    }

    # if {$rfxobj(regionHandlingFile)!=""} {
    # 	exportComment $fsi2 "$rfxobj(regionHandlingFile) includes procedures used by the commands in this file"  
    # 	exportSourceFile $fsi2 $rfxobj(regionHandlingFile)
    # 	exportLine $fsi2 ""
    # }

    exportComment $fsi2 "Math Settings"  
    exportLine $fsi2 "math coord.ucs"	     
    exportLine $fsi2 ""
    exportBackwardCompatibleSourceFile $fsi2 MathSettings.tcl
    exportBackwardCompatibleSourceFile $fsi2 RC_DistProcessing.tcl "capacitance resistance_capacitance"

    # exportComment $fsi2 "Deal with aliases"  
    # exportLine $fsi2 "set alias_off 1"	     
    # exportLine $fsi2 ""

    # optionally shut down aliases 04/30/2020
    exportComment $fsi2 "Turn on/off material aliases to allow/disallow automatic material conversion" 
    exportComment $fsi2 "Want material aliases? \"set allowMatAlias 1\" in \"PERaphaelConfig.tcl\""
    exportComment $fsi2 "Do not want material aliases? \"set allowMatAlias 0\" in \"PERaphaelConfig.tcl\""
    if {$rfxobj(allowMatAlias)==0} {
	exportComment $fsi2 "The following code section turns off material aliases"
 	exportLine $fsi2 "foreach mat \$materials {"
	exportLine $fsi2 "    LogFile \"alias \$mat \$mat\""     
	exportLine $fsi2 "    alias \$mat \$mat"     
	exportLine $fsi2 "}" 
    } else {
	exportComment $fsi2 "Material aliases are allowed by this simulation"
    }   
    exportLine $fsi2 ""

    exportComment $fsi2 "Material properties from Process Explorer database"
    if {$rfxobj(allowMatParamsFromPEDB)==1} {
	if {[llength $rfxobj(dbpermittivities)]==0&&[llength $rfxobj(dbconductivities)]==0} {
	    exportComment $fsi2 "N/A"
	}
	foreach "mat par" $rfxobj(dbconductivities) {
	    if {$par<0.01} {		
		exportLine $fsi2 "mater add name= $mat new.like= Oxide"
	    } else {
		exportLine $fsi2 "mater add name= $mat new.like= Copper"
	    }
	    exportLine $fsi2 "pdbSet $mat Potential Conductivity $par"
	}
	foreach "mat par" $rfxobj(dbpermittivities) {
	    exportLine $fsi2 "pdbSet $mat Potential Permittivity $par"
	}
    } else {
	exportComment $fsi2 "Disabled"
    }
    exportLine $fsi2 ""

    exportComment $fsi2 "Material properties from $rfxobj(materialParamsFile)"
    if {$rfxobj(allowMatParamsFromFile)==1} {
	exportSourceFile $fsi2 $rfxobj(materialParamsFile)
	exportLine $fsi2 ""
	exportBackwardCompatibleSourceFile $fsi2 C_MaterialParams.tcl "capacitance resistance_capacitance"
	exportBackwardCompatibleSourceFile $fsi2 R_MaterialParams.tcl "resistance resistance_capacitance"
    }
    
    exportComment $fsi2 "Material properties from the meas_RC function"
    if {$rfxobj(allowMatParamsFromMeasRC)==1} {
	if {[llength $rfxobj(funcpermittivities)]==0&&[llength $rfxobj(funcconductivities)]==0} {
	    exportComment $fsi2 "N/A"
	}
	foreach "mat par" $rfxobj(funcconductivities) {
	    if {$par<0.01} {		
		exportLine $fsi2 "mater add name= $mat new.like= Oxide"
	    } else {
		exportLine $fsi2 "mater add name= $mat new.like= Copper"
	    }
	    exportLine $fsi2 "pdbSet $mat Potential Conductivity $par"
	}
	foreach "mat par" $rfxobj(funcpermittivities) {
	    exportLine $fsi2 "pdbSet $mat Potential Permittivity $par"
	}
    } else {
	exportComment $fsi2 "Disabled"
    }
    exportLine $fsi2 ""

    exportComment $fsi2 "Contact size/offset for resistance (or resistance_capacitance) extraction" "resistance resistance_capacitance"
    exportLine $fsi2 "set contact_size 0.01" "resistance resistance_capacitance"
    exportLine $fsi2 "set contact_offset 0.001" "resistance resistance_capacitance"
    exportLine $fsi2 "" "resistance resistance_capacitance"

    if {$rfxobj(refineContact)==1&&($rfxobj(extractType)=="resistance"||$rfxobj(extractType)=="resistance_capacitance")} {
	exportComment $fsi2 "Contact refinement for resistance (or resistance_capacitance) extraction" "resistance resistance_capacitance"    
	exportLine $fsi2 "set contact_refine_size 0.02" "resistance resistance_capacitance"
	exportLine $fsi2 "set contact_refine_offset 0.005" "resistance resistance_capacitance"
	exportLine $fsi2 "set contact_refine 0.005" "resistance resistance_capacitance"
	exportLine $fsi2 "" "resistance resistance_capacitance"	
    }
    
    # exportComment $fsi2 "Print material properties in logfile?" "capacitance resistance_capacitance"
    # exportLine $fsi2 "set print_material_property 0" "capacitance resistance_capacitance"
    # exportLine $fsi2 "" "capacitance resistance_capacitance"

    exportComment $fsi2 "Tile edge refinement" "capacitance resistance_capacitance"
    exportLine $fsi2 "set refine_tile_edge 0" "capacitance resistance_capacitance"
    exportLine $fsi2 "set tile_edge_refine 0.1" "capacitance resistance_capacitance"
    exportLine $fsi2 "" "capacitance resistance_capacitance"

    exportComment $fsi2 "Interface auto contact refinement" "resistance resistance_capacitance"
    exportLine $fsi2 "set refine_auto_contact 0" "resistance resistance_capacitance" 
    exportLine $fsi2 "set auto_contact_refine 0.1" "resistance resistance_capacitance" 
    exportLine $fsi2 "set auto_contact_refine_exclude \"\"" "resistance resistance_capacitance" 
    exportLine $fsi2 "" "resistance resistance_capacitance"

    # exportComment $fsi2 "List to floating conductors" "capacitance resistance_capacitance"
    # exportLine $fsi2 "set floating_conductors {}" "capacitance resistance_capacitance"
    # exportLine $fsi2 "" "capacitance resistance_capacitance"

    exportComment $fsi2 "List of materials/regions for capacitance exclusion" "capacitance resistance resistance_capacitance"
    exportLine $fsi2 "set cap_exclude {}" "capacitance resistance resistance_capacitance"
    exportLine $fsi2 "" "capacitance resistance resistance_capacitance"

    exportComment $fsi2 "Output file name shared by output .spi and .tdr files"
    exportLine $fsi2 "set outputFileName $rfxobj(rootFileName)" 
    exportLine $fsi2 ""

    exportComment $fsi2 "Save the final Tdr?"
    exportLine $fsi2 "set saveFinalTdr 1" 
    exportLine $fsi2 ""

    exportComment $fsi2 "Mesh settings"
    exportLine $fsi2 "refinebox clear"  
    exportLine $fsi2 "pdbSet Grid SnMesh min.normal.size 0.005"
    exportLine $fsi2 "refinebox name= interface interface.materials= \{All All\}"  
    exportLine $fsi2 "pdbSet Grid SnMesh MaxPoints 50000000"
    exportLine $fsi2 "pdbSet Grid SnMesh AllowRegionMismatch 1"
    exportLine $fsi2 ""

    exportComment $fsi2 "Boundary extraction settings"
    exportLine $fsi2 "boundary spx2brep.method= Standard"
    exportLine $fsi2 "boundary spx2brep.advanced.vertical.resolution= 0.5"
    exportLine $fsi2 "boundary spx2brep.advanced.tolerance= 0.1"
    exportLine $fsi2 "boundary spx2brep.advanced.vertical.aspect.ratio= 10"
    exportLine $fsi2 "boundary spx2brep.standard.accuracy= 0.2"
    exportLine $fsi2 "boundary spx2brep.standard.decimation= false"
    exportLine $fsi2 "boundary spx2brep.standard.decimation.accuracy= 1e-8"
    exportLine $fsi2 "boundary spx2brep.standard.decimation.shortest.edge= 1e-8"
    exportLine $fsi2 "boundary spx2brep.standard.decimation.ridge.angle= 150"
    exportLine $fsi2 ""
    exportBackwardCompatibleSourceFile $fsi2 BNDExtraction.tcl

    if {[info exists rfxobj(configFile)]} {
        exportComment $fsi2 "Include user settings from configuration file $rfxobj(configFile)"
        exportSourceFile $fsi2 $rfxobj(configFile)
        exportLine $fsi2 ""
    }

    if {$rfxobj(splitRaphaelCommand)==1&&$rfxobj(includeSettingInCommand)==1} {
	exportComment $fsi "Source $rfxobj(toolName) setting file: $rfxobj(settingFile)"  
	exportSourceFile $fsi $rfxobj(settingFile)
	exportLine $fsi ""
    }
    
    # mode command moved to here 20200530 Zudian
    exportComment $fsi3 "Mode of extraction: capacitance|resistance|{capacitance resistance}"  
    exportLine $fsi3 "mode $rfxobj(mode)" "resistance"  
#    exportLine $fsi3 "mode $rfxobj(mode) floating= {\$floating_conductors}" "capacitance"  
    exportLine $fsi3 "mode $rfxobj(mode)" "capacitance"  
    exportLine $fsi3 "mode $rfxobj(mode)" "resistance_capacitance"  
    exportLine $fsi3 ""   

    exportComment $fsi3 "For capacitance extraction" capacitance
    exportLine $fsi3 "SetChangeMaterials" capacitance
    exportLine $fsi3 "pdbSetBoolean Grid Check.Duplicate.Name 0" capacitance
    exportLine $fsi3 "" capacitance
   
    exportComment $fsi3 "Turn off region merging before loading tdr"  
    exportLine $fsi3 "pdbSet Grid No3DMerge 1"
    exportLine $fsi3 ""
    
    exportComment $fsi3 "Load the tdr structure generated by Process Explorer"  
    # exportLine $fsi3 "init tdr= $rfxobj(tdrFileName) Copper change.material min.vol.material= Gas" capacitance
    # exportLine $fsi3 "init tdr= $rfxobj(tdrFileName)" "resistance resistance_capacitance"
    if {$rfxobj(lumpAllConductorsForCapacitance)==1} {
	exportLine $fsi3 "init tdr= \$tdrFileName Copper change.material min.vol.material= Gas" capacitance
    } else {
	exportLine $fsi3 "init tdr= \$tdrFileName min.vol.material= Gas" capacitance
    }
    exportLine $fsi3 "init tdr= \$tdrFileName" "resistance resistance_capacitance"
    exportLine $fsi3 ""

    exportComment $fsi3 "Special characters in material names are replaced, \"_\" by \"UU\", \".\" by \"DD\", and \"+\" by \"PP\""  
    exportComment $fsi3 "For example, Oxide.Nitride --> OxideDDNitride, Oxide_3 --> OxideUU3 Silicon+N --> SiliconPPN"  
    exportComment $fsi3 "You must remove the old material and define the new material properties in $rfxobj(materialParamsFile)"  
    exportLine $fsi3 "set regMatlist \[region region.material.map\]"
    exportLine $fsi3 "checkMaterialName \$regMatlist"
    exportLine $fsi3 ""
    
    exportComment $fsi3 "Are all material properties properly defined?"  
    exportLine $fsi3 "set regMatlist \[region region.material.map\]"
    exportLine $fsi3 "checkMaterialProperty \$regMatlist"
    exportLine $fsi3 ""

    exportComment $fsi3 "Print material properties"
    exportComment $fsi3 "Check conductivity to be non-zero"
    if {$rfxobj(printMaterialPropertiesToLogFile)==1} {
	printCheckMaterialPropertyCommand $fsi3
    }
    exportLine $fsi3 ""
      
    exportComment $fsi3 "Turn region merging back on"  
    exportLine $fsi3 "pdbSet Grid No3DMerge 0"
    exportLine $fsi3 ""
    
    # exportComment $fsi3 "Merge coductors according to lumped materials definition in varible lumpedmaterials" capacitance 
    # exportComment $fsi3 "Useful for capacitance extraction where user wants to merge conductors selectively" capacitance 
    # exportComment $fsi3 "To use the feature, set lumpAllConductorsForCapacitance 0 in \"$rfxobj(configFile)\" to prevent all materials merged together"  capacitance
    # exportLine $fsi3 "if {\[info exists lumpedmaterials\]} {" capacitance
    # exportLine $fsi3 "    mergeLumpedMaterials \$lumpedmaterials" capacitance 
    # exportLine $fsi3 "}" capacitance 
    # exportLine $fsi3 "" capacitance
    
    exportComment $fsi3 "Change the long region names into short names starting with the material name followed by a serial counter"
    exportLine $fsi3 "array set regionnames {}"
    foreach contact [lsort -index 2 -unique $rfxobj(filtered_contact_names)] {
	set pin_region_name [lindex $contact 2]
	exportLine $fsi3 "set regionnames($pin_region_name) $pin_region_name"
    }    
    exportLine $fsi3 "set no3dmerge \[pdbGet Grid No3DMerge\]"
    exportLine $fsi3 "changeRegionName \$regMatlist \$no3dmerge"
    exportLine $fsi3 "" 

    exportBackwardCompatibleSourceFile $fsi3 C_MergeMaterials.tcl "capacitance resistance_capacitance"
    exportBackwardCompatibleSourceFile $fsi3 R_MergeMaterials.tcl "resistance resistance_capacitance"

    exportComment $fsi3 "Keep track of regions"
    exportLine $fsi3 "TakeRegionSnapshot"
    exportLine $fsi3 ""     

    exportBackwardCompatibleSourceFile $fsi3 MeshSettings.tcl
    exportBackwardCompatibleSourceFile $fsi3 C_MeshSettings.tcl "capacitance resistance_capacitance"
    exportBackwardCompatibleSourceFile $fsi3 R_MeshSettings.tcl "resistance resistance_capacitance"	
      
    if {$rfxobj(refineContact)==1&&($rfxobj(extractType)=="resistance"||$rfxobj(extractType)=="resistance_capacitance")} {
	 exportComment $fsi3 "Contact refinement"
	 exportRefineboxforContact $fsi3
	 exportLine $fsi3 "" 
    }

    exportComment $fsi3 "Refine tile edge" "capacitance resistance_capacitance"
    exportLine $fsi3 "if {\$refine_tile_edge==1} {" "capacitance resistance_capacitance"
    exportLine $fsi3 "    ambitRefinement \$tile_edge_refine" "capacitance resistance_capacitance" 
    exportLine $fsi3 "}" "capacitance resistance_capacitance" 
    exportLine $fsi3 "" "capacitance resistance_capacitance" 

    exportComment $fsi3 "Interface auto contact refinement" "resistance resistance_capacitance"
    exportLine $fsi3 "if {\$refine_auto_contact==1} {" "resistance resistance_capacitance"
    exportLine $fsi3 "    autoContactRefinement \$auto_contact_refine \$auto_contact_refine \$auto_contact_refine \$auto_contact_refine_exclude" "resistance resistance_capacitance" 
    exportLine $fsi3 "}" "resistance resistance_capacitance" 
    exportLine $fsi3 "" "resistance resistance_capacitance"

    exportComment $fsi3 "Create the mesh" "capacitance resistance resistance_capacitance"
    exportLine $fsi3 "grid remesh info=2" "capacitance resistance resistance_capacitance"
    exportLine $fsi3 "" "capacitance resistance resistance_capacitance" 

    exportBackwardCompatibleSourceFile $fsi3 R_ContactSize.tcl "resistance resistance_capacitance"

    exportComment $fsi3 "Rename regions according to the text labels from Process Explorer" capacitance
    exportComment $fsi3 "Define contacts according to the text labels from Process Explorer" "resistance resistance_capacitance"
    if {$rfxobj(extractType)=="capacitance"} {
	exportContactforCapacitance $fsi3
    }
    if {$rfxobj(extractType)=="resistance"||$rfxobj(extractType)=="resistance_capacitance"} {
	exportContactforResistance $fsi3
    }

    if {$rfxobj(splitRaphaelCommand)==1&&$rfxobj(includeSettingInCommand)==2} {
	exportComment $fsi3 "Source $rfxobj(toolName) solve file: $rfxobj(solveFile)"  
	exportSourceFile $fsi3 $rfxobj(solveFile)
	exportLine $fsi3 ""
    }

    exportBackwardCompatibleSourceFile $fsi RC_LumpedMaterials.tcl "resistance resistance_capacitance"

    exportComment $fsi "Solve the problem"
    exportLine $fsi "solve"           
    exportLine $fsi ""  

    exportBackwardCompatibleSourceFile $fsi RC_ExcludeCap.tcl "resistance_capacitance"

    exportBackwardCompatibleSourceFile $fsi PrintDistRC.tcl "resistance_capacitance"
    exportBackwardCompatibleSourceFile $fsi RC_PrintRC.tcl 

    exportNetlist $fsi
   
    exportComment $fsi "Save the final tdr"
    exportLine $fsi "if {\$saveFinalTdr==1} {"       
    exportLine $fsi "    struct tdr= \${outputFileName}_$rfxobj(postfixName).tdr"       
    exportLine $fsi "}"       
    exportLine $fsi ""   
    
    exportLine $fsi "CHECKOFF"       
    exportComment $fsi "Call postprocessing function by user"
    exportLine $fsi "set returnvalue {}"       
    exportLine $fsi "if {\[info procs $rfxobj(userPostProcessingFunction)\]!=\"\"} {"       
    exportLine $fsi "    set returnvalue \[$rfxobj(userPostProcessingFunction)\]"       
    exportLine $fsi "}"       
    exportLine $fsi "CHECKON"       
    exportLine $fsi ""       
}

proc extractVarFromConfigFile { varName configFileName } {
    set error [catch {exec grep -s $varName $configFileName} lines]
    if {$error} {
	return "variableNotFound"
    }
    set lines [split $lines "\n"]
    set value ""
    foreach line $lines {
	if {[lindex $line 0]=="set"&&[lindex $line 1]=="$varName"} {
	    set value [lindex $line 2]
	    set value [string trimright $value ";"]
	}
    }
    return $value
}

proc processRaphaelResult4PE {} {
    upvar rfxobj rfxobj
    set rootFileName $rfxobj(rootFileName)
    set spiFileName ${rootFileName}.cMatrix.spi
    set spiSearchKey C_
    set tagForReturnValue capacitance
    if {$rfxobj(extractType)=="resistance"||$rfxobj(extractType)=="resistance_capacitance"} {
	set spiFileName ${rootFileName}.rMatrix.spi
	set spiSearchKey R_
	set tagForReturnValue resistance
    } 
    if {$rfxobj(extractType)=="resistance_capacitance"} {
	set spiFileName ${rootFileName}.rcMatrix.spi
    }
    set rfxobj(spiFileName) $spiFileName
    set rfxobj(spiSearchKey) $spiSearchKey
    set rfxobj(tagForReturnValue) $tagForReturnValue
    
    if {![file exists $rfxobj(spiFileName)]} {
	printErrorMessage "Cannot find the .spi file $rfxobj(spiFileName). Check $rfxobj(toolName) logfile $rfxobj(logFile)"
    }
    
    set spiResult [list]
    set fId [open $rfxobj(spiFileName) r]
    set lines [read $fId]
    close $fId
    set lines [split $lines "\n"] 
    set spiSearchKey $rfxobj(spiSearchKey)
    foreach line $lines {
	set key [lindex $line 0]
	if {!([string match "C_*" $key]||[string match "R_*" $key])} {
	    continue
	}
	if {[string eq inf [lindex $line 3]]||[lindex $line 3]>1e10} {
	    continue
	}
	if {$rfxobj(Revin)<21} {
	    lappend spiResult [list $rfxobj(tagForReturnValue) [lindex $line 1] [lindex $line 2] [lindex $line 3]]
	} else {
	    if {[string match "R_*" $key]} {		    
		lappend spiResult [list resistance [lindex $line 1] [lindex $line 2] "[lindex $line 3] ohm"]
	    } else {
		lappend spiResult [list capacitance [lindex $line 1] [lindex $line 2] "[lindex $line 3] F"]
	    } 
	}
    }

    set maxReturnItems 100
    set rfxobj(maxReturnItems) $maxReturnItems
    if {[llength $spiResult]>$rfxobj(maxReturnItems)} {
	set spiResult [lrange $spiResult 0 [expr $rfxobj(maxReturnItems)-1]] 
    }
    set rfxobj(spiResult) $spiResult

    return [array get rfxobj] 
}

proc retrieveContactfromPE {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    upvar rfxobj rfxobj

    set rfxobj(original_contact_names) [dict get $rfxobj(response) filtered_contact_names]
    set filtered_contact_names $rfxobj(original_contact_names)

    # escape "(" and ")" in contact names and format the numbers 
    set filtered_contact_coords [list]
    foreach contact $filtered_contact_names {
        set pin_coord [lindex $contact 6]
        set pnx [catch {set pin_x [format {%0.4f} [lindex $contact 6 0]]} fmx]
        set pny [catch {set pin_y [format {%0.4f} [lindex $contact 6 1]]} fmy]
        set pnz [catch {set pin_z [format {%0.4f} [lindex $contact 6 2]]} fmz]
        if {$pnx||$pny||$pnz} { 
	    puts "ERROR: contact $pin_name coordinates missing. Aborting"
	    puts $contact
	    exit 1
	}

	set pin_region_name [lindex $contact 2]
	set pin_region_name [regsub -all {\(} $pin_region_name {\\(}]
	set pin_region_name [regsub -all {\)} $pin_region_name {\\)}]
	set contact [lreplace $contact 2 2 $pin_region_name]

	set xyz [lindex $contact 6]
	set x [format "%.4f" [lindex $xyz 0]]
	set y [format "%.4f" [lindex $xyz 1]]
	set z [format "%.4f" [lindex $xyz 2]]
	set contact [lreplace $contact 6 6 [list $x $y $z]]
	lappend filtered_contact_coords $contact
    }
    set filtered_contact_names $filtered_contact_coords
 
    # remove contacts outside the domain clip
    foreach "xmin ymin xmax ymax" $rfxobj(bbox) {}
    set filtered_contact_coords [list]
    foreach contact $filtered_contact_names {
	set c [lindex $contact 3]
	set xyz [lindex $contact 6]
	set x [lindex $xyz 0]
	set y [lindex $xyz 1]
	set z [lindex $xyz 2]
	if {$x>=$xmin&&$x<=$xmax&&$y>=$ymin&&$y<=$ymax} {
	    lappend filtered_contact_coords $contact
	} else {
	    puts "  $c {$x $y $z} is outside the clip"
	}
    }
    set filtered_contact_names $filtered_contact_coords

    # remove duplicates for resistance/resistance_capacitance extraction
    # 1. contacts with either same name or same x/y location are allowed, but not both
    # 2. if multiple contacts share same name and x/y location, keep the last one
    if {$rfxobj(extractType)=="resistance"||$rfxobj(extractType)=="resistance_capacitance"} {
	set filtered_contact_coords [list]
	for {set i [expr [llength $filtered_contact_names]-1]} {$i>=0} {incr i -1} {
	    set contact2 [lindex $filtered_contact_names $i]
	    set name2 [lindex $contact2 3]
	    set loc2 [lindex $contact2 6]
	    set loc2 "[lindex $loc2 0]_[lindex $loc2 1]"
	    set found 0
	    set name1 $name2
	    set loc1 $loc2
	    foreach contact1 $filtered_contact_coords {
		set name1 [lindex $contact1 3]
		set loc1 [lindex $contact1 6]
		set loc1 "[lindex $loc1 0]_[lindex $loc1 1]"
		if {[string eq $name1 $name2]&&[string eq $loc1 $loc2]} {
		    set found 1
		    break
		}
	    }
	    if {$found==0} {
		lappend filtered_contact_coords $contact2
	    } 
	}
    }
    set filtered_contact_coords [lsort -index 3 $filtered_contact_coords]
    set filtered_contact_names $filtered_contact_coords    

    foreach var "filtered_contact_names filtered_contact_coords" {
	set rfxobj($var) [set $var]
    }   

    if {$rfxobj(verbose)>=3} {
	printMessage "List of contacts exported by Process Explorer:"
	putsList "  " $rfxobj(original_contact_names)
	printMessage "Process contacts:"
	printMessage "  1. contacts located outside the simulation domain are discarded" 
	printMessage "  2. duplicated contacts that share same name and x/y location in resistance/resistance_capacitance extraction are filtered to keep only the last one"
	printMessage "List of contacts after processing outsider and duplicates:"
	putsList "  " $rfxobj(filtered_contact_names)
    }

    set varList [list]
    foreach var $rfxobj(filtered_contact_names) {
	lappend varList [list [lindex $var 3] [lindex $var 6]]
    }
    set varList [lsort -index 0 $varList]
    if {$rfxobj(verbose)>=0} {
	printMessage "Filtered contact labels from Process Explorer flow:"   
	putsList "  " $varList 
    }    

    # Number of contacts fewer than 2 for resistance (resistance_capacitance)?
    if {$rfxobj(extractType)=="resistance"||$rfxobj(extractType)=="resistance_capacitance"} {
	printMessage "Check the number of unique contacts for resistance (or resistance_capacitance) extraction:"
	set filtered_contact_names $rfxobj(filtered_contact_names)
	set filtered_contact_names [lsort -index 3 -unique $filtered_contact_names]
	if {$rfxobj(verbose)>=3} {
	    putsList "  " $filtered_contact_names
	}
	if {[llength $filtered_contact_names]<2} {
	    printErrorMessage "Cannot do resistance (or resistance_capacitance) extraction with fewer than 2 contacts!!!\n"
	    return [dict create]	
	} else {
	    printMessage "     Ok the number of unique contacts is [llength $filtered_contact_names]\n"
	}
    }

    return [array get rfxobj]
}

proc exportContact2File {args} {
    upvar rfxobj rfxobj
    set fi [lindex $args 0]
    
    puts $fi "# contact clear"  
    puts $fi "set contact_size 0.001"
    puts $fi "set contact_offset 0.001"
    if {[file exists $rfxobj(configFile)]} {
       puts $fi "source $rfxobj(configFile)"
    }
    if {[file exists R_ContactSize.tcl]} {
       puts $fi "source R_ContactSize.tcl"
    }
    puts $fi ""
    foreach contact $rfxobj(filtered_contact_names) {
	set pin_name [lindex $contact 3] 
	set pin_region_name [lindex $contact 2] 
	set pin_coord [lindex $contact 6]
	set pnx [catch {set pin_x [format {%0.4f} [lindex $contact 6 0]]} fmx]
	set pny [catch {set pin_y [format {%0.4f} [lindex $contact 6 1]]} fmy]
	set pnz [catch {set pin_z [format {%0.4f} [lindex $contact 6 2]]} fmz]
	puts $fi "contact add !replace name= $pin_name region= $pin_region_name box zlo= $pin_x-\$contact_size\/2 ylo= $pin_y-\$contact_size\/2 xhi= -1*($pin_z-\$contact_offset) zhi= $pin_x+\$contact_size\/2 yhi= $pin_y+\$contact_size\/2 xlo= -1*($pin_z+\$contact_offset) "
    }     

    return [array get rfxobj]
}

proc retrieveDatafromPE {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    upvar rfxobj rfxobj

    set in_clip_state [dict get $in in_clip_state]
    set doe_id ""
    if { [dict exists $in $doeIdParam] } {
	set doe_id  [dict get $in $doeIdParam]                            
    }
    set rout_id [dict get $in $routeIdParam]         
    set flow_id [dict get $in $flowIdParam]
    set modu_id [dict get $in $moduleIdParam]
    set step_id [dict get $in $stepIdParam]                                             
    set extractType  [dict get $in "Extraction Type"]
   
    set user_contact1 "" 
    set user_contact2 ""
    if { [dict exists $in "Contact Name 1"] && [dict exists $in "Contact Name 2"] && [string match resistance $extractType]} {
    	set user_contact1 [dict get $in "Contact Name 1"]
    	set user_contact2 [dict get $in "Contact Name 2"]
    }

    set separate_multiple_parts_into_multipe_regions 1
    set transform_region_names_to_be_sprocess_compatible 1
    set filename_and_regionname_changes [clipstate save \
					     "$rout_id" "$flow_id" "$modu_id" "$step_id" "$doe_id" \
					     $separate_multiple_parts_into_multipe_regions \
					     $transform_region_names_to_be_sprocess_compatible]

    set tdrFileName [dict get $filename_and_regionname_changes filename]
    if {$rfxobj(rootFileName)==""} {
	set rootFileName [file rootname $tdrFileName] 
    } else {
	set rootFileName $rfxobj(rootFileName)
    }
    set material_names [clipstate list materials "$rout_id" "$flow_id" "$modu_id" "$step_id" "$doe_id"]
    set material_names [lsort $material_names]
    set region_names_before_splitting [clipstate list regions "$rout_id" "$flow_id" "$modu_id" "$step_id" "$doe_id"]
    set region_names_before_splitting [lsort $region_names_before_splitting]
    set region_name_to_part_regions [dict get $filename_and_regionname_changes region_name_to_part_regions]
    set region_names [list]
    foreach rs $region_name_to_part_regions {
	foreach "reg1 regs" $rs {}
	set region_names [concat $region_names $regs]
    }
    set region_names [lsort -unique $region_names]
    set response [contacts clipstate "$rout_id" "$flow_id" "$modu_id" "$step_id" "$doe_id"]
    foreach "xmin ymin xmax ymax xcol ycol ambit x y" $in_clip_state {}
    set ambit [format "%.4f" $ambit]
    set xmin [format "%g" [format "%.4f" [expr $xmin+$ambit]]]
    set ymin [format "%g" [format "%.4f" [expr $ymin+$ambit]]]
    set xmax [format "%g" [format "%.4f" [expr $xmax-$ambit]]]
    set ymax [format "%g" [format "%.4f" [expr $ymax-$ambit]]]
    set bbox "$xmin $ymin $xmax $ymax"
    foreach var "in in_clip_state doe_id rout_id flow_id modu_id step_id extractType 
                 user_contact1 user_contact2 tdrFileName rootFileName material_names region_names 
                 region_names_before_splitting response bbox ambit" {
	set rfxobj($var) [set $var]
    }   
    # set rfxobj(commandFile) ${rootFileName}_rcfx.cmd
    # set rfxobj(settingFile) ${rootFileName}_rcfx.tcl
    # set rfxobj(solveFile) ${rootFileName}_rcfx.con
    # set rfxobj(logFile) ${rootFileName}_rcfx.log
    # set rfxobj(finalTdrFile) ${rootFileName}_rcfx.tdr
    # set rfxobj(contactFile) ${rootFileName}_cnt.tcl

    # Change auto.segment to 1 for resistance_capacitance extraction
    # if {$rfxobj(extractType)=="resistance_capacitance"} {
    # 	set rfxobj(autoSegmentForResistance) 1
    # }

    # set mode
    set rfxobj(mode) $rfxobj(extractType)
    if {$rfxobj(mode)=="resistance"&&$rfxobj(autoSegmentForResistance)==1} {
	set rfxobj(mode) "resistance auto.segment"
    }
    if {$rfxobj(mode)=="resistance_capacitance"} {
	if {$rfxobj(autoSegmentForResistanceCapacitance)==1} {
	    set rfxobj(mode) "resistance capacitance auto.segment"
	} else {
	    set rfxobj(mode) "resistance capacitance auto.segment"
	    # set rfxobj(mode) "resistance capacitance"
	}
    }

    set varList [list]
    foreach var "doe_id rout_id flow_id modu_id step_id extractType mode
                 user_contact1 user_contact2 tdrFileName rootFileName bbox" {
	lappend varList [list $var $rfxobj($var)]
    }   
    if {$rfxobj(verbose)>=0} {
	printMessage "Process Explorer flow data:"   
	putsList "" $varList

	printMessage "List of materials:"   
	putsList "" $rfxobj(material_names)
    }    

    # Check material names for Raphael
    printMessage "Check material names for $rfxobj(toolName):"
    set rfxobj(materialNameErrorFlag) [checkMaterialNameforRaphael $in $doeIdParam $routeIdParam $flowIdParam $moduleIdParam $stepIdParam]
    if {$rfxobj(materialNameErrorFlag)==1} {
	printErrorMessage "Illegal material names from Process Explorer that cannot be resolved by Rapahel FX. Aborting\n"
	return [dict create]	
    } else {
	printMessage "     Material names are ok\n"
    }

    return [array get rfxobj]
}

proc retrieveMatParamsfromPE {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    upvar rfxobj rfxobj

    ############################################################
    # Read the Process Explorer material library
    
    # Collect all permittivities as a dictionary from material name to value
    # Note: value typically is a tuple (value, unit), but in case the
    # user set up his properties as string, it is just a single value which
    # when converted to number is assumed to also be of unit ohm*m in case
    # of Resistivity.    
    set permittivities [dict create]
    set resistivities [dict create]
    set conductivities [dict create]
    foreach mat $rfxobj(material_names) {
	if { $mat == "Gas" } {
	    continue
	}
        set permittivity_and_resistivity [spx::show Material=$mat Parameters= {"RelativePermittivity" "Resistivity"}]
        if {[dict exists $permittivity_and_resistivity "RelativePermittivity"]} {
            set val [dict get $permittivity_and_resistivity "RelativePermittivity"]
            dict set permittivities $mat [expr double($val)]
        }
        if {[dict exists $permittivity_and_resistivity "Resistivity"]} {
            set val [dict get $permittivity_and_resistivity "Resistivity"]
            dict set resistivities $mat [quantity_from_string $val "ohm*m"]
	    dict set conductivities $mat [expr 0.01/[lindex $val 0]]
        }
    }
    set rfxobj(dbpermittivities) $permittivities
    set rfxobj(dbresistivities) $resistivities
    set rfxobj(dbconductivities) $conductivities

    ############################################################
    # Read the "Material Dependent" parameter local to the step (for DoE or other
    # reason to override the shared properties of material library locally).
    set permittivities [dict create]
    set resistivities [dict create]
    set conductivities [dict create]
    if { [dict exists $rfxobj(in) "Material Dependent"] } {
        set matdep [dict get $rfxobj(in) "Material Dependent"]
        foreach row $matdep {
            set matfilt [lindex $row 0]
            set mats [spx::match Filter= $matfilt]
            set perm [lindex $row 1]
            set resi [lindex $row 2]
            foreach mat $mats {
                dict set permittivities $mat $perm
                dict set resistivities $mat $resi
		dict set conductivities $mat [expr 0.01/[lindex $resi 0]]
            }
        }
    }
    set rfxobj(funcpermittivities) $permittivities
    set rfxobj(funcresistivities) $resistivities
    set rfxobj(funcconductivities) $conductivities

    # Material properties from PE
    foreach key "Permittivities Resistivities" var "dbpermittivities dbresistivities" {
	set vals [list]
	foreach "m p" $rfxobj($var) {
	    lappend vals "$m $p"
	}
	if {$rfxobj(verbose)>=3} {
	    printMessage "Material properties from Process Explorer database ($key):"
	    putsList "  " $vals
	}
    }

    # Material properties from file
    if {[file exists $rfxobj(materialParamsFile)]} {
 	if {$rfxobj(verbose)>=3} {
	    printMessage "Material properties from file $rfxobj(materialParamsFile):"
	    puts [exec cat -n $rfxobj(materialParamsFile)]
	    puts ""
	}
    } else {
    	printMessage "Material properties file $rfxobj(materialParamsFile) not found"
     }

    # Material properties from meas_RC function
    foreach key "Permittivities Resistivities" var "funcpermittivities funcresistivities" {
	set vals [list]
	foreach "m p" $rfxobj($var) {
	    lappend vals "$m $p"
	}
	if {$rfxobj(verbose)>=3} {
	    printMessage "Material properties from meas_RC function ($key):"
	    putsList "  " $vals
	}
    }
    return [array get rfxobj]
}

proc printCheckMaterialPropertyCommand {fsi} {
    exportLine $fsi "array set as \[alias -list\]"
    exportLine $fsi "set mats {}"
    exportLine $fsi "foreach \"reg mat\" \$regMatlist {"
    exportLine $fsi "    lappend mats \$mat"
    exportLine $fsi "}"
    exportLine $fsi "set mats \[lsort -unique \$mats\]"
    exportLine $fsi "foreach mat \$mats {"
    exportLine $fsi "    if {\$mat==\"Gas\"} {"
    exportLine $fsi "         continue"
    exportLine $fsi "    }"
    exportLine $fsi "    set ms \$mat"
    exportLine $fsi "    if {\[info exists as(\$mat)\]} {"
    exportLine $fsi "        set ms \[concat \$ms \$as(\$mat)\]"
    exportLine $fsi "    }"
    exportLine $fsi "    set ms \[lsort -unique \$ms\]"
    exportLine $fsi "    foreach m \$ms {"
    exportLine $fsi "        if {\[pdbGet \$m Conductor\]==1} {"
    exportLine $fsi "            set c \[pdbGet \$m Potential Conductivity\]"
    exportLine $fsi "            LogFile \"\$m (\$mat) conductivity = \$c\""
    exportLine $fsi "            if {\$c==0} {"
    exportLine $fsi "                LogFile \"Error: Conductivity of \$m (\$mat) is zero!!!\""
    exportLine $fsi "                exit 1"
    exportLine $fsi "            }"
    exportLine $fsi "        } else {"
    exportLine $fsi "            set c \[pdbGet \$m Potential Permittivity\]"
    exportLine $fsi "            LogFile \"\$m (\$mat) permittivity = \$c\""	
    exportLine $fsi "        }"
    exportLine $fsi "    }"
    exportLine $fsi "}"
}

proc newMatNameInRaphael {name} {
    regsub -all {\_} $name UU name
    regsub -all {\.} $name DD name
    regsub -all {\+} $name PP name
    return $name
}

proc checkMaterialNameforRaphael {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    upvar rfxobj rfxobj
    set count 1
    set flag 0
    if {$rfxobj(verbose)>=3} {
	printMessage "List of materials:"
	puts $rfxobj(material_names)
    }
    foreach mat $rfxobj(material_names) {
	set matflag 0
	set newname [newMatNameInRaphael $mat]
	if {"$newname"!="$mat"} {
	    puts "[format "%6s" $count] \"$mat\" contains illegal string(s) and changes into \"$newname\" in $rfxobj(toolName). Do not forget to define properties for \"$newname\" in $rfxobj(toolName)!!!"
	    	set matflag 1
	}
	set illegal "\ "
	if {[string first $illegal $mat]!=-1} {
	    puts "[format "%6s" $count] \"$mat\" contains an illegal string \"$illegal\". The error cannot be corrected by $rfxobj(toolName). You need to change the material name in Process Explorer!!!"
	    set matflag 1
	    set flag 1
	}	
	set illegal "MC"
	if {"$mat"=="$illegal"} {
	    puts "[format "%6s" $count] \"$mat\" contains an illegal string \"$illegal\". The error cannot be corrected by $rfxobj(toolName). You need to change the material name in Process Explorer!!!"
	    set matflag 1
	    set flag 1
	}	
	if {$rfxobj(verbose)>=3} {
	    if {$matflag==0} {
		puts "[format "%6s" $count] $mat is ok"
	    } 
	}
	incr count
    }
    return $flag
}

proc putsList { ind var } {
    set count 1
    if {[llength $var]==0} {
	puts "[format "%6s" $count] None"
    } else {
	foreach e $var {
	    puts "[format "%6s" $count] [format "%30s" [lindex $e 0]] [lrange $e 1 end]"
	    incr count
	}
    }
    puts ""
}

proc putsPrintList {} {
    upvar rfxobj rfxobj
    set varList [list]
    foreach var $rfxobj(printList) {
	lappend varList "$var $rfxobj($var)"
    }
    putsList "" $varList
}

proc putsArray { ind var } {
    upvar $var $var
    set count 1             
    if {[array size $var]==0} {
        puts "[format "%6s" $count] None"
    } else {
	set names [lsort [array names $var]]
        foreach name $names {
            puts "[format "%6s" $count] [format "%30s" $name] [set ${var}($name)]"
            incr count
        }
    }
    puts ""
}

proc printMessage { message } {
    puts "$message"
}

proc printErrorMessage { message } {
    puts "Error!!!"
    puts "    $message"
    puts ""
}

proc exportComment {args} {
    upvar rfxobj rfxobj
    if {[llength $args]==2||[lsearch [lindex $args 2] $rfxobj(extractType)]!=-1} {
	puts [lindex $args 0] "# [lindex $args 1]"
    }
}

proc exportBackwardCompatibleComment {args} {
    upvar rfxobj rfxobj
    if {[llength $args]==2||[lsearch [lindex $args 2] $rfxobj(extractType)]!=-1&&$rfxobj(backwardCompatible)==1} {
	puts [lindex $args 0] "# [lindex $args 1]"
    }
}

proc exportLine {args} {
    upvar rfxobj rfxobj
    if {[llength $args]==2||[lsearch [lindex $args 2] $rfxobj(extractType)]!=-1} {
	puts [lindex $args 0] "[lindex $args 1]"
    }
}

proc exportSourceFile {args} {
    upvar rfxobj rfxobj
    set fsi [lindex $args 0]
    set filename [lindex $args 1]
    if {[llength $args]==2||[lsearch [lindex $args 2] $rfxobj(extractType)]!=-1} {
	if {[file exists $filename]} {
	    puts $fsi "source $filename"	    
	} else {
	    exportComment $fsi "File $filename not found!!!" 	    
	}
    }
}

proc exportBackwardCompatibleSourceFile {args} {
    upvar rfxobj rfxobj
    set fsi [lindex $args 0]
    set filename [lindex $args 1]
    if {([llength $args]==2||[lsearch [lindex $args 2] $rfxobj(extractType)]!=-1)&&[file exists $filename]&&$rfxobj(backwardCompatible)==1} {
	exportComment $fsi "$filename"
	exportLine $fsi "source $filename"	    
	exportLine $fsi ""  
    }
}

proc exportNonExistentVariable {args} {
    upvar rfxobj rfxobj
    set fsi [lindex $args 0]
    if {[llength $args]==2||[lsearch [lindex $args 2] $rfxobj(extractType)]!=-1} {
	foreach "var val" [lindex $args 1] {
	    if {$val==""} {
		set val "{}"
	    }
	    puts $fsi "if {!\[info exists $var\]} {"
	    puts $fsi "    set $var $val"
	    puts $fsi "}"
	}
    }
}

proc exportContact2FileforResistance {args} {
    upvar rfxobj rfxobj
    set fi [lindex $args 0]
    
    exportComment $fi "Contacts exported by Process Explorer $rfxobj(PEVersion)"
    exportComment $fi "meas_RC.tcl Version $rfxobj(measRCVersion)"  
    exportComment $fi "[exec date]"  
    exportLine $fi ""

    puts $fi "set contact_size 0.01"
    puts $fi "set contact_offset 0.001"
    exportSourceFile $fi R_ContactSize.tcl
    puts $fi ""

    puts $fi "# contact clear"  
    array set contactSecs {}
    foreach "c s" $rfxobj(contactSpecs) {
    	set contactSecs($c) $s
    }
    foreach contact $rfxobj(filtered_contact_names) {
    	set pin_name [lindex $contact 3] 
    	set pin_region_name [lindex $contact 2] 
    	set pin_coord [lindex $contact 6]
    	set pnx [catch {set pin_x [format {%0.4f} [lindex $contact 6 0]]} fmx]
    	set pny [catch {set pin_y [format {%0.4f} [lindex $contact 6 1]]} fmy]
    	set pnz [catch {set pin_z [format {%0.4f} [lindex $contact 6 2]]} fmz]
    	set contact_type box
    	set contact_size "\$contact_size"
    	set contact_size_y "\$contact_size"
    	set contact_size_z "\$contact_size"
    	set contact_offset "\$contact_offset"
   	set contact_size_y_n "\$contact_size\/2"
    	set contact_size_y_p "\$contact_size\/2"
    	set contact_size_z_n "\$contact_size\/2"
    	set contact_size_z_p "\$contact_size\/2"
    	set contact_offset_n "\$contact_offset"
    	set contact_offset_p "\$contact_offset"
    	set contact_attach {}
    	# Add user specifications for contact 20200910
    	if {[info exists contactSecs($pin_name)]} {
    	    set s $contactSecs($pin_name)
     	    foreach "type sizexn sizexp sizeyn sizeyp sizezn sizezp attach" [lrange $contactSecs($pin_name) 0 7] {}
	    puts "  $type $sizexn $sizexp $sizeyn $sizeyp $sizezn $sizezp $attach"
    	    if {"$type"!=""} {
    		set contact_type $type
    	    }
 	    foreach var "contact_offset_n contact_offset_p contact_size_y_n contact_size_y_p contact_size_z_n contact_size_z_p" par "sizexn sizexp sizeyn sizeyp sizezn sizezp" {
		set val [set $par]
		if {"$val"!=""&&[string is double $val]} {
		    set $var "$val"
		}		
	    }
    	    set contact_attach $attach
    	}
	if {"$contact_type"=="point"} {
	    puts $fi "contact add $contact_type replace name= $pin_name region= $pin_region_name z= $pin_x y= $pin_y x= -1*($pin_z-$contact_offset) $contact_attach"
	} else {
	    puts $fi "contact add $contact_type !replace !cut.mesh name= $pin_name region= $pin_region_name xlo= -1*($pin_z+$contact_offset_n) xhi= -1*($pin_z-$contact_offset_p) ylo= $pin_y-$contact_size_y_n yhi= $pin_y+$contact_size_y_p zlo= $pin_x-$contact_size_z_n zhi= $pin_x+$contact_size_z_p $contact_attach"
	}
     }     
}

proc exportContact2FileforCapacitance {args} {
    upvar rfxobj rfxobj
    set fi [lindex $args 0]
    set filtered_contact_names $rfxobj(filtered_contact_names)
    set filtered_contact_names_uniq [lsort -index 3 -unique $filtered_contact_names]
    set rfxobj(filtered_contact_names_uniq) $filtered_contact_names_uniq

    exportComment $fi "Contacts exported by Process Explorer"
    exportComment $fi "Process Explorer Version: $rfxobj(PEVersion)"
    exportComment $fi "meas_RC Version: $rfxobj(measRCVersion)"  
    exportComment $fi "[exec date]"  
    exportLine $fi ""

    puts $fi "# contact clear"  
    puts $fi "set contact_size 0.01"
    puts $fi "set contact_offset 0.001"
    exportSourceFile $fi R_ContactSize.tcl
    puts $fi ""

    foreach contact $filtered_contact_names_uniq {
	set pin_name [lindex $contact 3] 
	set pin_region_name [lindex $contact 2] 
	set pin_coord [lindex $contact 6]
	set pnx [catch {set pin_x [format {%0.4f} [lindex $contact 6 0]]} fmx]
	set pny [catch {set pin_y [format {%0.4f} [lindex $contact 6 1]]} fmy]
	set pnz [catch {set pin_z [format {%0.4f} [lindex $contact 6 2]]} fmz]
	exportLine $fi "set mat \[region name= $pin_region_name material syntax.check.value= Copper\]"
	exportLine $fi "contact add name= $pin_name \$mat xlo= -($pin_z+\$contact_offset) xhi= -($pin_z-\$contact_offset) ylo= $pin_y-\$contact_size\/2 yhi= $pin_y+\$contact_size\/2 zlo= $pin_x-\$contact_size\/2 zhi= $pin_x+\$contact_size\/2\n"
    } 
    exportLine $fi "" 

    if {[llength $filtered_contact_names_uniq]<[llength $filtered_contact_names]} {
	foreach contact $filtered_contact_names_uniq {
	    set pin_name   [lindex $contact 3]
	    set pin_region [lindex $contact 2]
	    set pin_match_list [lsearch -index 3 -exact -all -inline $filtered_contact_names $pin_name]
	    set contact_merge_list [list $pin_name]
	    
	    if {[llength $pin_match_list]>1} {
		foreach pml $pin_match_list {
		    set pmreg  [lindex $pml 2]
		    set pmname [lindex $pml 3]
		    set pmxy   [lindex $pml 6]
		    lappend contact_merge_list $pmreg 
		} 
		set contact_merge_list [lsort -unique $contact_merge_list]
		set idx [lsearch $contact_merge_list $pin_name]
		set contact_merge_list [lreplace $contact_merge_list $idx $idx]
		set contact_merge_list [linsert $contact_merge_list 0 $pin_name]
		for {set i 1} {$i<[llength $contact_merge_list]} {incr i} {
		    set con [lindex $contact_merge_list $i]
		    set contact_merge_list [lreplace $contact_merge_list $i $i $con]
		}
		set contact_merge_list [join $contact_merge_list " "]
		# exportLine $fi "contact merge= {$contact_merge_list}"
	    }
	}
    }	
}

proc exportRefineboxforContact {args} {
    upvar rfxobj rfxobj
    set fi [lindex $args 0]
    set filtered_contact_names $rfxobj(filtered_contact_names)

    set count 1
    foreach contact $filtered_contact_names {
	set pin_region_name [lindex $contact 2] 
	set pin_name [lindex $contact 3] 
	set pin_coord [lindex $contact 6]
	foreach "pin_x pin_y pin_z" [lindex $contact 6] {}
	if {$rfxobj(refineContactType)=="box"} {
	    # exportLine $fi "refinebox add resistance.only name= ${pin_name}_${count} min= \"-($pin_z+\$contact_refine_offset) $pin_y-\$contact_refine_size\/2 $pin_x-\$contact_refine_size\/2 \" max= \"-($pin_z-\$contact_refine_offset) $pin_y+\$contact_refine_size\/2 $pin_x+\$contact_refine_size\/2\" xrefine= \$contact_refine yrefine= \$contact_refine zrefine= \$contact_refine"
	    exportLine $fi "refinebox add resistance.only name= ${pin_name}_${count} min= \"-($pin_z+\$contact_refine_offset) $pin_y-\$contact_refine_size\/2 $pin_x-\$contact_refine_size\/2 \" max= \"-($pin_z-\$contact_refine_offset) $pin_y+\$contact_refine_size\/2 $pin_x+\$contact_refine_size\/2\" xrefine= \$contact_refine yrefine= \$contact_refine zrefine= \$contact_refine"
	} else {
	    exportLine $fi "mask name= ${pin_name}_${count} left= $pin_y-\$contact_size\/2 right= $pin_y+\$contact_size\/2 front= $pin_x-\$contact_size\/2 back= $pin_x+\$contact_size\/2"
	    exportLine $fi "refinebox add resistance.only name= ${pin_name}_${count} mask= ${pin_name}_${count} mask.edge.mns= \$contact_refine mask.edge.ngr= 1.3 mask.edge.refine.extent= \$contact_refine_size\/2 extrusion.min= -($pin_z+\$contact_refine_offset) extrusion.max= -($pin_z-\$contact_refine_offset) "
	}
	incr count
    }
}

proc exportContactforResistance {args} {
    upvar rfxobj rfxobj
    set fi [lindex $args 0]
    set filtered_contact_names $rfxobj(filtered_contact_names)

    exportLine $fi "# contact clear"
    array set contactSecs {}
    foreach "c s" $rfxobj(contactSpecs) {
    	set contactSecs($c) $s
    }
    foreach contact $rfxobj(filtered_contact_names) {
    	set pin_name [lindex $contact 3] 
    	set pin_region_name [lindex $contact 2] 
    	set pin_coord [lindex $contact 6]
    	set pnx [catch {set pin_x [format {%0.4f} [lindex $contact 6 0]]} fmx]
    	set pny [catch {set pin_y [format {%0.4f} [lindex $contact 6 1]]} fmy]
    	set pnz [catch {set pin_z [format {%0.4f} [lindex $contact 6 2]]} fmz]
    	set contact_type box
    	set contact_size "\$contact_size"
    	set contact_size_y "\$contact_size"
    	set contact_size_z "\$contact_size"
    	set contact_offset "\$contact_offset"
    	set contact_attach {}
    	# Add user specifications for contact 20200910
    	if {[info exists contactSecs($pin_name)]} {
    	    set s $contactSecs($pin_name)
    	    foreach "type sizey sizez offset attach" [lrange $contactSecs($pin_name) 0 4] {}
    	    if {"$type"!=""} {
    		set contact_type $type
    	    }
    	    if {"$sizey"!=""&&[string is double $sizey]} {
    		set contact_size_y "$sizey"
    	    }
    	    if {"$sizez"!=""&&[string is double $sizez]} {
    		set contact_size_z "$sizez"
    	    }
    	    if {"$offset"!=""&&[string is double $offset]} {
    		set contact_offset "$offset"
    	    }
    	    set contact_attach $attach
    	}
	if {"$contact_type"=="point"} {
	    puts $fi "contact add $contact_type replace name= $pin_name region= $pin_region_name z= $pin_x y= $pin_y x= -1*($pin_z-$contact_offset) $contact_attach"
	} else {
	    puts $fi "contact add $contact_type !replace !cut.mesh name= $pin_name region= \$regionnames($pin_region_name) zlo= $pin_x-$contact_size_z\/2 ylo= $pin_y-$contact_size_y\/2 xhi= -1*($pin_z-$contact_offset) zhi= $pin_x+$contact_size_z\/2 yhi= $pin_y+$contact_size_y\/2 xlo= -1*($pin_z+$contact_offset) $contact_attach"
	}
    }     
    exportLine $fi ""

    exportComment $fi "Track the name changes" "resistance_capacitance resistance"
    exportLine $fi "array set annotationnames {}" "resistance_capacitance resistance"
    exportLine $fi "regionMapping annotationnames" "resistance_capacitance resistance"
    exportLine $fi "" "resistance_capacitance resistance"
}

proc exportContactforResistance {args} {
    upvar rfxobj rfxobj
    set fi [lindex $args 0]
    set filtered_contact_names $rfxobj(filtered_contact_names)

    exportLine $fi "# contact clear"
    array set contactSecs {}
    foreach "c s" $rfxobj(contactSpecs) {
    	set contactSecs($c) $s
    }
    foreach contact $rfxobj(filtered_contact_names) {
    	set pin_name [lindex $contact 3] 
    	set pin_region_name [lindex $contact 2] 
    	set pin_coord [lindex $contact 6]
    	set pnx [catch {set pin_x [format {%0.4f} [lindex $contact 6 0]]} fmx]
    	set pny [catch {set pin_y [format {%0.4f} [lindex $contact 6 1]]} fmy]
    	set pnz [catch {set pin_z [format {%0.4f} [lindex $contact 6 2]]} fmz]
    	set contact_type box
    	set contact_size "\$contact_size"
    	set contact_size_y "\$contact_size"
    	set contact_size_z "\$contact_size"
    	set contact_offset "\$contact_offset"
    	set contact_size_y_n "\$contact_size\/2"
    	set contact_size_y_p "\$contact_size\/2"
    	set contact_size_z_n "\$contact_size\/2"
    	set contact_size_z_p "\$contact_size\/2"
    	set contact_offset_n "\$contact_offset"
    	set contact_offset_p "\$contact_offset"
    	set contact_attach {}
    	# Add user specifications for contact 20200910
	puts "$pin_name $pin_region_name {$pin_coord}"
    	if {[info exists contactSecs($pin_name)]} {
    	    set s $contactSecs($pin_name)
    	    foreach "type sizexn sizexp sizeyn sizeyp sizezn sizezp attach" [lrange $contactSecs($pin_name) 0 7] {}
	    puts "  $type $sizexn $sizexp $sizeyn $sizeyp $sizezn $sizezp $attach"
    	    if {"$type"!=""} {
    		set contact_type $type
    	    }
	    foreach var "contact_offset_n contact_offset_p contact_size_y_n contact_size_y_p contact_size_z_n contact_size_z_p" par "sizexn sizexp sizeyn sizeyp sizezn sizezp" {
		set val [set $par]
		if {"$val"!=""&&[string is double $val]} {
		    set $var "$val"
		}		
	    }
     	    set contact_attach $attach
    	}
	if {"$contact_type"=="point"} {
	    puts $fi "contact add $contact_type replace name= $pin_name region= $pin_region_name z= $pin_x y= $pin_y x= -1*($pin_z-$contact_offset) $contact_attach"
	} else {
	    puts $fi "contact add $contact_type !replace !cut.mesh name= $pin_name region= \$regionnames($pin_region_name) xlo= -1*($pin_z+$contact_offset_n) xhi= -1*($pin_z-$contact_offset_p) ylo= $pin_y-$contact_size_y_n yhi= $pin_y+$contact_size_y_p zlo= $pin_x-$contact_size_z_n zhi= $pin_x+$contact_size_z_p $contact_attach"
	}
    }     
    exportLine $fi ""

    exportComment $fi "Track the name changes" "resistance_capacitance resistance"
    exportLine $fi "array set annotationnames {}" "resistance_capacitance resistance"
    exportLine $fi "regionMapping annotationnames" "resistance_capacitance resistance"
    exportLine $fi "" "resistance_capacitance resistance"
}

proc exportContactCoordsforResistance {args} {
    upvar rfxobj rfxobj
    set fi [lindex $args 0]
    set filtered_contact_names $rfxobj(filtered_contact_names)

    exportLine $fi "# contact coords"
    exportLine $fi "set contactcoords {"
    foreach contact $filtered_contact_names {
	set pin_region_name [lindex $contact 2] 
	set pin_name [lindex $contact 3] 
	set pin_coord [lindex $contact 6]
	foreach "pin_x pin_y pin_z" [lindex $contact 6] {}
	exportLine $fi "\t$pin_name {-$pin_z $pin_y $pin_x}"
    }
    exportLine $fi "}"
    exportLine $fi ""
}

proc exportContactforCapacitance {args} {
    upvar rfxobj rfxobj
    set fi [lindex $args 0]
    set filtered_contact_names $rfxobj(filtered_contact_names)
    set filtered_contact_names_uniq [lsort -index 3 -unique $filtered_contact_names]
    set rfxobj(filtered_contact_names_uniq) $filtered_contact_names_uniq

    foreach contact $filtered_contact_names_uniq {
	set pin_name [lindex $contact 3] 
	set pin_region_name [lindex $contact 2] 
	exportLine $fi "region name= \$regionnames($pin_region_name) new.name= $pin_name"
    } 
    exportLine $fi "" 
    set contact_merge_lists [list]
    if {[llength $filtered_contact_names_uniq]<[llength $filtered_contact_names]} {
	exportComment $fi "Regions sharing a same text label are merged into one" 
	foreach contact $filtered_contact_names_uniq {
	    set pin_name   [lindex $contact 3]
	    set pin_region [lindex $contact 2]
	    set pin_match_list [lsearch -index 3 -exact -all -inline $filtered_contact_names $pin_name]
	    set contact_merge_list [list $pin_name]
	    
	    if {[llength $pin_match_list]>1} {
		foreach pml $pin_match_list {
		    set pmreg  [lindex $pml 2]
		    set pmname [lindex $pml 3]
		    set pmxy   [lindex $pml 6]
		    lappend contact_merge_list $pmreg 
		} 
		set contact_merge_list [lsort -unique $contact_merge_list]
		set idx [lsearch $contact_merge_list $pin_name]
		set contact_merge_list [lreplace $contact_merge_list $idx $idx]
		set contact_merge_list [linsert $contact_merge_list 0 $pin_name]
		for {set i 1} {$i<[llength $contact_merge_list]} {incr i} {
		    set con [lindex $contact_merge_list $i]
		    set con "\$regionnames($con)"
		    set contact_merge_list [lreplace $contact_merge_list $i $i $con]
		}
		set contact_merge_list [join $contact_merge_list " "]
		exportLine $fi "contact merge= {$contact_merge_list}"
		lappend contact_merge_lists $contact_merge_list
	    }
	}
	exportLine $fi ""
    }
    set rfxobj(contact_merge_lists) $contact_merge_lists

    exportComment $fi "Track the name changes"
    exportLine $fi "array set annotationnames {}" 
    foreach contact $rfxobj(filtered_contact_names) {
	set pin_name [lindex $contact 3] 
	set pin_region_name [lindex $contact 2] 
	exportLine $fi "set annotationnames(\$regionnames($pin_region_name)) $pin_name"
    } 
    # foreach contact_merge_list $rfxobj(contact_merge_lists) {
    # 	set pin_name [lindex $contact_merge_list 0]
    # 	set contact_merge_list [lrange $contact_merge_list 1 end]
    # 	foreach pin_region_name $contact_merge_list {
    # 	    exportLine $fi "set annotationnames($pin_region_name) $pin_name"
    # 	}
    # } 
    exportLine $fi "regionMapping annotationnames"
    exportLine $fi ""         	
}

proc exportNetlist {args} {
    upvar rfxobj rfxobj
    set fi [lindex $args 0]
    set rootFileName $rfxobj(rootFileName)
    exportComment $fi "Export the solution to files"
    if {$rfxobj(extractType)=="capacitance"} {
	exportLine $fi "printCapacitanceMatrix spice.matrix \${outputFileName}.cMatrix.csv" "capacitance"          
	exportLine $fi "printCapacitanceMatrix spice.matrix \${outputFileName}.cMatrix.spi" "capacitance"         
	exportLine $fi "printCapacitanceMatrix spice.total  \${outputFileName}.cTotal.spi"  "capacitance"
	exportLine $fi "printRC \${outputFileName}.rcMatrix.spi exclude.C= \${cap_exclude}" "capacitance"          
    } elseif {$rfxobj(extractType)=="resistance"} {   
	exportLine $fi "printResistanceMatrix spice.matrix \${outputFileName}.rMatrix.csv" "resistance"         
	exportLine $fi "printResistanceMatrix spice.matrix \${outputFileName}.rMatrix.spi" "resistance"         
	exportLine $fi "printResistanceMatrix spice.total  \${outputFileName}.rTotal.spi"  "resistance" 
	exportLine $fi "printRC \${outputFileName}.rcMatrix.spi" "resistance"          
    } else {        
	if {$rfxobj(printRCModelList)=="na"} {
	    exportLine $fi "printCapacitanceMatrix spice.matrix \${outputFileName}.cMatrix.spi" "resistance_capacitance"         
	    exportLine $fi "printCapacitanceMatrix spice.total  \${outputFileName}.cTotal.spi"  "resistance_capacitance"         
	    exportLine $fi "printResistanceMatrix spice.matrix \${outputFileName}.rMatrix.spi" "resistance_capacitance"         
	    exportLine $fi "printResistanceMatrix spice.total  \${outputFileName}.rTotal.spi"  "resistance_capacitance"         
	    exportLine $fi "printRC \${outputFileName}.rcMatrix.spi  model1 exclude.C= \${cap_exclude}" resistance_capacitance          
	    exportLine $fi "printRC \${outputFileName}.rc1Matrix.spi model1 exclude.C= \${cap_exclude}" resistance_capacitance          
	    exportLine $fi "printRC \${outputFileName}.rc2Matrix.spi model2 exclude.C= \${cap_exclude}" resistance_capacitance           
	    exportLine $fi "printRC \${outputFileName}.rc3Matrix.spi model3 exclude.C= \${cap_exclude}" resistance_capacitance           
	    exportLine $fi "printRC \${outputFileName}.rc4Matrix.spi model4 exclude.C= \${cap_exclude}" resistance_capacitance          
	} else {
	    exportComment $fi "User-specified model(s): {$rfxobj(printRCModelList)}" "resistance_capacitance"
	    array set ms {
		cMatrix {printCapacitanceMatrix spice.matrix}
		cTotal {printCapacitanceMatrix spice.total}
		rMatrix {printResistanceMatrix spice.matrix}
		rTotal {printResistanceMatrix spice.total}
	    }
	    foreach m $rfxobj(printRCModelList) {
		if {[lsearch {model1 model2 model3 model4} $m]!=-1} {
		    exportLine $fi "printRC \${outputFileName}.${m}.rcMatrix.spi $m exclude.C= \${cap_exclude}" resistance_capacitance           
		} elseif {[lsearch {cMatrix cTotal rMatrix rTotal} $m]!=-1} {
		    foreach "c k" $ms($m) {}
		    exportLine $fi "$c $k \${outputFileName}.${m}.spi" "resistance_capacitance"         
		    
		} else {
		    exportComment $fi "Model \"$m\" specified in printRCModelList is not a valid model !!!"	"resistance_capacitance"	
		}
	    }
	}
    }
    exportLine $fi ""  
}

proc printDateTime { verbose message } {
    upvar rfxobj rfxobj
    if {$rfxobj(verbose)>=$verbose} {
	puts "$message: [exec date]"
    }
}

### meas_RC rcx function body ###

# process step: meas_RC, rev: >= 4
# external input:
# internal input: flowIdParam, moduleIdParam, stepIdParam, in_clip_state, filtered_contact_names
# internal output: out_capacitance or out_resistance
proc meas__RCExec_rcx {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    global tcl_platform
    # Windows is not supported right now, return early.
    if { [string equal $tcl_platform(os) "Windows NT"] } {
        echo "NOTE: meas_RC with Approach=[dict get $in Approach] is not supported on $tcl_platform(os)."
        set out [dict create]
        return $out
    }

    # get some input parameter values
    set in_clip_state [dict get $in in_clip_state]
    set doe_id ""
    if { [dict exists $in $doeIdParam] } {
        set doe_id  [dict get $in $doeIdParam]
    }
    set rout_id [dict get $in $routeIdParam]
    set flow_id [dict get $in $flowIdParam]
    set modu_id [dict get $in $moduleIdParam]
    set step_id [dict get $in $stepIdParam]
    set extract_type  [dict get $in "Extraction Type"]
    set user_contact1 "" 
    set user_contact2 ""
    if { [dict exists $in "Contact Name 1"] && [dict exists $in "Contact Name 2"] } {
       set user_contact1 [dict get $in "Contact Name 1"]
       set user_contact2 [dict get $in "Contact Name 2"]
    } 
    
    set separate_multiple_parts_into_multipe_regions 1
    set transform_region_names_to_be_sprocess_compatible 1
    set filename_and_regionname_changes [clipstate save \
        "$rout_id" "$flow_id" "$modu_id" "$step_id" "$doe_id" \
        $separate_multiple_parts_into_multipe_regions \
        $transform_region_names_to_be_sprocess_compatible]
    set filename [dict get $filename_and_regionname_changes filename]
    set region_name_to_part_regions [dict get $filename_and_regionname_changes region_name_to_part_regions]
    echo "WROTE TDR TO $filename"
    echo "REGION NAMES CHANGES (MULTIPLE PARTS): $region_name_to_part_regions"
    set region_names [clipstate list regions "$rout_id" "$flow_id" "$modu_id" "$step_id" "$doe_id"]
    echo "ALL KNOWN REGION NAMES: $region_names"
    set material_names [clipstate list materials "$rout_id" "$flow_id" "$modu_id" "$step_id" "$doe_id"]
    echo "ALL KNOWN MATERIAL NAMES: $material_names"
    
    set response [contacts clipstate "$rout_id" "$flow_id" "$modu_id" "$step_id" "$doe_id"]
    set filtered_contact_names [dict get $response filtered_contact_names]
    set filtered_contact_coords [lsort -index 6 -unique $filtered_contact_names]
    foreach crds $filtered_contact_coords {
       set pnm [lindex $crds 3]
       set pxy [lindex $crds 6]
       echo "pin $pnm is located at $pxy" 
    }
    set filtered_contact_names [lsort -index 3 -unique $filtered_contact_names]
    echo "FILTERED_CONTACT_NAMES: $filtered_contact_names"

    # select contact candidates by filtering over user input (currently only text label (idx = 3))
    set contact1 []
    set contact2 []
    foreach contact $filtered_contact_names {

        # pin info for full cap matrix
        set pin_name [lindex $contact 3] 
        set pin_coord [lindex $contact 6]
        set pnx [catch {set pin_x [format {%0.4f} [lindex $contact 6 0]]} fmx]
        set pny [catch {set pin_y [format {%0.4f} [lindex $contact 6 1]]} fmy]
        set pnz [catch {set pin_z [format {%0.4f} [lindex $contact 6 2]]} fmz]
        if { $pnx || $pny || $pnz } { echo "Warning: $pin_name coordinates missing" }
        set pin_region_name [lindex $contact 2] 

        # contact pair info for resistance
	set clipstate_name [lindex $contact 3]
	set user_name1 [lindex $user_contact1 3]
	set user_name2 [lindex $user_contact2 3]
        if { "$user_name1" == "$clipstate_name" } {
            set contact1 $contact
        }
        if { "$user_name2" == "$clipstate_name" } {
	     set contact2 $contact
        }

    }
    
    set coords1 [lindex $contact1 6]
    set coords2 [lindex $contact2 6]
    echo "COORDS1: $coords1 --- COORDS2: $coords2"

    set region1 [lindex $contact1 2]
    set region2 [lindex $contact2 2]
    echo "REGION1: $region1 --- REGION2: $region2"

    set Contact1                         [lindex $contact1 3]
    set RegionName1                      [lindex $contact1 2]
    set cnt1x [ catch {set Contact1_Coord_x [format {%0.4f} [lindex $contact1 6 0]]} fm1x ]
    set cnt1y [ catch {set Contact1_Coord_y [format {%0.4f} [lindex $contact1 6 1]]} fm1y ]
    set cnt1z [ catch {set Contact1_Coord_z [format {%0.4f} [lindex $contact1 6 2]]} fm1z ]
    if { $cnt1x || $cnt1y || $cnt1z } { echo "Warning: contact1 coordinates missing" }

    set Contact2                         [lindex $contact2 3]
    set RegionName2                      [lindex $contact2 2]
    set cnt2x [catch {set Contact2_Coord_x [format {%0.4f} [lindex $contact2 6 0]]} fm2x]
    set cnt2y [catch {set Contact2_Coord_y [format {%0.4f} [lindex $contact2 6 1]]} fm2y]
    set cnt2z [catch {set Contact2_Coord_z [format {%0.4f} [lindex $contact2 6 2]]} fm2z]
    if { $cnt2x || $cnt2y || $cnt2z } { echo "Warning: contact1 coordinates missing" }

    # initiate run rcx
    set j 1

    # tdr only
    if {[file exists keyTdrOnly]} {
       set j 0
       puts ""
       puts "INFO: File keyTdrOnly in working directory causes tool to generate tdr and cmd only. " 
       puts "... Done!"
       puts ""
    }

    # Material Name Checks

    set matNameError 0
    foreach mater $material_names {
	if { [string match *\.* $mater] } {
	    puts ""
	    puts "Error: Material name $mater contains dot \".\".  It's illegal for Raphael" 
	    echo "Error: Material name $mater contains dot \".\".  It's illegal for Raphael" 
	    set matNameError 1
	} 
	if { [string match *_* $mater] } {
	    puts ""
	    puts "Error: Material name $mater contains underscore \"_\".  It's illegal for Raphael" 
	    echo "Error: Material name $mater contains underscore \"_\".  It's illegal for Raphael" 
	    set matNameError 1
	} 
	if { [string match *\ * $mater] } {
	    puts ""
	    puts "Error: Material name $mater contains whitespace \" \".  It's illegal for Raphael" 
	    echo "Error: Material name $mater contains whitespace \" \".  It's illegal for Raphael" 
	    set matNameError 1
	} 
	if { [string match *\+* $mater] } {
	    puts ""
	    puts "Error: Material name $mater contains plus sign \"+\".  It's illegal for Raphael" 
	    echo "Error: Material name $mater contains plus sign \"+\".  It's illegal for Raphael" 
	    set matNameError 1
	} 
	if { $mater == "MC" } {
	    puts ""
	    puts "Error: Material name MC is illegal for Raphael. Please change it." 
	    echo "Error: Material name MC is illegal for Raphael. Please change it." 
	    set matNameError 1
	} 
    }
    if { $matNameError } {
	puts ""
	puts "Error in material names .... Stop running Raphael"
	set j 0
    }
    
    ############################################################
    # Read the Process Explorer material library
    
    # Collect all permittivities as  a dictionary from material name to value
    # Note: value typically is a tuple (value, unit), but in case the
    # user set up his properties as string, it is just a single value which
    # when converted to number is assumed to also be of unit ohm*m in case
    # of Resistivity.    
    set permittivities [dict create]
    set resistivities [dict create]
    foreach mat $material_names {
	if { $mat == "Gas" } {
	    continue
	}
	set permittivity_and_resistivity [spx::show Material=$mat Parameters= {"RelativePermittivity" "Resistivity"}]
        if {[dict exists $permittivity_and_resistivity "RelativePermittivity"]} {
            set val [dict get $permittivity_and_resistivity "RelativePermittivity"]
            dict set permittivities $mat [expr double($val)]
        }
        if {[dict exists $permittivity_and_resistivity "Resistivity"]} {
            set val [dict get $permittivity_and_resistivity "Resistivity"]
            dict set resistivities $mat [quantity_from_string $val "ohm*m"]
        }
    }
    echo "INFO: permittivities from Process Explorer material library:\n$permittivities"
    echo "INFO: resistivities from Process Explorer material library:\n$resistivities"
    
    ############################################################
    # Read the "Material Dependent" parameter local to the step (for DoE or other
    # reason to override the shared properties of material library locally).
    if { [dict exists $in "Material Dependent"] } {
        set matdep [dict get $in "Material Dependent"]
        foreach row $matdep {
            set matfilt [lindex $row 0]
            set mats [spx::match Filter= $matfilt]
            set perm [lindex $row 1]
            set resi [lindex $row 2]
            foreach mat $mats {
                if { [dict exists $permittivities $mat] } {
                    set oldperm [dict get $permittivities $mat]
                    if { [expr (abs($oldperm - $perm)/abs($perm)) > 1e-9] } {
                        echo "INFO: $mat \"Relative Permittivity\" taken from \"Material Dependent\" parameter (=$perm) instead of from material library (=$oldperm)."
                    }
                }
                dict set permittivities $mat $perm
                if { [dict exists $resistivities $mat] } {
                    set oldresi [dict get $resistivities $mat]
                    if { [expr (abs([lindex $oldresi 0] - [lindex $resi 0])/abs([lindex $resi 0])) > 1e-9] } {
                        echo "INFO: $mat \"Resistivity\" taken from \"Material Dependent\" parameter (=$resi) instead of from material library (=$oldresi)."
                    }
                }
                dict set resistivities $mat $resi
            }
        }
    }
    
    set FileName [ file rootname $filename ]
    
    set SPX_InputName ${FileName}_spx.cmd
    set SN_InputName ${FileName}_msh.cmd
    set RPH_InputName ${FileName}_rph.cmd

    ############################################################
    ## Create tcl for contacts 

    if { [file exists keyGenCnt] } {

       set CNT_InputName ${FileName}_cnt.tcl
       set fdt [ open $CNT_InputName w+ ]

       puts ""	
       puts "INFO: File keyGenCnt enables contact tcl file generation:"	
       puts "      => $CNT_InputName "	

       puts $fdt "   "
       puts $fdt "# square contact size on interface; contact border must be within contact interface(s) to avoid crash."
       puts $fdt "set contact_size   0.001"
       puts $fdt "   "
       puts $fdt "# contact box offset above or below the interface; should be less than the min layer thickness from both sides."
       puts $fdt "set contact_offset 0.001"
       puts $fdt "   "
       if { [file exists R_ContactSize.tcl] } {
          puts $fdt " source R_ContactSize.tcl "
          puts "Info: source file R_ContactSize.tcl in Raphael cmd"
       }

       set cont_list { }
       foreach contact $filtered_contact_names {

        # pin info for full cap matrix
        set pin_name [lindex $contact 3] 
	lappend cont_list $pin_name
        set pin_coord [lindex $contact 6]
        set pnx [catch {set pin_x [format {%0.4f} [lindex $contact 6 0]]} fmx]
        set pny [catch {set pin_y [format {%0.4f} [lindex $contact 6 1]]} fmy]
        set pnz [catch {set pin_z [format {%0.4f} [lindex $contact 6 2]]} fmz]
        if { $pnx || $pny || $pnz } { echo "Warning: $pin_name coordinates missing" }
        set pin_region_name [lindex $contact 2] 

        puts $fdt " "
        puts $fdt " contact name= $pin_name region= $pin_region_name box zlo= $pin_x-\$contact_size\/2 ylo= $pin_y-\$contact_size\/2 xhi= -1*($pin_z-\$contact_offset) zhi= $pin_x+\$contact_size\/2 yhi= $pin_y+\$contact_size\/2 xlo= -1*($pin_z+\$contact_offset) "

       }

       #check the number of contacts for resistance extraction
       set cont_list_u [lsort -unique $cont_list]
       set num_conts [llength $cont_list_u]
       echo "Info: The number of contacts in the clip is $num_conts"
       echo "List of contacts: $cont_list_u"
       echo "Info: The number of contacts in the clip is $num_conts"
       echo "List of contacts: $cont_list_u"
       if { $num_conts < 2 } {
          echo "Alert: The number of contacts in the clip is less than 2!"
          puts " "
          puts "Alert: The number of contacts in the clip is less than 2!"
          puts " "
       }
     close $fdt

     puts "Info: The contact coordinate system is comptible only with that of Raphael K-2015.06 or later."
     puts "... Done writing file!"
     puts ""
   }
   # end gen cnts
   ############################################################
    
    # Check Raphael version
    set MY_LD_LIBRARY_PATH ""
    if { [info exists ::env(LD_LIBRARY_PATH)] } {
        set MY_LD_LIBRARY_PATH $::env(LD_LIBRARY_PATH)
        array unset ::env LD_LIBRARY_PATH
    }
    if { [catch {set raph_version [exec -ignorestderr raphael rcx -version | grep Version]; set raph_version [string trim [string trim $raph_version "*"]]; echo "Raphael version used: $raph_version"} err] } {
        echo "There was an error checking the version of raphael: $err"
        echo "Assuming raphael version M-2016.12."
        set raph_version "Version M-2016.12"
    }
    if { [string length $MY_LD_LIBRARY_PATH] > 0 } {
        set ::env(LD_LIBRARY_PATH) $MY_LD_LIBRARY_PATH
    }

    if { $raph_version == "Version J-2014.09" || \
	 $raph_version == "Version K-2015.06" || \
	 $raph_version == "Version L-2016.03"
    } {
	set new_raph 0 
    } else {
	set new_raph 1 
    }

    if { ! $new_raph } {
       echo "SPX -batch Input file  for boundary extraction"
       
       set fspx [ open $SPX_InputName w+ ]
       puts $fspx " ##SPX -batch Input file  for boundary extraction ##"
       puts $fspx " mgoals use.spx "
       puts $fspx " init tdr= ${FileName}.tdr "
       if {[file exists BNDSettings.tcl]} {
          puts $fspx " source BNDSettings.tcl "  
          puts "Info: source file BNDSettings.tcl in Raphael cmd"
       }
   
       puts $fspx " struct tdr.bnd= ${FileName}_spx_bnd.tdr " 
       puts $fspx " exit "
       close $fspx
       
       set i 1
       
       if { $i } {
          set logOUTSPX [exec -ignorestderr spx -batch  $SPX_InputName]
          echo $logOUTSPX 
       }
    }

    echo " Raphael Input file  for Contact and RC calculations"
    
    set fsi [ open $RPH_InputName w+ ]
    puts $fsi " ## Raphael Input file  for Contact and RC calculations ## "
    
    
    puts $fsi " pdbSet Mechanics StressHistory 0 "
    puts $fsi " pdbSet Mechanics EtchDepoRelax 0 "
    puts $fsi ""
    puts $fsi " ### Example to define material properties ##"
    puts $fsi " mater add name= SiON new.like= Oxide "
    puts $fsi " pdbSet SiON Potential Permittivity 3.5 "
    puts $fsi " "
    puts $fsi " pdbSet Silicon Conductor 0 "
    puts $fsi " pdbSet Copper Potential Conductivity 596000"
    puts $fsi " mater add name= TiNitride  new.like= Copper "
    puts $fsi " pdbSet TiNitride Potential Conductivity 3000"
    puts $fsi "   "
    if { [dict size $resistivities] > 0 } {
        puts $fsi " ## BEGIN: Material properties from PE material library or MaterialDependent parameter ##"
        puts $fsi ""
        foreach mat [dict keys $resistivities] {
            if { $mat == "Gas" } {
                continue
            }
            set resi [lindex [spx::quantity Quantity=[dict get $resistivities $mat] In= "ohm*cm"] 0]
            set perm [dict get $permittivities $mat]
            # detect conductor in PE is <1e-3 assuming ohm*m, hence 1e-1 ohm*cm
            if { [expr [lindex $resi 0] < 1e-1] } {
                # conductors
                puts $fsi "# mater add name= $mat new.like= Copper "
                puts $fsi "# pdbSet $mat Potential Conductivity [lindex $resi 0]"
            } else {
                # insulators
                puts $fsi "# mater add name= $mat new.like= Oxide "
                puts $fsi "# pdbSet $mat Potential Permittivity $perm "
            }
        }
        puts $fsi ""
        puts $fsi " ## END: Material properties from PE material library or MaterialDependent parameter ##"
        puts $fsi ""
    }
    if { [file exists MaterialParams.tcl] } {
       puts $fsi " source MaterialParams.tcl "
       puts "Info: source file MaterialParams.tcl in Raphael cmd"
    }
    if { [file exists C_MaterialParams.tcl] && [string match *capacitance* $extract_type] } {
       puts $fsi " source C_MaterialParams.tcl "
       puts "Info: source file C_MaterialParams.tcl in Raphael cmd"
    }
    if { [file exists R_MaterialParams.tcl] && [string match *resistance*  $extract_type] } {
       puts $fsi " source R_MaterialParams.tcl "
       puts "Info: source file R_MaterialParams.tcl in Raphael cmd"
    }

    if { ! $new_raph } {
       puts $fsi " ## load bnd file ##  "
       puts $fsi " init tdr= ${FileName}_spx_bnd.tdr "
       puts $fsi "   "
    } else {
       puts $fsi "   "
       puts $fsi " # Settings for boundary extraction; must be placed before init tdr="
       puts $fsi " pdbSet InfoDefault 1 "
       puts $fsi "   "
       puts $fsi " set adv_res 0.5 "
       puts $fsi " set adv_tol 0.1          ;# <0.3 "
       puts $fsi " set adv_aspect_ratio 10 "
       puts $fsi "  "
       puts $fsi " boundary spx2brep.method        = \"Standard\" ;# \"Advanced\" or \"Standard\" "
       puts $fsi " boundary spx2brep.advanced.vertical.resolution = \$adv_res       	;# default: 0.5 "
       puts $fsi " boundary spx2brep.advanced.tolerance = \$adv_tol 			;# default: 0.1 "
       puts $fsi " boundary spx2brep.advanced.vertical.aspect.ratio = \$adv_aspect_ratio	;# default: 10 "
       puts $fsi "  "
       puts $fsi " boundary spx2brep.standard.decimation = true			;# default: true "
       puts $fsi " boundary spx2brep.standard.decimation.accuracy=1e-8		;# default: 1e-8 "
       puts $fsi " boundary spx2brep.standard.decimation.shortest.edge=1e-8	;# default: 1e-8 "
       puts $fsi " boundary spx2brep.standard.decimation.ridge.angle=150	;# default: 150 "
       puts $fsi "  "
       if {[file exists BNDExtraction.tcl] } {
          puts $fsi "   "
          puts $fsi " # Overwrite BND settings above "
          puts $fsi " source BNDExtraction.tcl "  
          puts "Info: source file BNDExtraction.tcl in Raphael cmd"
          puts $fsi "   "
       } 

       puts $fsi "   "
       puts $fsi " ## load gc tdr file ##  "
       puts $fsi " init tdr= ${FileName}.tdr "
       puts $fsi "   "

       # BndTdr only
       if {[file exists keyBndTdrOnly]} {
          puts ""
          puts "INFO: File keyBndTdrOnly in working directory causes tool to generate bnd tdr and cmd only. " 
          puts $fsi "   "
          puts $fsi "## output bnd tdr (suffix _rcx)  "
          puts $fsi " struct tdr= ${FileName} "
          puts $fsi "   "
          puts $fsi " exit  "
          puts $fsi "   "
          puts "... Done!  Exit Raphael."
          puts ""
       }

       puts $fsi " # Check for missing pdbSet  "
       puts $fsi " set reglist \[region list.bulk\]  "
       puts $fsi " set matlist {}  "
       puts $fsi " foreach reg \$reglist {  "
       puts $fsi "    set mat \[region name= \$reg material\]  "
       puts $fsi "    lappend matlist \$mat  "
       puts $fsi " }  "
       puts $fsi " set matlist \[lsort -unique \$matlist\]  "
       puts $fsi " puts \"\" "
       puts $fsi " puts \"INFO: all materials in tdr: \$matlist\" "
       puts $fsi " LogFile \"INFO: all materials in tdr: \$matlist\" "
       puts $fsi " puts \"\" "
       puts $fsi " set matPdbError 0  "
       puts $fsi " foreach mt \$matlist {  "
       puts $fsi "    if { ! \[pdbIsAvailable \$mt Potential\] } {  "
       puts $fsi "  	  puts stderr \"\"  "
       puts $fsi "  	  puts stderr \"Error: Material \$mt is missing pdbSet definition!\"   "
       puts $fsi "  	  LogFile \"Error: Material \$mt is missing pdbSet definition!\"   "
       puts $fsi "  	  puts stderr \"       ... Raphael will exit shortly!\"   "
       puts $fsi "  	  puts stderr \"\"  "
       puts $fsi "       set matPdbError 1  "
       puts $fsi "    }  "
       puts $fsi " }  "
       puts $fsi " if { \$matPdbError } {  "
       puts $fsi "    LogFile \"Error: Material(s) shown above have no pdbSet definition!\"  "
       puts $fsi "    LogFile \"       Please add definition in MaterialParams.tcl !\"  "
       puts $fsi "    LogFile \"\"  "
       puts $fsi "    LogFile \"... exit Raphael\"  "
       puts $fsi "    LogFile \"\"  "
       puts $fsi "    exit  "
       puts $fsi " }  "
       puts $fsi " # end checking pdbSet  "

       puts $fsi "   "
       if { [string match *capacitance* $extract_type] } {
          if {[file exists C_MergeMaterials.tcl]} {
             puts $fsi " # User commands to merge materials "  
             puts $fsi " source C_MergeMaterials.tcl "  
             puts $fsi " TakeRegionSnapshot "  
             puts "Info: source file C_MergeMaterials.tcl in Raphael cmd"
          } else {
             puts $fsi " set merge_conductor \"All\" "
             puts $fsi " if { \$merge_conductor == \"All\"} {  "
             puts $fsi "    set target_conductor \"Copper\" "
             puts $fsi "    set reglist \[region list.bulk\] "
             puts $fsi "    foreach reg \$reglist { "
             puts $fsi "        set mat \[region name= \$reg material\] "
             puts $fsi "        set is_conductor \[pdbGet \$mat Conductor\] "
             puts $fsi "        if { \$is_conductor && \$mat != \$target_conductor } { "
             puts $fsi "           region name= \$reg \$target_conductor change.material !zero.data         "
             puts $fsi "           puts \"region: \$reg\" "
             puts $fsi "           puts \"    -> material \$mat is changed to \$target_conductor\" "
             puts $fsi "        } "
             puts $fsi "    } "
             puts $fsi " } "
             puts $fsi " TakeRegionSnapshot "  
          }
       }
       if { [string match *resistance* $extract_type] } {
          if {[file exists R_MergeMaterials.tcl]} {
             puts $fsi " # User commands to merge materials "
             puts $fsi " source R_MergeMaterials.tcl " 
             puts $fsi " TakeRegionSnapshot " 
             puts "Info: source file R_MergeMaterials.tcl in Raphael cmd"
          }
       }
    }

    puts $fsi "   "
    puts $fsi " math coord.ucs "
    puts $fsi "   "
    puts $fsi " ## Mesh Options ## "
    puts $fsi " refinebox clear  "
    puts $fsi " pdbSet Grid SnMesh MaxPoints 			5000000  "
    puts $fsi " pdbSet Grid SnMesh min.normal.size 		0.010  "
    puts $fsi " refinebox interface.materials= {All All}  "
    puts $fsi "   "
    if { [file exists MeshSettings.tcl] } {
       puts $fsi " source MeshSettings.tcl "
       puts "Info: source file MeshSettings.tcl in Raphael cmd"
    }
    if { [file exists C_MeshSettings.tcl] && [string match *capacitance* $extract_type] } {
       puts $fsi " source C_MeshSettings.tcl "
       puts "Info: source file C_MeshSettings.tcl in Raphael cmd"
    }
    if { [file exists R_MeshSettings.tcl] && [string match *resistance* $extract_type] } {
       puts $fsi " source R_MeshSettings.tcl "
       puts "Info: source file R_MeshSettings.tcl in Raphael cmd"
    }
    puts $fsi "   "
    puts $fsi " grid remesh  "
    puts $fsi "   "
    
    # begin resistance type
    if { [string match *resistance* $extract_type] } {
       puts $fsi " # pdbSet Silicon Conductor 1" 
       puts $fsi "   "
    puts $fsi "   "
    puts $fsi " contact clear "   

    puts $fsi "   "
    puts $fsi "# square contact size on interface; contact border must be within contact interface(s) to avoid crash."
    puts $fsi "set contact_size   0.001"
    puts $fsi "# contact box offset above or below the interface; should be less than the min layer thickness from both sides."
    puts $fsi "set contact_offset 0.001"
    puts $fsi "   "
    if { [file exists R_ContactSize.tcl] } {
       puts $fsi " source R_ContactSize.tcl "
       puts "Info: source file R_ContactSize.tcl in Raphael cmd"
    }
    puts $fsi "   "

    # Raphael J-2014.09-ENG1
    if { $raph_version == "Version J-2014.09"} {

       if { [string length $RegionName1] == 0 || [string length $RegionName2] == 0 }  {
           puts "Error: Either Contact1 or Contact2 does not exist!" 
	   puts "       Impossible to extract resistance!  Abort."
	   # skip raphael
	   set j 0
       }

    puts $fsi " set Mat1 \[ region name= $RegionName1 material \]"
    puts $fsi " set Mat2 \[ region name= $RegionName2 material \]"

    puts $fsi " contact name= $Contact1 region= \$Mat1 box xlo= $Contact1_Coord_x-\$contact_size\/2 ylo= $Contact1_Coord_y-\$contact_size\/2 zlo= $Contact1_Coord_z-\$contact_offset xhi= $Contact1_Coord_x+\$contact_size\/2 yhi= $Contact1_Coord_y+\$contact_size\/2 zhi= $Contact1_Coord_z+\$contact_offset  "
    puts $fsi " contact name= $Contact2 region= \$Mat2 box xlo= $Contact2_Coord_x-\$contact_size\/2 ylo= $Contact2_Coord_y-\$contact_size\/2 zlo= $Contact2_Coord_z-\$contact_offset xhi= $Contact2_Coord_x+\$contact_size\/2 yhi= $Contact2_Coord_y+\$contact_size\/2 zhi= $Contact2_Coord_z+\$contact_offset  "

    } else {
   # Raphael K-2015.06 or newer
    set cont_list { }
    foreach contact $filtered_contact_names {

        # pin info for full cap matrix
        set pin_name [lindex $contact 3] 
	lappend cont_list $pin_name
        set pin_coord [lindex $contact 6]
        set pnx [catch {set pin_x [format {%0.4f} [lindex $contact 6 0]]} fmx]
        set pny [catch {set pin_y [format {%0.4f} [lindex $contact 6 1]]} fmy]
        set pnz [catch {set pin_z [format {%0.4f} [lindex $contact 6 2]]} fmz]
        if { $pnx || $pny || $pnz } { echo "Warning: $pin_name coordinates missing" }
        set pin_region_name [lindex $contact 2] 

        puts $fsi " contact name= $pin_name region= $pin_region_name box zlo= $pin_x-\$contact_size\/2 ylo= $pin_y-\$contact_size\/2 xhi= -1*($pin_z-\$contact_offset) zhi= $pin_x+\$contact_size\/2 yhi= $pin_y+\$contact_size\/2 xlo= -1*($pin_z+\$contact_offset) "

    }
    puts $fsi "   "

    #check the number of contacts for resistance extraction
    set cont_list_u [lsort -unique $cont_list]
    set num_conts [llength $cont_list_u]
    echo "Info: The number of contacts in the clip is $num_conts"
    echo "List of contacts: $cont_list_u"
    echo "Info: The number of contacts in the clip is $num_conts"
    echo "List of contacts: $cont_list_u"
    if { $num_conts < 2 } {
	echo "Error: The number of contacts in the clip is less than 2!"
	echo "       Impossible to extract resistance!  Abort."
	echo " "
	puts " "
	puts "Error: The number of contacts in the clip is less than 2!"
	puts "       Impossible to extract resistance!  Abort."
	puts " "
	# skip raphael
	set j 0
    }

   }

    puts $fsi " grid remesh  "
    puts $fsi "   "
    puts $fsi " mode resistance "
    puts $fsi " solve  "
    puts $fsi "   "
    puts $fsi " struct tdr= ${FileName}_rph.tdr "
    puts $fsi " set R_${Contact1}_${Contact2} \[ printResistanceMatrix resistance.matrix $Contact1 $Contact2 \] "
    puts $fsi " LogFile  REXTRACTIONRESULT \$R_${Contact1}_${Contact2} " 
    puts $fsi " printResistanceMatrix spice.matrix ${FileName}.rMatrix.csv  "
    }
    # end resistance type
     
    
    # start capacitance type
    if { [string match *capacitance* $extract_type] } { 
    	
	if { [string match *resistance* $extract_type] } {
	puts $fsi " contact clear "
	puts $fsi " grid remesh  "
	}
    
    # echo "# ..."
    # echo "# ... Create command for rename region to pin name ..."
    puts $fsi "   "
    puts $fsi " ### Replace pin region name by pin name"

    foreach contact $filtered_contact_names {
       set pin_name [lindex $contact 3] 
       set pin_region_name [lindex $contact 2] 
       echo "... Pin Name: $pin_name"
       echo "... Pin Region Name: $pin_region_name"
       puts $fsi " region name= $pin_region_name new.name= $pin_name"
       echo "... pin region name is reassigned to pin name"
    }

    if { [llength $filtered_contact_names] < [llength $filtered_contact_coords] } {
       echo "... number of pin (text) locations is more than the number of pins (texts)"	
       puts ""
       puts "Info: Number of pin locations is more than the number of pins"	
       puts "... => one or more texts have multiple locations:"	
       foreach contact $filtered_contact_names {
          set pin_name   [lindex $contact 3]
          set pin_region [lindex $contact 2]
          set pin_match_list [lsearch -index 3 -exact -all -inline $filtered_contact_coords $pin_name]
          echo "pin_match $pin_match_list"
          set contact_merge_list {}
          if { [llength $pin_match_list] > 1 } {
               foreach pml $pin_match_list {
                   set pmreg  [lindex $pml 2]
                   set pmxy   [lindex $pml 6]
                   set pmname [lindex $pml 3]
                   echo "pm name: $pmname"
                   echo "pm region name: $pmreg"
                   echo "pm xy: $pmxy"
                   puts "... pin name       : $pmname"
                   puts "... pin region name: $pmreg"
                   puts "... pin location   : $pmxy"
                   if { $pmreg == $pin_region } {
                      lappend contact_merge_list $pin_name 
                   } else {
                      lappend contact_merge_list $pmreg 
                   }
               } 
               echo "Contact merge region list : [join $contact_merge_list " "] " 
               puts " "
               puts "Info: Contact merge region list : [join $contact_merge_list " "] " 
               puts "Info: Merge the above regions to contact: $pin_name "
               puts "      ... Contact merge works only with Raphael L-2016.03-ENG1 or later, if  "
               puts "      ... the regions themselves are merged by, for instance, material change."
               puts $fsi " contact merge = { [join $contact_merge_list " "] } "
               puts " "
          }
       }
    }

    puts $fsi "   "
    puts $fsi "   "
    puts $fsi "  mode capacitance"
    puts $fsi " solve  " 
    puts $fsi " struct tdr= ${FileName}_rph.tdr "
    puts $fsi "   "
    puts $fsi " printCapacitanceMatrix spice.matrix ${FileName}.cMatrix.csv  " 
    puts $fsi " printCapacitanceMatrix spice.matrix ${FileName}.cMatrix.spi  " 
    }
    # end capacitance type
   
    close $fsi 

  if { $j } {
      set MY_LD_LIBRARY_PATH ""
      if { [info exists ::env(LD_LIBRARY_PATH)] } {
          set MY_LD_LIBRARY_PATH $::env(LD_LIBRARY_PATH)
          array unset ::env LD_LIBRARY_PATH
      }
      set logOUTRaphael [exec -ignorestderr  raphael rcx $RPH_InputName ]
      echo $logOUTRaphael   
      if { [string length $MY_LD_LIBRARY_PATH] > 0 } {
          set ::env(LD_LIBRARY_PATH) $MY_LD_LIBRARY_PATH
      }

    set Revin [dict get $in rev]
    echo $Revin
    
    if { $Revin < 5  } {
        return [dict create]
    }


    if { [string match *capacitance* $extract_type] } {

      if { [file exists ${FileName}.cMatrix.csv] } {

        set filename [open ${FileName}.cMatrix.csv  r]
        set fileread [read $filename]
        set lines [split $fileread "\n"] 

        set LCV {}
        foreach line $lines {
            if { [string match "*$Contact1* , *$Contact2*,*"  $line] || [string match "*$Contact2* , *$Contact1*,*"  $line]} {
                if { $Revin <21 } {
                   set val [lindex $line 6]
		} else {
		   set val [list [lindex $line 6] "F"]
		}
                lappend LCV [list "capacitance" [lindex $line 2]  [lindex $line 4] $val ] 
            }
        }

        foreach line $lines {
            if { [string match "*,*,*,*"  $line] } {
                if { $Revin <21 } {
                   set val [lindex $line 6]
		} else {
		   set val [list [lindex $line 6] "F"]
		}
                lappend LCV [list "capacitance" [lindex $line 2]  [lindex $line 4] $val ] 
            }
        }
        echo $LCV
        foreach Capa  $LCV {  
        echo ""
        echo $Capa
        echo "" 
        }
      } else {
        puts "" 
        puts "Error: File cMatrix.csv doesn't exist: ${FileName}.cMatrix.csv "
        puts "    ... Check Raphael log file!" 
        puts "" 

        # set LCV empty to avoid error below
	    set LCV {}

      }
    }
 
    if { [string match *resistance* $extract_type] } {
        set getREX [catch {set RV [lindex [eval exec grep  REXTRACTIONRESULT  ${FileName}_rph.log ] end]} REXmsg]
        if { $getREX } {
           puts "" 
           puts "Error: Failed to extract resistance.  No resistance value from log file:"
           puts "     => ${FileName}_rph.log"
           puts "" 

           # set LRV empty to avoid error below
           set LRV {}

        } else {
           echo $RV
           if { $Revin >=21 } {
               set RV [list $RV "ohm"]
           }
           lappend LRV [list "resistance" $Contact1 $Contact2 $RV]
        }
    }
    
    if { [info exists LCV] && [info exists LRV] } { 
        set RES [lappend LCV [lindex $LRV 0] ]
    } elseif {[info exists LCV] } { 
        set RES $LCV 
    } else { 
      set RES $LRV
    }
    
    echo ""
    echo "RES = $RES "
    echo "" 
    set Revin [dict get $in rev]
    
    set out [dict create]
    if { $Revin <6 } {
        dict set out out_rc $RES
    }
    if { $Revin >= 6 } {
        dict set out Output $RES
    }

    return $out
   
  }
  # end of rcx
}

### meas_RC routing function body (e.g. rcx vs. rcfx) ###

# rcfx is the default, only if parameter or custom property UseRCX is set and
# if it is true rcx is used.
proc meas__RCExec {in doeIdParam routeIdParam flowIdParam moduleIdParam stepIdParam {end {}}} {
    
    if { [dict exists $in UseRCX] } {
        set useRcx [dict get $in UseRCX]
        if { $useRcx } {
            return [meas__RCExec_rcx $in DOE Route Flow Module Step]
        }
    }
    return [meas__RCExec_rcfx $in DOE Route Flow Module Step]
}

#### per rev function bodies

for {set rev 5} {$rev < 15} {incr rev} {
    eval "proc meas__RC${rev}Exec {in {end {}}} { return \[meas__RCExec \$in _doe_id _rout_id _flow_id _modu_id _step_id\] }"
}

for {set rev 15} {$rev <= [spx::current_rev]} {incr rev} {
    eval "proc meas__RC${rev}Exec {in {end {}}} { return \[meas__RCExec \$in DOE Route Flow Module Step\] }"
}

#### exec when sourcing this file

# measRCVersion
