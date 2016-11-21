#! /bin/env ruby


require 'getoptlong'
require 'Dir'


##########################################################
infile = nil
evalue_cutoff = 1e-10
geneconv_file = nil
outdir = nil
is_force = false

domain_info = Hash.new{|h,k|h[k]=[]}
gc_info = Hash.new{|h,k|h[k]=[]}


##########################################################
opts = GetoptLong.new(
  ['-i', GetoptLong::REQUIRED_ARGUMENT],
  ['-e', GetoptLong::REQUIRED_ARGUMENT],
  ['--geneconv', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '-i'
      infile = value
    when '-e'
      evalue_cutoff = value.to_f
    when '--geneconv'
      geneconv_file = value
    when '--outdir'
      outdir = value
    when '--force'
      is_force = true
  end
end


mkdir_with_force(outdir, is_force)
gc_bed_file = File.join(outdir, "gc.bed")
domain_bed_file = File.join(outdir, "domain.bed")


##########################################################
class GC_REGION
  attr_accessor :domain, :prot_start, :prot_stop
end


##########################################################
def parse_hmmsearch_result(infile, evalue_cutoff)
  domain_info = Hash.new{|h,k|h[k]=[]}
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    # target name        accession   tlen query name           accession   qlen   E-value  score  bias   #  of  c-Evalue  i-Evalue  score  bias  from    to  from    to  from    to  acc description of target
    #AHOS_RS10920         -            215 1-cysPrx_C           PF10417.4     40   4.2e-11   39.7   0.2   1   1   8.2e-14   9.6e-11   38.5   0.1     1    37   155   191   155   193 0.93 -
    next if line =~ /^#/
    line.chomp!
    line_arr = line.split(/\s+/)
    prot, domain = line_arr.values_at(0, 4)
    evalue, prot_start, prot_stop = line_arr.values_at(6,-6,-5).map{|i|i.to_f}
    prot_start, prot_stop = prot_start.to_i, prot_stop.to_i
    next if evalue > evalue_cutoff
    obj = GC_REGION.new
    obj.domain = domain
    obj.prot_start = prot_start
    obj.prot_stop = prot_stop
    domain_info[prot] << obj
  end
  in_fh.close
  return(domain_info)
end


def read_geneconv_file(geneconv_file)
  gc_info = Hash.new{|h,k|h[k]=[]}
  File.open(geneconv_file, 'r').each_line do |line|
    #geneconv/8_4/72.frags	sso|SSO_RS02265	sso|SSO_RS04415	SACI_RS02185,STK_RS00920,SIL_RS07725,MCUP_RS00565,MSED_RS11150,AHOS_RS05045	SACI_RS06775,STK_RS06840,SIL_RS05965,MCUP_RS02720,MSED_RS08640,AHOS_RS07035	0.0	3.0e-05	724.0	788.0	65.0
    line.chomp!
    line_arr = line.split("\t")
    prot_full_name = line_arr[1]
    prot = prot_full_name.split('|')[1]
    prot_start, prot_stop = line_arr.values_at(-3,-2).map{|i|i.to_i}
    obj = GC_REGION.new
    obj.prot_start = prot_start
    obj.prot_stop = prot_stop
    gc_info[prot] << obj
  end
  return(gc_info)
end


def output_bed(info, outfile)
  out_fh = File.open(outfile, 'w')
  info.each_pair do |prot, arr|
    arr.each do |obj|
      out_fh.puts [prot, obj.prot_start, obj.prot_stop].map{|i|i.to_s}.join("\t")
    end
  end
  out_fh.close
end


##########################################################
domain_info = parse_hmmsearch_result(infile, evalue_cutoff)

if ! geneconv_file.nil?
  gc_info = read_geneconv_file(geneconv_file)
end


##########################################################
output_bed(gc_info, gc_bed_file)
output_bed(domain_info, domain_bed_file)


