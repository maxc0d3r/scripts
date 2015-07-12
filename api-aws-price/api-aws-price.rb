#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'json'

url = "http://www.ec2instances.info"
page = Nokogiri::HTML(open(url))

p ARGV[0]
machine_type_costs = page.search("//tr[starts-with(@id, ARGV[0])]")
machine_type_cost_region = JSON.parse(machine_type_costs.css('td.cost.cost-linux').attr('data-pricing').value)[ARGV[1]]
puts machine_type_cost_region

