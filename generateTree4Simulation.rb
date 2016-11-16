#! /bin/env ruby


require 'getoptlong'
require 'bio'


####################################################
tree_file = nil

counter = 0


####################################################
opts = GetoptLong.new(
  ['--tree', GetoptLong::REQUIRED_ARGUMENT],
)

opts.each do |opt, value|
  case opt
    when '--tree'
      tree_file = value
  end
end


####################################################
treeio = Bio::FlatFile.open(Bio::Newick, tree_file)
tree = treeio.next_entry.tree

tree.nodes.each do |node|
  if node.name =~ /\w/
    counter += 1
    node.name = counter.to_s
  end
end


output = tree.output_newick
output.gsub!(/[\n\s]/, '')
output.gsub!(/^[(]/, '')
output.gsub!(/[)];$/, ';')
puts output


