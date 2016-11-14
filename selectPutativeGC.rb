#! /bin/env ruby


require "getoptlong"
require "bio"


##################################################################
infile = nil
prefixes = Array.new

prefix_counts = Hash.new{|h,k|h[k]=[]}


##################################################################
opts = GetoptLong.new(
  ["-i", GetoptLong::REQUIRED_ARGUMENT],
  ["--prefix", GetoptLong::REQUIRED_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when "-i"
      infile = value
    when "--prefix"
      prefixes << value.split(',')
  end
end

prefixes.flatten!


#################################################################
seq_count = 0
Bio::FlatFile.open(infile).each_entry do |f|
  seq_count += 1
  prefixes.each_with_index do |prefix, index|
    if f.definition =~ /#{prefix}/i
      prefix_counts[prefix] << seq_count
    end
  end
end

total_num_of_seqs = prefix_counts.values.flatten.size


prefix_counts.each_pair do |prefix, arr|
  if arr.map{|i|i<=total_num_of_seqs/2}.all?{|i|i==true}
    puts infile
    break
  end
end


