#! /bin/env ruby


require "getoptlong"
require "bio"


###########################################################
infile = nil
seq_files = Array.new
pattern = nil
prefixes = Array.new
outdir = nil
is_force = false

clstrs = Array.new
seq_objs = Hash.new


###########################################################
def read_seq(seq_file, prefix)
  seq_objs = Hash.new
  Bio::FlatFile.open(seq_file).each_entry do |f|
    seq_name = [prefix, f.definition].join('|')
    seq_objs[seq_name] = f
  end
  return(seq_objs)
end


def read_mclOutput(infile)
  clstrs = Array.new
  File.open(infile, 'r').each_line do |line|
    line.chomp!
    line_arr = line.split("\t")
    clstrs << line_arr
  end
  return(clstrs)
end


###########################################################
opts = GetoptLong.new(
  ["-i", GetoptLong::REQUIRED_ARGUMENT],
  ["--seq", GetoptLong::REQUIRED_ARGUMENT],
  ["--pattern", GetoptLong::REQUIRED_ARGUMENT],
  ["--prefix", GetoptLong::REQUIRED_ARGUMENT],
  ["--outdir", GetoptLong::REQUIRED_ARGUMENT],
  ["--force", GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when "-i"
      infile = value
    when "--seq"
      seq_files << value.split(',')
    when "--pattern"
      pattern = value
    when "--prefix"
      prefixes << value.split(',')
    when "--outdir"
      outdir = value
    when "--force"
      is_force = true
  end
end


seq_files.flatten!
prefixes.flatten!

if outdir.nil?
  puts "outdir has to be specified! Exiting ......"
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


###########################################################
seq_files.each_with_index do |seq_file, index|
  prefix = prefixes[index]
  seq_objs = seq_objs.merge(read_seq(seq_file, prefix))
end

clstrs = read_mclOutput(infile)


###########################################################
clstrs.each_with_index do |clstr, index|
  if clstr.size == 4
    outfile = File.join(outdir, index.to_s+'.fas')
    out_fh = File.open(outfile, 'w')
    clstr.each do |gene|
      out_fh.puts ">" + gene
      out_fh.puts seq_objs[gene].seq
    end
    out_fh.close
  end
end


