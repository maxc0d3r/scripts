#!/usr/bin/env ruby

require 'fog'
require 'optparse'
require 'net/ssh/multi'
require './fog_config.rb'

$conn = Fog::Compute.new(
          :provider => 'AWS',
          :aws_access_key_id => @aws_access_key_id,
          :aws_secret_access_key => @aws_secret_access_key
        )

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: mssh [options]"
  opts.on("-c", "--command COMMAND","Command to run on remote hosts") do |command|
    options[:command] = command
  end
  opts.on("-f", "--filter FILTER","Filter") do |filter|
    options[:filter] = filter
  end
  opts.on("-h", "--help", "Display this screen") do
    puts opts
    exit
  end
end

optparse.parse!

command = options[:command]
filter_criteria = options[:filter].split(":")[0]
filter_value = options[:filter].split(":")[1]

def get_servers(criteria,value)
  servers = $conn.servers.all("tag:#{criteria}" => "#{value}")
  ipaddress = Array.new
  servers.each do |server|
    ipaddress << server.private_ip_address
  end
  return ipaddress
end

Net::SSH::Multi.start(:on_error => :ignore) do |ssh|
  get_servers(filter_criteria,filter_value).each do |ip|
    ssh.use "#{ip}", :user => "#{@ssh_user}", :keys => ["#{@ssh_key}"]
  end
  
  ssh.exec "#{command}"
  ssh.loop
end

