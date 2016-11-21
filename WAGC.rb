#! /bin/env ruby


require "getoptlong"
require "bio"
require "pathname"


#################################################################
RAxML_prog = File.expand_path("~/software/phylo/RAxML_8.2.4/raxmlHPC-PTHREADS")


#################################################################
infile = nil
outdir = nil
step = 5
subseq_length = 50
topo_file = nil
cpu = 2
is_force = false
is_raxml = true
is_FastTree = true
bootstrap = nil

seq_objs = Hash.new


#################################################################
def read_seq(infile)
  seq_objs = Hash.new
  Bio::FlatFile.open(infile).each_entry do |f|
    seq_objs[f.definition] = f
  end
  return(seq_objs)
end


def output_subseqs(seq_objs, step, subseq_length, outdir)
  start = 1
  counter = 0
  while start+subseq_length <= seq_objs[seq_objs.keys[0]].seq.size do
    counter += 1
    outfile = File.join([outdir, counter.to_s+".aln"])
    out_fh = File.open(outfile, 'w')
    seq_objs.each_pair do |gene, f|
      out_fh.puts ">#{gene}"
      out_fh.puts f.seq[start-1, subseq_length]
    end
    out_fh.close
    start += step
  end
end


def get_likelihood(infile)
  likelihood = nil
  File.open(infile, "r").each_line do |line|
    line.chomp!
    if line =~ /Final ML Optimization Likelihood: ([^ ]+)/ or line =~ /final GAMMA-based Likelihood: ([^ ]+)/ or line =~ /^LH after SPRs ([^ ]+)/
      likelihood = $1.to_f
    end
  end
  return(likelihood)
end


def run_raxml(infile, topo_file, aln_outdir, wholeMolecule_tree_outdir, subseq_tree_outdir, cpu=2, bootstrap=nil)
  obs_path_to_wholeMolecule_tree_outdir = Pathname.new(wholeMolecule_tree_outdir).realpath
  if bootstrap.nil?
    `#{RAxML_prog} -T #{cpu} -s #{infile} -m GTRGAMMA -f d -w #{obs_path_to_wholeMolecule_tree_outdir} -n wholeMolecule -p 123`
  else
    `#{RAxML_prog} -T #{cpu} -s #{infile} -m GTRGAMMA -f a -w #{obs_path_to_wholeMolecule_tree_outdir} -n wholeMolecule -p 123 -x 123 -N #{bootstrap}`
  end
  topo_file = File.join([obs_path_to_wholeMolecule_tree_outdir, "RAxML_bestTree.wholeMolecule"])

  aln_basenames = Array.new
  counter = 0
  total = `ls -1 #{aln_outdir}/*aln | wc -l`
  Dir.foreach(aln_outdir) do |aln|
    next if aln =~ /^\./
    aln_basenames << aln
  end

  likelihoods = Array.new
  aln_basenames.sort_by{|i|$1.to_i if i=~/([^.]+)/}.each do |aln|
    counter += 1
    puts "#{counter} out of #{total}"
    full_path_to_aln = File.join([aln_outdir, aln])
    corename = aln.sub(/\.aln$/, "")
    subseq_tree_outdir_per_aln_best = File.join([subseq_tree_outdir, corename, "best"])
    subseq_tree_outdir_per_aln_topo = File.join([subseq_tree_outdir, corename, "topo"])
    `mkdir -p #{subseq_tree_outdir_per_aln_best}`
    `mkdir -p #{subseq_tree_outdir_per_aln_topo}`
    obs_path_to_subseq_tree_outdir_per_aln = Pathname.new(subseq_tree_outdir_per_aln_best).realpath
    `#{RAxML_prog} -T #{cpu} -s #{full_path_to_aln} -m GTRGAMMA -f d -w #{obs_path_to_subseq_tree_outdir_per_aln}      -n #{corename} -p 123`
    likelihood_best = get_likelihood(File.join([obs_path_to_subseq_tree_outdir_per_aln, "RAxML_info."+corename]))
    obs_path_to_subseq_tree_outdir_per_aln_topo = Pathname.new(subseq_tree_outdir_per_aln_topo).realpath
    `#{RAxML_prog} -T #{cpu} -s #{full_path_to_aln} -m GTRGAMMA -f d -w #{obs_path_to_subseq_tree_outdir_per_aln_topo} -n #{corename} -p 123 -g #{topo_file}`
    likelihood_topo = get_likelihood(File.join([obs_path_to_subseq_tree_outdir_per_aln_topo, "RAxML_info."+corename]))
    likelihoods << [likelihood_best, likelihood_topo]
  end
  return(likelihoods)
