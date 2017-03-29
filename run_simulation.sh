#!/bin/bash -e
coordlist=$1
tlrcmaster=$2
mask=$3
fwhm=$4
logfile=$5
current_coord=$(mktemp -t blursimcoord.XXXXXX)
current_vol_point=$(mktemp -t blursimpoint.XXXXXX)
current_vol_blur=$(mktemp -t blursimblur.XXXXXX)
current_vol_blur_masked=$(mktemp -t blursimblur.XXXXXX)
tmplogfile=$(mktemp -t blursimlog.XXXXXX)
nvox=$(wc -l $coordlist| awk '{print $1}')

echo "Simulation progress:"
i=0
while read coord; do
	i=$((i+1))
	p=$(bc <<< "scale = 4; ($i/$nvox)*100")
	echo -ne "\rvoxel $i ($p%)"
	echo $coord > $current_coord
	if [ "$i" -gt "0" ]; then
		rm -f ${current_vol_point}+tlrc.HEAD
		rm -f ${current_vol_point}+tlrc.BRIK
		rm -f ${current_vol_blur}+tlrc.HEAD
		rm -f ${current_vol_blur}+tlrc.BRIK
		rm -f ${current_vol_blur_masked}+tlrc.HEAD
		rm -f ${current_vol_blur_masked}+tlrc.BRIK
	fi
	3dUndump                               \
		-master "${tlrcmaster}"        \
		-ijk                           \
		-datum float                   \
		-prefix "${current_vol_point}" \
		"${current_coord}" > /dev/null 2>&1
	3dmerge                             \
		-1blur_fwhm $fwhm           \
		-prefix ${current_vol_blur} \
		"${current_vol_point}+tlrc.HEAD" > /dev/null 2>&1
	3dcalc \
		-a "${current_vol_blur}+tlrc.HEAD" \
		-b "${mask}" \
		-expr 'a*b' \
		-prefix ${current_vol_blur_masked} > /dev/null 2>&1
	3dBrickStat       \
		-count    \
		-non-zero \
		${current_vol_blur_masked}+tlrc.HEAD >> ${tmplogfile} 2> /dev/null
done < $coordlist
echo ""
mv -iv ${tmplogfile} ${logfile}
