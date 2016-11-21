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
delNullFromRaxml=$scripts/delNullFromRaxml.rb

convert_ali_format=~/tools/self_bao_cun/basic_process_mini/convert_ali_format.py
trimal=$mnt3_sswang/software/sequence_analysis/trimal/source/trimal

cpu=2


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
		--gc_info)
			gc_info_file=$2
			shift
			;;
		--mauve)
			mauve=$2
			shift
			;;
		--cpu)
			cpu=$2
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
	unset c
	b=`basename $j`
	d=`dirname $j`
	c=${d#*/}

	if [ -s $j ]; then
		export c=$c
		output=`awk '{a=$5;gsub(/[(].+/,"",$5);alns[$5]=""}END{if(ENVIRON["c"] in alns){print ENVIRON["c"]}}' $gc_info_file`
		if [ -z $output ]; then
			continue
		fi
		echo $c

		aln=$aln_dir/$c.aln
		[ ! -f $aln ] && continue

		target_outdir=$outdir/$c
		[ -d $outdir/$c ] && rm -rf $target_outdir
		mkdir -p $target_outdir
		trimmed_aln=$target_outdir/$c.trimmed.aln
		$trimal -in $aln -out $trimmed_aln -gt 1
		length=`python $seqmagick info --input-format fasta $trimmed_aln | tail -1 | awk '{print $4}'`
		ruby $WAGC -i $aln --outdir $target_outdir --no_FastTree --cpu $cpu >/dev/null;

		filesize=`ls -l $trimmed_aln | awk '{ print $5 }'`
		num_of_cycle=100
		th_cutoff=6
		max=$((3000*10));
		if [ $filesize -gt $max ]; then
			num_of_cycle=50
			th_cutoff=3
		else
			num_of_cycle=100
			th_cutoff=6
		fi

		if [ `ruby $delNullFromRaxml --gc_range_file $pre_raxml_dir/$c/FastTree.gc_range --lnL_file $target_outdir/lnL | wc -l` -eq 0 ]; then
			continue
		fi

		max_lnL_file=$target_outdir/max_lnL
		touch $max_lnL_file
			
		for i in `seq $num_of_cycle`; do
			simulation_dir=$target_outdir/simulation/$i
			mkdir -p $simulation_dir
			ruby $generateTree4Simulation --tree $outdir/$c/tree/wholeMolecule_tree/RAxML_bestTree.wholeMolecule > $simulation_dir/1.tree
			$seq_gen -mGTR -op -l$length -q < $simulation_dir/1.tree 2>/dev/null | python $convert_ali_format -i - -o $simulation_dir/1.aln --in_fmt phylip --out_fmt fasta
			if [ ! -s $simulation_dir/1.aln ]; then continue; fi
			ruby $WAGC -i $simulation_dir/1.aln --outdir $simulation_dir/simulation_raxml/ --step 5 -l 50 --cpu $cpu --force --no_FastTree >/dev/null;
			awk 'BEGIN{max=-10}{if($1>max){max=$1}}END{print max}' $simulation_dir/simulation_raxml/lnL  >> $max_lnL_file
			if [ `ruby $delNullFromRaxml --gc_range_file $pre_raxml_dir/$c/FastTree.gc_range --lnL_file $target_outdir/lnL --max_lnL_file $max_lnL_file --max_num_of_failed $(($th_cutoff-1)) | wc -l` -eq 0 ]; then
				break
			fi
		done

		lnL_min=`find $target_outdir -name lnL -exec awk 'BEGIN{max=-10}{if($1>max){max=$1}}END{print max}' {} \; | sort -n | tail -n $th_cutoff | head -1`
		for i in `find $target_outdir/tree/subseq/ -regex ".*RAxML_\(fastTree.*\|bestTree.*\)"`; do ruby $putativeGC_from_seqSimilarity --tree $i --mauve $mauve --no_bootstrap; done > $target_outdir/raxml.putative_GC
		coors_included=`ruby $getFinalCoors -i $target_outdir/lnL --lnL_min $lnL_min`
		ruby2.1 $detectRegionOfGC -i $target_outdir/raxml.putative_GC --type raxml > $target_outdir/raxml.ori.gc_range
		ruby2.1 $detectRegionOfGC -i $target_outdir/raxml.putative_GC --type raxml --coor $coors_included > $target_outdir/raxml.gc_range
	fi
done


