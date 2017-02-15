#! /bin/env ruby


require "getoptlong"


##########################################################################
infile = nil
mauve_file = nil

pairs = Hash.new


##########################################################################
def read_mauve(mauve_file)
  mauve_rela = Hash.new
  File.open(mauve_file, 'r').each_line do |line|
    #0:SACI_RS03420:575816-576373	2:STK_RS01680:318927-319484
    line.chomp!
    line_arr = line.split("\t")
    genes = line_arr.map{|item|item.split(':')[1]}
    line_arr.each do |item|
      item_arr = item.split(':')
      gene = item_arr[1]
      mauve_rela[gene] = genes.select{|i|i if i != gene}
    end
  end
  return(mauve_rela)
end


def read_infile(infile)
  pairs = Hash.new
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    genes = line.split("\t").sort
    pairs[genes] = nil
  end
  return(pairs)
end


##########################################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--mauve', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--mauve'
      mauve_file = value
  end
end


##########################################################################
pairs = read_infile(infile)

mauve_rela = read_mauve(mauve_file)

pairs.each_key do |genes|
  arr1 = mauve_rela[genes[0]]
  arr2 = mauve_rela[genes[1]]
  if not arr1.empty? and not arr2.empty?
    puts genes.join("\t")
  end
end



