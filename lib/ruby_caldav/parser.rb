module RubyCaldav
  class Parser

    module ClassMethods
      def parse_events(body)
        xml = Oga.parse_xml(body)
        parsed_events = []

        xml.xpath("multistatus/response").each do |response|
          href = response.xpath("href").text
          etag = response.xpath("propstat/prop/getetag").text
          event_str = response.xpath("propstat/prop/C:calendar-data").text
          if event_str
            calendars = RiCal.parse_string(event_str)
            if calendars && (calendar = calendars.first) && (events = calendar.events)
              event = events.first
              event.add_x_property("HREF", href)
              event.add_x_property("ETAG", etag)
              parsed_events << event
            end
          end
        end
        parsed_events
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
        xml = Oga.parse_xml(body)
        events_etag = []
        xml.xpath("multistatus/response").each do |response|
          href_str = response.xpath("href").text
          etag_str = response.xpath("propstat/prop/getetag").text
          events_etag << {href: href_str, etag: etag_str}
        end
        events_etag
      end

      def parse_propfind(body)
        xml = Oga.parse_xml(body)
        properties = {}
        xml.xpath("multistatus/response").each do |response|
          response.xpath("propstat/prop/*").each do |prop|
            properties[prop.name] = prop.text
          end
        end
        properties
      end

    end

    extend ClassMethods
  end
end