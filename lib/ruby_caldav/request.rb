require 'builder'

module RubyCaldav
  NAMESPACES = {"xmlns:d" => 'DAV:', "xmlns:c" => "urn:ietf:params:xml:ns:caldav", "xmlns:cs" => "http://calendarserver.org/ns/"}
  module Request
    class Base
      def initialize
        @xml = Builder::XmlMarkup.new(:indent => 2)
        @xml.instruct!
      end

      attr :xml
    end

    class Mkcalendar < Base
      attr_accessor :displayname, :description, :color

      def initialize(displayname = nil, description = nil, color = nil)
        super()
        @displayname = displayname
        @description = description
        @color = color
      end

      def to_xml
        xml.c :mkcalendar, NAMESPACES.merge({ "xmlns:x" =>"http://apple.com/ns/ical/"}) do
          xml.d :set do
            xml.d :prop do
              xml.d :displayname, displayname unless displayname.to_s.empty?
              xml.tag! "c:calendar-description", description, "xml:lang" => "en" unless description.to_s.empty?
              xml.x "x:calendar-color", color unless color.to_s.empty?
            end
          end
        end
      end
    end

    class PropPatch < Base
      attr_reader :props
      def initialize(props, custom_namespaces = {})
        super()
        @props = props
        @custom_namespaces = custom_namespaces
      end

      def to_xml
        xml.d :propertyupdate, NAMESPACES.merge(@custom_namespaces) do
          xml.d :set do
            xml.d :prop do
              props.each do |prop|
                xml.tag! prop[:name], prop[:value]
              end
            end
          end
        end
      end
    end

    class ReportVEVENT < Base

      def initialize
        super
      end

      def etags(tstart = nil, tend = nil)
        xml.c 'calendar-query'.to_sym, NAMESPACES do
          xml.d :prop do
            xml.d :getetag
          end
          xml.c :filter do
            xml.c 'comp-filter'.to_sym, :name => 'VCALENDAR' do
              xml.c 'comp-filter'.to_sym, :name => 'VEVENT' do
                xml.c 'time-range'.to_sym, :start => "#{tstart}Z", :end => "#{tend}Z" if tstart && tend
              end
            end
          end
        end
      end

      def etag(href)
        xml.c 'calendar-multiget'.to_sym, NAMESPACES do
          xml.d :prop do
            xml.d :getetag
          end
          xml.d :href, href
        end
      end

      def all_events(tstart = nil, tend = nil)
        xml.c 'calendar-query'.to_sym, NAMESPACES do
          xml.d :prop do
            xml.d :getetag
            xml.c 'calendar-data'.to_sym
          end
          xml.c :filter do
            xml.c 'comp-filter'.to_sym, :name => 'VCALENDAR' do
              xml.c 'comp-filter'.to_sym, :name => 'VEVENT' do
                xml.c 'time-range'.to_sym, :start => "#{tstart}Z", :end => "#{tend}Z" if tstart && tend
              end
            end
          end
        end
      end

      def events(events_href)
        xml.c 'calendar-multiget'.to_sym, NAMESPACES do
          xml.d :prop do
            xml.d :getetag
            xml.c 'calendar-data'.to_sym
          end
          events_href.each do |href|
            xml.d :href, href
          end
        end
      end
    end

    class Propfind < Base
      def initialize
        super
      end

      def basic
        xml.d :propfind, NAMESPACES do
          xml.d :prop do
            xml.d :displayname
            xml.cs :getctag
          end
        end
      end
    end
  end
end
