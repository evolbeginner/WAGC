#! /bin/env ruby


require 'getoptlong'


###################################################################
infile = nil
gff_file = nil
features = Array.new
attr = 'ID'
genome_length = nil

gene_info = Hash.new


###################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--gff', GetoptLong::REQUIRED_ARGUMENT],
  ['--feature', GetoptLong::REQUIRED_ARGUMENT],
  ['--attr', GetoptLong::REQUIRED_ARGUMENT],
  ['--genome_length', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--gff'
      gff_file = value
    when '--feature'
      features = value.split(',')
    when '--attr'
      attr = value
    when '--genome_length'
      genome_length = value.to_i
  end
end


###################################################################
def read_gff(gff_file, features, attr)
  gene_info = Hash.new{|h,k|h[k]={}}
  genome_length = nil
  in_fh = File.open(gff_file, 'r')
  in_fh.each_line do |line|
    #NC_003552	genbank	gene	266	1510	1	-	.	ID=MA_RS00005
    line.chomp!
    line_arr = line.split("\t")
    chr, feature, start, stop, strand, attr_str = line_arr.values_at(0,2,3,4,6,-1)
    start, stop = start.to_i, stop.to_i
    if feature == 'source'
      genome_length = stop - start + 1
    end
    next if not features.include?(feature)
    if attr_str =~ /#{attr}=([^;]+)/
      gene = $1
      gene_info[gene]['start'] = start
      gene_info[gene]['stop'] = stop
      gene_info[gene]['strand'] = strand
    end
  end
  in_fh.close
  return([gene_info, genome_length])
end


def read_pair(pair_file)
  pairs = Hash.new
  in_fh = File.open(pair_file, 'r')
  in_fh.each_line do |line|
    line.chomp!
    line_arr = line.split("\t")
    genes = line_arr[0,2]
    pairs[genes] = nil
  end
  in_fh.close
  return(pairs)
end


###################################################################
gene_info, genome_length_from_gff = read_gff(gff_file, features, attr)
if genome_length.nil?
  genome_length = genome_length_from_gff
end

pairs = read_pair(infile)

pairs.each_key do |genes|
  distance1 = (gene_info[genes[0]]['start'] - gene_info[genes[1]]['start']).abs
  distance2 = genome_length - distance1
  distance = [distance1, distance2].min
  p distance
end


