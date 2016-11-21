#! /bin/env ruby


require 'getoptlong'
require 'bio'


#############################################################
tree_file = nil
otus = Array.new
joiner = "\n"

sub_family_nodes = Array.new


#############################################################
opts = GetoptLong.new(
  ['--tree', GetoptLong::REQUIRED_ARGUMENT],
  ['--otu', GetoptLong::REQUIRED_ARGUMENT],
  ['--joiner', GetoptLong::REQUIRED_ARGUMENT],
)


opts.each do |opt, value|
  case opt
    when '--tree'
      tree_file = value
    when '--otu', '--OTU'
      otus << value.split(',')
    when '--joiner'
      joiner = value
  end
end


otus.flatten!


#############################################################
treeio = Bio::FlatFile.open(Bio::Newick, tree_file)
tree = treeio.next_entry.tree
tree.nodes.map{|node|node.name.gsub!(' ', '_') if node.name =~ /\w/}

otu_nodes = otus.map{|otu|tree.get_node_by_name(otu);}
tree.root
lowest_node = tree.lowest_common_ancestor(otu_nodes[0], otu_nodes[1])
tree.descendents(lowest_node).each do |node|
  sub_family_nodes << node if node.name =~ /\w/
end

puts sub_family_nodes.map{|i|i.name}.join(joiner)


