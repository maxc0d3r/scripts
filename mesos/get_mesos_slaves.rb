#!/usr/bin/env ruby

require 'open-uri'
require 'json'

url = 'http://<FQDN_OF_MESOS_MASTER>:<PORT_OF_MESOS_MASTER>/master/state.json'

slaves = JSON.parse(open(url).read)["slaves"]
slaves.each do |slave|
  puts slave["hostname"] + ": " + slave["pid"].split('@')[1].split(':')[0]
end
