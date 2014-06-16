#!/usr/bin/env ruby
require 'erb'
require 'zookeeper'
require 'json'

@hostname = `hostname -f`
collection_host_mapping = Hash.new
@current_meta = ""
@current_search = ""

quorum = ENV["QUORUM"]
zk = Zookeeper.new(quorum)
res = JSON.parse(zk.get(:path => "/clusterstate.json")[:data])
res.each do |collection_name,stats|
  res["#{collection_name}"]["shards"].each do |key,value|
    value["replicas"].each do |key,value| 
      collection_host_mapping[value["core"]] = value["node_name"].split(':')[0] 
    end
  end
end
collection_host_mapping.each do |key,value|
  if value.to_s.strip == hostname.to_s.strip
    if key.include?("meta")
      @current_meta = key
    else
      @current_search = key
    end
  end
end

template = open("/etc/jmxtrans/solr.json.erb", 'r') {|f| f.read}
output = ERB.new(template).result()
File.open("/var/lib/jmxtrans/solr.json", 'w') {|f| f.write (output) }
`/etc/init.d/jmxtrans restart`
