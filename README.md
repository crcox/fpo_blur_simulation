Face Place Object Dataset: Simulation of masked gaussian blur
=============================================================

The purpose of this simulation is to determine the probability of a voxel being selected after accounting for bluring.

Procedure
---------
1. Each subject's native-space coordinates were manually warped to TLRC space.
2. These coordinates were concatenated into a single text file, which was then projected into an AFNI volume using a version of the `TT_N27+tlrc.HEAD` standard atlas which has been resampled to have 3x3x3mm voxels. This defines a union mask with all unique voxels represented on a common grid.
3. This shared coordinate and index space is then dumped to a text file.
4. This text file dump off all voxel indexes in the mask is then looped over, and a temporary volume is generated (using the 3mm variant of the `TT_N27` atlas as the master) with only that single voxel filled in.
5. A 4mm FWHM Guassian kernel is then used to smooth that voxel (which always yields a spherical volume containing 125 voxels).
6. The 125 voxel sphere is then intersected with the union mask, and the number of voxels falling within the mask is counted and written to disk.
7. After repeating this procedure for all voxels, the masked-blur-volumes are matched up with their voxel coordinates, and a volume is created that represents the solution. The value stored at each voxel in this solution encodes how many voxels within the mask will be "turned on" if that voxel initially stored a value of 1 and was blurred with a 4mm FWHM kernel (assuming no other neighboring voxels are involved).

Files
-----
The results are stored in `unionmask_3mm_blurvol+tlrc.HEAD` and `unionmask_results.txt` (IJK coordinates and masked-blur-volumes). The initial coordinate dump mentioned in step (2) above is in `fpo_all_tlrc_coords.csv`. The `TT_N27` atlas used as a master for generating volumes is `TT_N27_3mm+tlrc.HEAD`, and this is derived from `TT_N27+tlrc.HEAD`. The shell script `run_simulation.sh` does the heavy-lifting of running the simulation, which the Makefile handles setup, execution, and finishing touches in a simple interface.

Reproducability
---------------
If you have:

1. `fpo_all_tlrc_coords.csv`
2. `TT_N27+tlrc.HEAD`
3. `run_simulation.sh`
4. Makefile

all in the same directory, running:

```
make all
```

will reproduce the full simulation. Altering these files or changing the FWHM (defined within the Makefile) will obviously change the results of the simulation.

Chris Cox (29/03/2017)
christopher.cox-2@manchester.ac.uk
