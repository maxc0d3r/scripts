#!/usr/bin/env ruby

require 'bundler/setup'

require 'google_drive'
require 'fog'
require_relative 'config.rb'
session = GoogleDrive.login(@username,@password)

$state = { 0 => "unprovisioned", 1 => "running", 2 => "stopped", 3 => "terminated", 4 => "unreachable", 5 => "rebooting" }

$connection = Fog::Compute.new(
	:provider => 'AWS',
	:aws_access_key_id => @aws_access_key_id,
	:aws_secret_access_key => @aws_secret_access_key )
  
$cw_conn = Fog::AWS::CloudWatch.new(:aws_access_key_id => @aws_access_key_id, :aws_secret_access_key => @aws_secret_access_key)

def cpu_utilization(instance_id)
  metric_options = {
    'Namespace' => 'AWS/EC2',
    'MetricName' => 'CPUUtilization',
    'Period' => 604800,
    'EndTime' => Time.now.to_datetime,
    'StartTime' => (Time.now.to_time - 604800).to_datetime,
    'Statistics' => ['Maximum','Average'],
    'Dimensions' => [ { 'Name' => 'InstanceId', 'Value' => instance_id } ]
  }
  result = $cw_conn.get_metric_statistics(metric_options).body['GetMetricStatisticsResult']['Datapoints']
  if result.length == 0
    return Array[{"Maximum" => 0, "Average" => 0}]
  end
  return result
end


print "Enter name of Spreadsheet to read/write: "
spreadsheetName=gets
spreadsheetHandle = session.spreadsheet_by_title("#{spreadsheetName.strip}")
ws = nil
if spreadsheetHandle.nil?
  spreadsheetHandle = session.create_spreadsheet(title="#{spreadsheetName.strip}")
  ws = spreadsheetHandle.add_worksheet("#{Date.today.to_s}")
else
  if spreadsheetHandle.worksheet_by_title("#{Date.today.to_s}").nil?
    ws = spreadsheetHandle.add_worksheet("#{Date.today.to_s}")
  else
    spreadsheetHandle.worksheet_by_title("#{Date.today.to_s}").delete
    ws = spreadsheetHandle.add_worksheet("#{Date.today.to_s}")
  end
end

schema = ["ID","Name","Role","Environment","Cluster","Flavor","Private IP","Public IP","AZ","Type","State","Average CPU Utilization"]
i=1
schema.each do |column_name|
  ws[1,i] = column_name
  i=i+1
end

instance_list = $connection.servers.all()
instance_list_spot = $connection.servers.all('instance-lifecycle' => 'spot')
instance_list_ondemand = instance_list - instance_list_spot
puts "Total number of On-Demand instances = #{instance_list_ondemand.length}"
puts "Total number of Spot instances = #{instance_list_spot.length}"

i=2
print "Adding instances to spreadsheet, #{spreadsheetName} ..."
instance_list_ondemand.each do |instance|
  cpuUtilization = cpu_utilization(instance.id)
  ws[i,1] = instance.id
  ws[i,2] = instance.tags["Name"]
  ws[i,3] = instance.tags["Role"]
  ws[i,4] = instance.tags["Environment"]
  ws[i,5] = instance.tags["Cluster"]
  ws[i,6] = instance.flavor_id
  ws[i,7] = instance.private_ip_address
  ws[i,8] = instance.public_ip_address
  ws[i,9] = instance.availability_zone
  ws[i,10] = "On-Demand"
  ws[i,11] = $state.key(instance.state)
  ws[i,12] = cpuUtilization[0]["Average"]
  print "."
  ws.save
  i=i+1
end

instance_list_spot.each do |instance|
  cpuUtilization = cpu_utilization(instance.id)
  ws[i,1] = instance.id
  ws[i,2] = instance.tags["Name"]
  ws[i,3] = instance.tags["Role"]
  ws[i,4] = instance.tags["Environment"]
  ws[i,5] = instance.tags["Cluster"]
  ws[i,6] = instance.flavor_id
  ws[i,7] = instance.private_ip_address
  ws[i,8] = instance.public_ip_address
  ws[i,9] = instance.availability_zone
  ws[i,10] = "Spot"
  ws[i,11] = $state.key(instance.state)
  ws[i,12] = cpuUtilization[0]["Average"]
  print "."
  ws.save
  i=i+1
end
