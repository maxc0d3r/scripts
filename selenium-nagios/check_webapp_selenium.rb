#!/usr/bin/env ruby

#Needed these to allow for Zenoss to pickup gems
ENV['GEM_HOME']="/usr/local/rvm/gems/ruby-1.9.3-p448"
ENV['GEM_PATH']="/usr/local/rvm/gems/ruby-1.9.3-p448"

#Since I'm running this on EC2, hence using Xvfb as a virtual screen
ENV['DISPLAY']=':1'

require 'selenium-webdriver'

driver = Selenium::WebDriver.for :firefox
login_url = "<OUR_LOGIN_URL>"
to_test_url = "<POST_LOGIN_APP_URL>"
subject_maintenance = "App Issue - Scheduled Maintenance underway"
subject_alert = "App Issue - App is down !"

msg = "All is well !"
retval = 0

begin
  driver.navigate.to login_url
  driver.manage.timeouts.implicit_wait = 20
rescue
  driver.quit
  puts "Error loading #{login_url}"
  exit 5
end

if driver.title.include?("Maintenance")
  driver.quit
  puts "Maintenance underway"
  exit 2
end

sleep 1
begin
  driver.find_element(:name,'email').send_keys "foo@bar.com"
  sleep 1
  driver.find_element(:name,'password').send_keys "xxxxxxxx"
  sleep 1
rescue
  driver.quit
  puts "Cannot find form fields for login at #{login_url}"
  exit 5
end

begin
  login_result = driver.find_element(:link, "Login").click
  sleep 10
  if login_result != "ok"
    driver.quit
    puts "Error while trying to login to app"
    exit 5
  end
rescue
  driver.quit
  puts 'Error redirecting to abc.foobar.com post login'
  exit 5
end

begin
  driver.navigate.to store_url
  driver.manage.timeouts.implicit_wait = 20
rescue
  driver.quit
  msg = "Error loading #{to_test_url}"
  exit 5
end

product_count = driver.find_element(:css,"div#products-count div.data div.value").text
if product_count == " " || product_count.nil? || product_count == "0"
  msg = "URL: #{to_test_url}. No products being returned in tile !"
  retval = 5
end

begin 
  graph = driver.find_element(:css,"svg")
rescue
  if graph.nil?
    msg = msg + " No graphs !"
    retval = 5
  end
end

driver.close
driver.quit
puts "#{msg}|product_count=#{product_count}"
exit retval
