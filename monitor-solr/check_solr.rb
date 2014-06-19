#!/usr/bin/env ruby

require 'zookeeper'

quorum = QUORUM
expected_nodes = EXPECTED_NODES

zk = Zookeeper.new(quorum)
live_nodes = zk.get_children(:path => "/live_nodes")[:children].map { |x| x.split(":")[0] }
count = live_nodes.length
if count < expected_nodes.length
  puts "Number of live solr nodes = #{count}|count=#{count}"
  unavailable_nodes = expected_nodes - live_nodes
  puts "Unavailable Nodes = "
  unavailable_nodes.each do |node|
    puts node
  end
  exit 5
end
puts "All is well ! Number of live solr nodes = #{count}|count=#{count}"
