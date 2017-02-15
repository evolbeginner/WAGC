#! /bin/bash


#########################################################################
get_subseq=~/tools/self_bao_cun/basic_process_mini/get_subseq.rb

seq_indir=sequences
seq_outdir=full_length/pep_seq/
blast_outdir=full_length/blast


#########################################################################
while [ $# -gt 0 ]; do
	case $1 in
		-i)
			infile=$2
			shift
			;;
		--blast_db)
			blast_db=$2
			shift
			;;
		--seq_indir)
			seq_indir=$2
			shift
			;;
	esac
	shift
done


[ -z $blast_db ] && echo "blast_db has to be given! Exiting ......" && exit

[ ! -d $seq_outdir ] && mkdir -p $seq_outdir
[ ! -d $blast_outdir ] && mkdir -p $blast_outdir


#########################################################################
while read line; do
	#full_length/phylo/371/RAxML_bipartitionsBranchLabels.371	Mpal|MSWAN_0440	Mpal|MSWAN_1089	Metbo_2206	Metbo_1509,MTBMA_c11810,MTH_785	92
	tree_file=`echo $line | cut -d ' ' -f 1`
	seq_full_name=`echo $line | cut -d ' ' -f 2`
	b=`basename $tree_file`
	corename=`grep -Po '\d+$' <<< $b`
	seq_name=`grep -Po '[^|]+$' <<<$seq_full_name`
	a=`grep $seq_name $seq_indir/*pep.fas`
	seq_infile=`echo $a | cut -d : -f 1`
	seq_outfile=$seq_outdir/"$corename-$seq_name.pep.fas"
	ruby $get_subseq -i $seq_infile --seq $seq_name > $seq_outfile
	blast_output=$blast_outdir/"$corename-$seq_name.blast8"
	blastp -query $seq_outfile -db $blast_db -out $blast_output -outfmt 6 -evalue 1e-10 -num_threads 2
done < $infile


