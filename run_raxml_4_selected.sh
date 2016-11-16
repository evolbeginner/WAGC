#! /bin/bash


#####################################################################
mnt3_sswang=/mnt/bay3/sswang
scripts=$mnt3_sswang/lian_xi/gc_test/scripts

seqmagick=~/software/sequence_analysis/seqmagick/seqmagick.py
seq_gen=~/software/sequence_analysis/Seq-Gen.v1.3.3/source/seq-gen
WAGC=$scripts/WAGC.rb
generateTree4Simulation=$scripts/generateTree4Simulation.rb
putativeGC_from_seqSimilarity=$scripts/putativeGC_from_seqSimilarity.rb
detectRegionOfGC=$scripts/detectRegionOfGC.rb
getFinalCoors=$scripts/getFinalCoors.rb
convert_ali_format=~/tools/self_bao_cun/basic_process_mini/convert_ali_format.py


#####################################################################
while [ $# -gt 0 ]; do
	case $1 in
		--outdir)
			outdir=$2
			shift
			;;
		--aln_dir|--alndir)
			aln_dir=$2
			shift
			;;
		--pre_raxml)
			pre_raxml_dir=$2
			shift
			;;
		--mauve)
			mauve=$2
			shift
			;;
	esac
	shift
done


if [ -z $outdir -o -z $aln_dir -o -z $pre_raxml_dir -o -z $mauve ]; then
	echo "outdir, aln_dir, pre_raxml_dir and mauve have to be given! Exiting ......"
	exit
fi

mkdir -p $outdir


#####################################################################
for j in `find $pre_raxml_dir -name 'FastTree.gc_range'`; do
	b=`basename $j`
	d=`dirname $j`
	c=${d#*/}
	if [ -s $j ]; then
		echo $c
		aln=$aln_dir/8_4/combined/$c.aln
		#ruby $WAGC -i $aln --outdir $outdir/$c --force >/dev/null;
		length=`python $seqmagick info --input-format fasta $aln | tail -1 | awk '{print $4}'`
		target_outdir=$outdir/$c
		for i in `seq 100`; do
			simulation_dir=$target_outdir/simulation/$i
			mkdir -p $simulation_dir
			ruby $generateTree4Simulation --tree $outdir/$c/tree/wholeMolecule_tree/RAxML_bestTree.wholeMolecule > $simulation_dir/1.tree
			$seq_gen -mGTR -op -l$length -q < $simulation_dir/1.tree 2>/dev/null | python $convert_ali_format -i - -o $simulation_dir/1.aln --in_fmt phylip --out_fmt fasta
			if [ ! -s $simulation_dir/1.aln ]; then continue; fi
			ruby $WAGC -i $simulation_dir/1.aln --outdir $simulation_dir/simulation_raxml/ --step 5 -l 50 --cpu 2 --force --no_FastTree >/dev/null;
		done

		lnL_min=`find $target_outdir -name lnL -exec awk 'BEGIN{max=-10}{if($1>max){max=$1}}END{print max}' {} \; | sort -n | tail -6 | head -1`
		for i in `find $target_outdir/tree/subseq/ -name 'RAxML_bestTree.*'`; do ruby $putativeGC_from_seqSimilarity --tree $i --mauve $mauve --no_bootstrap; done > $target_outdir/raxml.putative_GC
		coors_included=`ruby $getFinalCoors -i $target_outdir/lnL --lnL_min $lnL_min`
		ruby2.1 $detectRegionOfGC -i $target_outdir/raxml.putative_GC --type raxml > $target_outdir/raxml.ori.gc_range
		ruby2.1 $detectRegionOfGC -i $target_outdir/raxml.putative_GC --type raxml --coor $coors_included > $target_outdir/raxml.gc_range
		exit
	fi
done


