# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require File.expand_path('../lib/ruby_caldav/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "ruby_caldav"
  s.version     = RubyCaldav::VERSION
  s.summary     = "Ruby CalDAV client"
  s.description = "yet another great Ruby client for CalDAV calendar."

  s.required_ruby_version     = '>= 1.9.2'

  s.license     = 'MIT'

  s.homepage    = %q{https://github.com/digitpro/ruby_caldav}
  s.authors     = [%q{Digitpro agilastic}]
  s.email       = [%q{}]
  s.add_runtime_dependency 'ri_cal'
  s.add_runtime_dependency 'builder'
  s.add_runtime_dependency 'net-http-digest_auth'
  s.add_runtime_dependency 'oga', '~> 1.3'



  s.description = <<-DESC
  ruby_caldav is yet another great Ruby client for CalDAV calendar.  It is based on the icalendar gem.
DESC
  s.post_install_message = <<-POSTINSTALL
POSTINSTALL


  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
end
