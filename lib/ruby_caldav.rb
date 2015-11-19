require 'net/https'
require 'net/http/digest_auth'
require 'uuid'
require 'rexml/document'
require 'rexml/xpath'
require 'ri_cal'
require 'time'
require 'date'

%w(client.rb request.rb net.rb filter.rb parser.rb).each do |f|
  require File.join(File.dirname(__FILE__), 'ruby_caldav', f)
end