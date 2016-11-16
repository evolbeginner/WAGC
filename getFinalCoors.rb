#! /bin/env ruby


require "bio"
require "getoptlong"


##############################################################
infile = nil
lnL_min = nil

final_coors = Hash.new


##############################################################
opts = GetoptLong.new(
  ["-i", GetoptLong::REQUIRED_ARGUMENT],
  ["--lnL_min", GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when "-i"
      infile = value
    when "--lnL_min"
      lnL_min = value.to_f
  end
end


##############################################################
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  line.chomp!
  line_arr = line.split("\t")
  lnL = line_arr[0].to_f
  if lnL > lnL_min
    final_coors[$.] = lnL
  end
end


puts final_coors.keys.join(",")


