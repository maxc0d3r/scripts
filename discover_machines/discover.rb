#!/usr/bin/env ruby

require 'fog'
require 'optparse'
require_relative 'config.rb'

$conn = Fog::Compute.new(
          :provider => 'AWS',
          :aws_access_key_id => @aws_access_key_id,
          :aws_secret_access_key => @aws_secret_access_key
        )

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: discover [options]"
  opts.on("-f", "--filter FILTER","Comma separated filters") do |filter|
    options[:filter] = filter
  end
  opts.on("-l", "--list", "List of all available filters") do
    puts "Cluster:[dynamo-app|services|dip-hdfs|crawlers-hdfs|analytics-hdfs|dip-mr|crawlers-mr|analytics-mr|proxy|memstore|solr|website|blog|monitoring|splunk|goserver]"
    exit
  end
  opts.on("-h", "--help", "Display this screen") do
    puts opts
    exit
  end
end

optparse.parse!

command = options[:command]
filter_criterias = options[:filter]
$filters=filter_criterias.split(',').inject(Hash.new{|h,k|h[k]=[]}) do |h,s|
  v,k=s.split(':')
  h["tag:#{v}"] << k
  h
end


def get_servers()
  server_details = Array.new()
  servers = $conn.servers.all($filters)
  ipaddress = Array.new
  servers.each do |server|
    server_details  << "#{server.tags["Name"]}.#{server.tags["Environment"]}.indix.tv"
  end
  puts server_details
end

get_servers