end


def output_likelihoods(likelihoods, lnL_outfile)
  out_fh = File.open(lnL_outfile, 'w')
  likelihoods.each_with_index do |arr, index|
      likelihood_best, likelihood_topo = arr
      if likelihood_best.nil? or likelihood_topo.nil?
        out_fh.puts nil
      else
        likelihood_diff = likelihood_best-likelihood_topo
        likelihood_diff = likelihood_diff <= 0.1 ? 0.1 : likelihood_diff
        out_fh.puts [Math.log(likelihood_diff), likelihood_best, likelihood_topo].map{|i|i.to_s}.join("\t")
      end
  end
  out_fh.close
end


def run_FastTree(aln_outdir, fastTree_outdir)
  aln_basenames = Array.new
  counter=0
  Dir.foreach(aln_outdir) do |aln|
    next if aln =~ /^\./
    aln_basenames << aln
  end
  aln_basenames.sort_by{|i|$1.to_i if i=~/([^.]+)/}.each do |aln|
    counter += 1
    infile = File.join([aln_outdir, counter.to_s+'.aln'])
    outfile_basename = counter.to_s + ".FastTree.tre"
    outfile = File.join([fastTree_outdir, outfile_basename])
    `FastTree -nt -quiet <#{infile} >#{outfile}`
  end
end


#################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--step', GetoptLong::REQUIRED_ARGUMENT],
  ['--subseq_length', '-l', GetoptLong::REQUIRED_ARGUMENT],
  ['--topo', GetoptLong::REQUIRED_ARGUMENT],
  ['--cpu', '--CPU', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--no_raxml', GetoptLong::NO_ARGUMENT],
  ['--no_FastTree', GetoptLong::NO_ARGUMENT],
  ['--bootstrap', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--outdir'
      outdir = value
    when '--step'
      step = value.to_i
    when '-l', '--subseq_length'
      subseq_length = value.to_i
    when '--topo'
      topo_file = value
    when '--cpu', '--CPU'
      cpu = value.to_i
    when '--force'
      is_force = true
    when '--no_raxml'
      is_raxml = false
    when '--no_FastTree'
      is_FastTree = false
    when '--bootstrap'
      bootstrap = value.to_i
  end
end


if outdir.nil?
  puts 'outdir has to be specified! Exiting ......'
  puts
  exit
end
if Dir.exists?(outdir)
  if is_force
    `rm -rf #{outdir}`
    `mkdir -p #{outdir}`
  end
else
  `mkdir -p #{outdir}`
end


aln_outdir = File.join([outdir, "aln"])
fastTree_outdir = File.join([outdir, "FastTree"])
subseq_tree_outdir = File.join([outdir, "tree", "subseq"])
wholeMolecule_tree_outdir = File.join([outdir, "tree", "wholeMolecule_tree"])
`mkdir #{aln_outdir}`
`mkdir -p #{fastTree_outdir}`
`mkdir -p #{subseq_tree_outdir}`
`mkdir -p #{wholeMolecule_tree_outdir}`

lnL_outfile = File.join([outdir, "lnL"])


#################################################################
seq_objs = read_seq(infile)

output_subseqs(seq_objs, step, subseq_length, aln_outdir)

run_FastTree(aln_outdir, fastTree_outdir) if is_FastTree

if is_raxml
  likelihoods = run_raxml(infile, topo_file, aln_outdir, wholeMolecule_tree_outdir, subseq_tree_outdir, cpu, bootstrap)
  output_likelihoods(likelihoods, lnL_outfile)
end


