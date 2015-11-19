require_relative 'lib/ruby_caldav'
client = RubyCaldav::Client.new(:uri => "http://localhost:5232/aaa/", :user => "" , :password => "")
events = client.find_events(["/aaa/98baca40-4234-de45-b3e3-f88a29adf235.ics", "/aaa/8DBBD94D-056F-451C-BAD6-83E51D5FFDAB.ics"])
p events