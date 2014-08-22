lock '3.2.1'

$:.unshift File.expand_path('../../../../lib', __FILE__) # in your Capfile, this would likely be "require 'rubygems'"
require 'supply_drop'

set :puppet_command, "puppet"
