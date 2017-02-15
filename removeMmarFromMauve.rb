#! /bin/env ruby


require 'getoptlong'


############################################################
infile = nil
gene_prefixes_excluded = Array.new


############################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--gene_prefixes_excluded', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--gene_prefixes_excluded'
      gene_prefixes_excluded << value.split(',')
  end
end


gene_prefixes_excluded.flatten!


############################################################
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  line_arr = line.split("\t")
  items = Array.new
  line_arr.each do |i|
    is_pass = true
    i_arr = i.split(':')
    if ! gene_prefixes_excluded.empty?
      gene_prefixes_excluded.each do |prefix|
        is_pass = false and break if i_arr[1] =~ /^#{prefix}/
      end
    end
    items << i if is_pass
  end
  puts items.join("\t") if ! items.empty?
end

in_fh.close


