module RubyCaldav
  class Parser

    module ClassMethods
      def parse_events(body)
        xml = REXML::Document.new(body)
        result = ""
        REXML::XPath.each(xml, '//c:calendar-data/', {"c" => "urn:ietf:params:xml:ns:caldav"}) { |calendar| result << calendar.text }
        calendars = RiCal.parse_string(result)
        if calendars.empty?
          calendars
        else
          events= []
          calendars.each do |calendar|
            calendar.events.each do |event|
              events << event
            end
          end
          events
        end
      end

      def parse_event(body)
        calendars = RiCal.parse_string(body)
        if calendars.empty?
          nil
        else
          calendars.first.events.first
        end
      end

      def parse_etags(body)
        xml = REXML::Document.new(body)
        events_etag = []
        href_str = ""
        etag_str = ""
        REXML::XPath.each(xml, "multistatus/response") do |response|
          response.each_element("href") do |href|
            href_str = href.text
          end
          response.each_element("propstat/prop/getetag") do |etag|
            etag_str = etag.text
          end
          events_etag << {href: href_str, etag: etag_str}
        end
        events_etag
      end

      def parse_propfind(body)
        xml = REXML::Document.new(body)
        properties = {}
        REXML::XPath.each(xml, "multistatus/response") do |response|
          response.each_element("propstat/prop/*") do |prop|
            properties[prop.name] = prop.text
          end
        end
        properties
      end

    end

    extend ClassMethods
  end
end