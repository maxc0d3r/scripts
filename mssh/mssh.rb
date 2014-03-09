#!/usr/bin/env ruby

require 'fog'
require 'optparse'
require 'net/ssh/multi'
require_relative 'config.rb'

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
  opts.on("-f", "--filter FILTER","Comma separated filters") do |filter|
    options[:filter] = filter
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

puts $filters

def get_servers()
  servers = $conn.servers.all($filters)
  ipaddress = Array.new
  servers.each do |server|
    ipaddress << server.private_ip_address
  end
  return ipaddress
end

Net::SSH::Multi.start(:on_error => :ignore) do |session|
  get_servers().each do |ip|
    session.use "#{ip}", :user => "#{@ssh_user}", :keys => ["#{@ssh_key}"]
  end
  session.open_channel do |ch|  
    ch.request_pty do |c,success|
      raise "Could not request pty" unless success
      ch.exec "#{command}"
      ch.on_data do |ch,data|
        puts "[#{ch[:host]} :] #{data}"
      end
    end
  end
  session.loop
end

