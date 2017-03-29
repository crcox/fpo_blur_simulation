# PARAMETERS
# N.B. These parameters can be overridden from the commandline when invoking
# make. For example: make OUTDIR=MySim FWHM=2
FWHM = 4
OUTDIR = out
INDIR = .

# FILE NAMES
# N.B. If you modify these variables, leave off the file extensions. Full
# filenames will be composed automatically from these basenames (i.e., the file
# name without path or extension). Technically, basenames can be relative
# paths, with their roots anchored in OUTDIR and INDIR, as the case may be, but
# there should be no need nest directories within the IN- and OUTDIRS.
## Inputs
DUMP_ALLCOORDS_BASENAME  = fpo_all_tlrc_coords
TLRC_MASTER_1mm_BASENAME = TT_N27
## Intermediate
TLRC_MASTER_3mm_BASENAME = TT_N27_3mm
AFNI_MASK_BASENAME       = unionmask_3mm
DUMP_MASK_BASENAME       = $(AFNI_MASK_BASENAME)_voxel_list
## Outputs
RESULTS_BASENAME         = blurvol
DUMP_RESULTS_BASENAME    = $(AFNI_MASK_BASENAME)_$(RESULTS_BASENAME)
AFNI_RESULTS_BASENAME    = $(AFNI_MASK_BASENAME)_$(RESULTS_BASENAME)

## Input (auto-fill)
DUMP_ALLCOORDS_PREFIX = $(addprefix $(INDIR)/, $(DUMP_ALLCOORDS_BASENAME))
DUMP_ALLCOORDS = $(addsuffix .csv, $(DUMP_ALLCOORDS_PREFIX))
TLRC_MASTER_1mm_PREFIX = $(addprefix $(INDIR)/, $(TLRC_MASTER_1mm_BASENAME))
TLRC_MASTER_1mm = $(addsuffix +tlrc.HEAD, $(TLRC_MASTER_1mm_PREFIX))
## Intermediate (auto-fill)
AFNI_MASK_PREFIX = $(addprefix $(OUTDIR)/, $(AFNI_MASK_BASENAME))
AFNI_MASK = $(addsuffix +tlrc.HEAD, $(AFNI_MASK_PREFIX))
DUMP_MASK_PREFIX = $(addprefix $(OUTDIR)/, $(DUMP_MASK_BASENAME))
DUMP_MASK = $(addsuffix .txt, $(DUMP_MASK_PREFIX))
TLRC_MASTER_3mm_PREFIX = $(addprefix $(OUTDIR)/, $(TLRC_MASTER_3mm_BASENAME))
TLRC_MASTER_3mm = $(addsuffix +tlrc.HEAD, $(TLRC_MASTER_3mm_PREFIX))
## Output (auto-fill)
RESULTS_PREFIX = $(addprefix $(OUTDIR)/, $(RESULTS_BASENAME))
RESULTS = $(addsuffix .txt, $(RESULTS_PREFIX))
DUMP_RESULTS_PREFIX = $(addprefix $(OUTDIR)/, $(DUMP_RESULTS_BASENAME))
DUMP_RESULTS = $(addsuffix .txt, $(DUMP_RESULTS_PREFIX))
AFNI_RESULTS_PREFIX = $(addprefix $(OUTDIR)/, $(AFNI_RESULTS_BASENAME))
AFNI_RESULTS = $(addsuffix +tlrc.HEAD, $(AFNI_RESULTS_PREFIX))

# Tasks
all : results2vol 
resample : $(TLRC_MASTER_3mm)
mask : $(AFNI_MASK)
dump : $(DUMP_MASK)
simulation : $(RESULTS)
index_results : $(DUMP_RESULTS)
results2vol : $(AFNI_RESULTS)

# Rules
$(TLRC_MASTER_3mm) : $(TLRC_MASTER_1mm)
	-rm -f $(TLRC_MASTER_3mm_PREFIX)+tlrc.HEAD
	-rm -f $(TLRC_MASTER_3mm_PREFIX)+tlrc.BRIK
	-rm -f $(TLRC_MASTER_3mm_PREFIX)+tlrc.BRIK.gz
	3dresample -dxyz 3 3 3 -prefix $(TLRC_MASTER_3mm_PREFIX) -inset $(TLRC_MASTER_1mm)

$(AFNI_MASK) : $(DUMP_ALLCOORDS) $(TLRC_MASTER_3mm)
	-rm -f $(AFNI_MASK_PREFIX)+tlrc.HEAD
	-rm -f $(AFNI_MASK_PREFIX)+tlrc.BRIK
	-rm -f $(AFNI_MASK_PREFIX)+tlrc.BRIK.gz
	3dUndump -master $(TLRC_MASTER_3mm) -xyz -prefix $(AFNI_MASK_PREFIX) $(DUMP_ALLCOORDS)

$(DUMP_MASK) : $(AFNI_MASK)
	-rm -f $(DUMP_MASK)
	#3dmaskdump -mask $(AFNI_MASK) -o $(DUMP_MASK) $(AFNI_MASK)
	3dmaskdump -mask $(AFNI_MASK) $(AFNI_MASK)|head > $(DUMP_MASK) 
	
$(RESULTS) : $(DUMP_MASK) $(TLRC_MASTER_3mm) $(AFNI_MASK)
	./run_simulation.sh $(DUMP_MASK) $(TLRC_MASTER_3mm) $(AFNI_MASK) $(FWHM) $(RESULTS)

$(DUMP_RESULTS) : $(DUMP_MASK) $(RESULTS)
	cut -d' ' -f1-3 $(DUMP_MASK)|paste -d' ' - $(RESULTS)>$(DUMP_RESULTS)

$(AFNI_RESULTS) : $(DUMP_RESULTS) $(TLRC_MASTER_3mm)
	-rm -f $(AFNI_RESULTS_PREFIX)+tlrc.HEAD
	-rm -f $(AFNI_RESULTS_PREFIX)+tlrc.BRIK
	-rm -f $(AFNI_RESULTS_PREFIX)+tlrc.BRIK.gz
	3dUndump -master $(TLRC_MASTER_3mm) -ijk -datum float -prefix $(AFNI_RESULTS_PREFIX) $(DUMP_RESULTS)
	3drefit -fim $(AFNI_RESULTS)
