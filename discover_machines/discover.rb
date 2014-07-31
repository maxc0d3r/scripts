#!/usr/bin/env ruby

require 'fog'
require 'optparse'
require 'google_drive'
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


def get_servers(environment)
  server_details = Array.new()
  $filters['tag:Environment'] = ["#{environment}"]
  servers = $conn.servers.all($filters)
  ipaddress = Array.new
  servers.each do |server|
    server_details  << { "name" => "#{server.tags["Name"]}.#{server.tags["Environment"]}.indix.tv", "cluster" => "#{server.tags["Cluster"]}" }
  end
  server_details
end

def populate_spreadsheet
  session = GoogleDrive.login(@username,@password)
  spreadsheetName="DNS"
  worksheetNames=["production","production-mr","staging","staging-mr","ft","uat","all"]
  instance_variable_names=["production","production_mr","staging","staging_mr","ft","uat","all"]
  spreadsheetHandle = session.spreadsheet_by_title("#{spreadsheetName.strip}")

  if spreadsheetHandle.nil?
    spreadsheetHandle = session.create_spreadsheet(title="#{spreadsheetName.strip}")
    worksheetNames.each_with_index do |ws,index|
      instance_variable_set("@#{instance_variable_names[index]}", spreadsheetHandle.add_worksheet(ws))
    end
  else
    worksheetNames.each_with_index do |ws,index|
      if spreadsheetHandle.worksheet_by_title(ws).nil?
        instance_variable_set("@#{instance_variable_names[index]}",spreadsheetHandle.add_worksheet(ws))
      else
        spreadsheetHandle.worksheet_by_title(ws).delete
        instance_variable_set("@#{instance_variable_names[index]}",spreadsheetHandle.add_worksheet(ws))
      end
    end
  end

  schema = ["DNS","Cluster"]
  worksheetNames.each_with_index do |ws_name,index|
    ws = instance_variable_get("@#{instance_variable_names[index]}")
    i=1
    schema.each do |column_name|
      ws[1,i] = column_name
      i=i+1
    end
  end

  worksheetNames.each_with_index do |ws_name,index|
    ws = instance_variable_get("@#{instance_variable_names[index]}")
    i=2
    get_servers(ws_name).each do |server_details|
      ws[i,1] = server_details["name"]
      ws[i,2] = server_details["cluster"]
      i=i+1
    end
    ws.save
  end
end

populate_spreadsheet
