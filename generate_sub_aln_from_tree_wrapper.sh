#! /bin/bash


############################################################################################
midpoint_root=~/tools/self_bao_cun/phylo_mini/midpoint_root.R
get_subseq=~/tools/self_bao_cun/basic_process_mini/get_subseq.rb


############################################################################################
while [ $# -gt 0 ]; do
	case $1 in
		--num)
			num=$2
			shift
			;;
		--otu)
			otu=$2
			shift
			;;
	esac
	shift
done

out_aln=sub_aln/999${num}1.aln
if [ -f $out_aln ]; then
	echo "out_aln $out_aln already exists. Do you want to continue? [Y/N]"
	read -r -n1 c
	if [ $c == "Y" -o $c == "y" ]; then
		echo -n "" >/dev/null
	elif [ $c == "N" ]; then
		echo "Exiting ......"
		exit 1
	else
		echo "Exiting ......"
		exit 1
	fi
fi


############################################################################################
$midpoint_root FastTree/8_4/$num.FastTree.tre test/mp.tree;

ruby $get_subseq -i aln/8_4/combined/$num.aln --seq_name `ruby ../scripts/extractSubfamilyFromTree.rb --tree test/mp.tree --joiner , --otu $otu` > $out_aln


