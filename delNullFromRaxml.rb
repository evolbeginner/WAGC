#! /bin/env ruby


require "getoptlong"


############################################################
lnL_file = nil
gc_range_file = nil
max_lnL_file = nil
max_num_of_failed = nil
is_all_site = false

lnLs = Hash.new
gc_sites = Hash.new


############################################################
def read_lnL_file(lnL_file)
  lnLs = Hash.new
  File.open(lnL_file, 'r').each_line do |line|
    line.chomp!
    next if line !~ /\w/
    lnLs[$.] = line.to_f
  end
  return(lnLs)
end


def read_range_file(range_file, is_all_site)
  gc_sites = Hash.new
  pair = nil
  File.open(range_file, 'r').each_line do |line|
    #Mace|MA_RS08395	Mace|MA_RS22960
    #112-114	112,113,114	112,114
    #130-137	130,131,132,133,134,137	130,131,132,133,134
    line.chomp!
    line_arr = line.split("\t")
    if is_all_site
      if ($. % 2 == 1)
        pair = line
      else
        line_arr.map{|i|i.to_i}.each do |site|
          gc_sites[site] = nil
        end
      end
    else
      if line_arr.size == 2
        pair = line
      else
        range = line_arr[0]
        sites = range.split('-')[0]..range.split('-')[1]
        sites.each do |site|
          gc_sites[site.to_i] = nil
        end
      end
    end
  end
  return(gc_sites)
end


############################################################
opts = GetoptLong.new(
  ['--lnL_file', GetoptLong::REQUIRED_ARGUMENT],
  ['--gc_range_file', GetoptLong::REQUIRED_ARGUMENT],
  ['--max_lnL_file', GetoptLong::REQUIRED_ARGUMENT],
  ['--max_num_of_failed', GetoptLong::REQUIRED_ARGUMENT],
  ['--all_site', GetoptLong::NO_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when '--lnL_file'
      lnL_file = value
    when '--gc_range_file'
      gc_range_file = value
    when '--max_lnL_file'
      max_lnL_file = value
    when '--max_num_of_failed'
      max_num_of_failed = value.to_i
    when '--all_site'
      is_all_site = true
  end
end


############################################################
lnLs = read_lnL_file(lnL_file)

gc_sites = read_range_file(gc_range_file, is_all_site)

max_lnLs = read_lnL_file(max_lnL_file) if not max_lnL_file.nil?


gc_sites.keys.each do |gc_site|
  next if not lnLs.include?(gc_site)
  is_pass = true
  if not max_lnL_file.nil?
    is_pass = false
    num_of_failed = max_lnLs.values.select{|max_lnL| lnLs[gc_site] <= max_lnL}.size
    if num_of_failed <= max_num_of_failed
      is_pass = true
    end
  end
  puts gc_site if is_pass
end


