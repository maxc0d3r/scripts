#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'optparse'
require 'net/ssh/multi'
require_relative 'config.rb'

options = {}

optparse = OptionParser.new do |opts|
	opts.banner = "Usage: check_jt.rb [options]"
 	opts.on("-u", "--url URL", "URL of ") do |url|
 		options[:url] = url
 	end
	opts.on("-w", "--warningnumtts WARNINGNUMTTS", "Warning Limit for number of TTs") do |warningtts|
		options[:warningtts] = warningtts
	end
	opts.on("-c", "--criticaltts CRITICALTTS", "Critical Limit for number of TTs") do |criticaltts|
		options[:criticaltts] = criticaltts
	end
	opts.on("-H", "--help", "Display this screen") do
    puts opts
    exit
  end
end

optparse.parse!

url_active_tts = "http://" + options[:url] + "/machines.jsp?type=active"
url_black_listed_tts = "http://" + options[:url] + "/machines.jsp?type=blacklisted"
warningtts = options[:warningtts]
criticaltts = options[:criticaltts]

page = Nokogiri::HTML(open("#{url_active_tts}"))
count_of_active_tts = 0
active_tts = Array.new
page.css('table.datatable tr td[2]').each do |el|
   active_tts << el.text
   count_of_active_tts+=1
end

page = Nokogiri::HTML(open("#{url_black_listed_tts}"))
count_of_blacklisted_tts = 0
black_listed_tts = Array.new
page.css('table.datatable tr td[2]').each do |el|
  black_listed_tts << el.text
  count_of_blacklisted_tts+=1
end

msg = "Ok: There are #{count_of_active_tts} tasktrackers"
returnval=0

if count_of_blacklisted_tts > 0
  puts "Warning: There are #{count_of_blacklisted_tts} black listed tasktrackers. #{black_listed_tts}. Trying to get them back online | blacklisted_tts=#{count_of_blacklisted_tts}"
  Net::SSH::Multi.start(:on_error => :ignore) do |session|
    black_listed_tts.each do |server|
      session.use "#{server}", :user => "#{@ssh_user}", :keys => ["#{@ssh_key}"]
    end
    session.open_channel do |ch|
      ch.request_pty do |c,success|
        raise "Could not request pty" unless success
        ch.exec "#{@command}"
        ch.on_data do |ch,data|
          puts "[#{ch[:host]} :] #{data}"
        end
      end
    end
    session.loop
    exit 2
  end
end

if count_of_active_tts < warningtts.to_i
  msg = "Warning: There are only #{count_of_active_tts} tasktrackers available, while you needed #{warningtts}"
  returnval=1
end

if count_of_active_tts < criticaltts.to_i
  msg = "Critical: There are only #{count_of_active_tts} tasktrackers available, while you needed #{criticaltts}"
  returnval=2
end

puts "#{msg}. #{active_tts} | numtts=#{count_of_active_tts}"
exit returnval
