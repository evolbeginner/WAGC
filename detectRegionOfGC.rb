#! /bin/env ruby2.1


require 'getoptlong'
require 'set'


######################################################
infile = nil
coors_included = Array.new
type = nil

region_info = Hash.new{|h,k|h[k]={}}


######################################################
def get_ranges(coordinates)
  ranges = Array.new
  passed_coors = Array.new
  selected_coors = Hash.new{|h,k|h[k]={}}
  coordinates.each do |coor|
    sorrounding_coors = [coor-3, coor-2, coor-1, coor+1, coor+2, coor+3]
    candidate_coors = sorrounding_coors.select{|i|i if coordinates.include?(i)}
    candidate_coors.each do |candidate_coor|
      selected_coors[coor][candidate_coor] = ""
    end
    is_pass = false
    if candidate_coors.size >= 3
      is_pass = true
    elsif not candidate_coors.empty?
      if (candidate_coors.include?(coor-1) and candidate_coors.include?(coor-2)) or (candidate_coors.include?(coor+1) and candidate_coors.include?(coor+2))
        is_pass = true
      end
    else
      is_pass = false
    end

    if is_pass
      passed_coors << coor
    end

  end

  #p coordinates
  if not passed_coors.empty?
    coordinates = coordinates.to_set
    coordinates_divided = coordinates.divide{|x,y|selected_coors[x].include?(y)}
    coordinates_divided.to_a.select{|sub_set|sub_set unless sub_set.select{|i|passed_coors.include?(i)}.empty?}.each do |sub_set|
      sub_set_arr = sub_set.to_a
      ranges << [[sub_set_arr.min.to_s+'-'+sub_set.max.to_s], sub_set_arr, sub_set_arr.select{|i|passed_coors.include?(i)}]
    end
  end
  return(ranges)
end


######################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['--coor', '--coors', '--coors_included', GetoptLong::REQUIRED_ARGUMENT],
  ['--type', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '--coor', '--coors', '--coors_included'
      coors_included = value.split(',').map{|i|i.to_i}
    when '--type'
      type = value
  end
end


######################################################
in_fh = File.open(infile, 'r')
in_fh.each_line do |line|
  #292/FastTree/149.FastTree.tre	sac|SACI_RS02185	sac|SACI_RS06775	STK_RS06840,SSO_RS04415,SIL_RS05965,MCUP_RS02720,MSED_RS08640,AHOS_RS07035	STK_RS00920,SSO_RS02265,SIL_RS07725,MCUP_RS00565,MSED_RS11150,AHOS_RS05045	0
  #292/FastTree/149.FastTree.tre	ado|AHOS_RS05045	ado|AHOS_RS07035	SACI_RS06775,STK_RS06840,SSO_RS04415,SIL_RS05965,MCUP_RS02720,MSED_RS08640	SACI_RS02185,STK_RS00920,SSO_RS02265,SIL_RS07725,MCUP_RS00565,MSED_RS11150	0
  #292/FastTree/139.FastTree.tre	sso|SSO_RS02265	sso|SSO_RS04415	SACI_RS06775,STK_RS06840,SIL_RS05965,MCUP_RS02720,MSED_RS08640,AHOS_RS07035	SACI_RS02185,STK_RS00920,SIL_RS07725,MCUP_RS00565,MSED_RS11150,AHOS_RS05045	0
  line.chomp!
  line_arr = line.split("\t")
  file, gene1, gene2, genes1, genes2 = line_arr[0,5]
  basename = File.basename(file)
  corename=case type
    when 'FastTree', 'fasttree'
      basename.sub(/\..+/, "")
    when 'raxml'
      basename.sub(/.+\./, "")
  end
  pair = [gene1, gene2].join("\t")
  if not coors_included.empty?
    next if not coors_included.include?(corename.to_i)
  end
  region_info[pair][corename.to_i] = [genes1, genes2]
end


region_info.sort.to_h.each_pair do |pair, v1|
  ranges = get_ranges(v1.sort.to_h.keys)
  if not ranges.empty?
    puts pair
    ranges.each do |range|
      puts [range[0], range[1].map{|i|i.to_s}.join(','), range[2].map{|i|i.to_s}.join(',')].join("\t")
    end
  end
end


