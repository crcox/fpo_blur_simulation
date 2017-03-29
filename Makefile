TXT_MASK = fpo_all_tlrc_coords.csv
AFNI_MASK = unionmask_3mm+tlrc.HEAD
AFNI_MASK_PREFIX = $(subst +tlrc.HEAD,,$(AFNI_MASK))
AFNI_MASK_DUMP = unionmask_voxel_list.txt
TLRC_MASTER_1mm = TT_N27+tlrc.HEAD
TLRC_MASTER = TT_N27_3mm+tlrc.HEAD
TLRC_MASTER_PREFIX = $(subst +tlrc.HEAD,,$(TLRC_MASTER))
RESULTS = results.txt
RESULTS_W_INDEX = unionmask_results.txt
AFNI_RESULTS_PREFIX = unionmask_3mm_blurvol
AFNI_RESULTS = unionmask_3mm_blurvol+tlrc.HEAD
FWHM = 4

resample : $(TLRC_MASTER_1mm)
	-rm -f $(TLRC_MASTER_PREFIX)+tlrc.HEAD
	-rm -f $(TLRC_MASTER_PREFIX)+tlrc.BRIK
	-rm -f $(TLRC_MASTER_PREFIX)+tlrc.BRIK.gz
	3dresample -dxyz 3 3 3 -prefix $(TLRC_MASTER_PREFIX) -inset $(TLRC_MASTER_1mm)

mask : $(TXT_MASK) $(TLRC_MASTER)
	-rm -f $(AFNI_MASK_PREFIX)+tlrc.HEAD
	-rm -f $(AFNI_MASK_PREFIX)+tlrc.BRIK
	-rm -f $(AFNI_MASK_PREFIX)+tlrc.BRIK.gz
	3dUndump -master $(TLRC_MASTER) -xyz -prefix $(AFNI_MASK_PREFIX) $(TXT_MASK)

dump : $(AFNI_MASK)
	-rm -f $(AFNI_MASK_DUMP)
	3dmaskdump -mask $(AFNI_MASK) -o $(AFNI_MASK_DUMP) $(AFNI_MASK)
	
simulation : $(AFNI_MASK_DUMP) $(TLRC_MASTER) $(AFNI_MASK)
	./run_simulation.sh $(AFNI_MASK_DUMP) $(TLRC_MASTER) $(AFNI_MASK) $(FWHM) $(RESULTS)

index_results : $(AFNI_MASK_DUMP) $(RESULTS)
	cut -d' ' -f1-3 $(AFNI_MASK_DUMP)|paste -d' ' - $(RESULTS)>$(RESULTS_W_INDEX)

results2vol : $(RESULTS_W_INDEX) $(TLRC_MASTER)
	-rm -f $(AFNI_RESULTS_PREFIX)+tlrc.HEAD
	-rm -f $(AFNI_RESULTS_PREFIX)+tlrc.BRIK
	-rm -f $(AFNI_RESULTS_PREFIX)+tlrc.BRIK.gz
	3dUndump -master $(TLRC_MASTER) -ijk -datum float -prefix $(AFNI_RESULTS_PREFIX) $(RESULTS_W_INDEX)
	3drefit -fim $(AFNI_RESULTS)
