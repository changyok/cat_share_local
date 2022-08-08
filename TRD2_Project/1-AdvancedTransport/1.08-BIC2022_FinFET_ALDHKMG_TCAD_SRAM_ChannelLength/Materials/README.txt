o Version History
  Nov 27, 2013  v1.0  First version


o Description of How Material and Molefraction Parameters are Set

S-Band does not contain a built-in framework like S-Device for
interpolating model parameters based on molefraction. Instead, we use
Tcl procedures to do this interpolation and then set the needed model
parameters explicitly.
 
This means that in a S-Band command file, the material and molefraction
dependent parameters need to be set explicitly for each semiconductor
material. For example, for a device with a semiconductor region called
semi1, a typical call from the main s-band command file would be:

 1. source ./Materials/MaterialPhysics.tcl
    Source the MaterialPhysics.tcl Tcl file to define the needed Tcl
    procedures

 2. Compute the strain tensor for uniaxail strain for the specified
    Material and molefraction. The needed compliance tensor is automatically
    computed for the given molefraction
    set strainTensor [computeUniaxialStrain @Material@ @xMolefrac@ @Stress@ $channelAxis]

 3. Physics region=semi1 CrystalStrain strain=$strainTensor
    This sets the strain tensor in region semi1

 4. set a0 [computeRelaxedLatticeParameter @Material@ @xMolefrac@]; # lattice spacing in [cm]
    This set the relaxed lattice parameter for the specific material
    with specified molefraction. a0 is needed by the Schrodinger solvers
   
 5. setupInsulatorParameters @Material@; # pass-in semi material
    This sets the model parameters for insulator including the effective
    mass to use for oxide penetration. This mass can depend on the
    semiconductor material
   
 6. setupMaterialParameters @Material@ semi1 @xMolefrac@ $strainTensor
    This set all the material parameters for the indicated material in
    region semi for the indicated molefraction and strain tensor

The main Tcl procedure, setupMaterialParameters, first reads in two
tables of model parameters. One of the tables,
e.g. SiGe_SDeviceElectrostaticParams.txt, specifies the molefraction
dependence of the classical electrostatic parameters. These parameters
are consistent with S-Device. The second table,
e.g. SiGe_BandParams.txt, specicies various band parameters as a
function of molefraction including valley energy shift, valley masses,
valley non-parabolicity, and deformation potentials. Based on these
parameters, the final value is piecewise linear interpolated based on
the molefraction.
