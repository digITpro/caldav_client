require 'builder'

module RubyCaldav
  NAMESPACES = {"xmlns:d" => 'DAV:', "xmlns:c" => "urn:ietf:params:xml:ns:caldav"}
  module Request
    class Base
      def initialize
        @xml = Builder::XmlMarkup.new(:indent => 2)
        @xml.instruct!
      end

      attr :xml
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
            xml.c 'calendar-data'.to_sym
          end
          events_href.each do |href|
            xml.d :href, href
          end
        end
      end
    end
  end
end
