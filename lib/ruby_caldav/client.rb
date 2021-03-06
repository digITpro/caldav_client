module RubyCaldav

  class Client
    INIT_HEADER = {
      "Depth" => "1",
      "User-Agent" => "DAVKit/4.0.1 (730); CalendarStore/4.0.1 (973); iCal/4.0.1 (1374); Mac OS X/10.6.2 (10C540)",
      "Content-Type" => "text/xml; charset='UTF-8'"
    }.freeze

    attr_accessor :host, :port, :url, :user, :password, :ssl

    def format=(fmt)
      @format = fmt
    end

    def format
      @format ||= Format::Debug.new
    end

    def initialize(data)
      unless data[:proxy_uri].nil?
        proxy_uri = URI(data[:proxy_uri])
        @proxy_host = proxy_uri.host
        @proxy_port = proxy_uri.port.to_i
      end

      uri = URI(data[:uri].end_with?('/') ? data[:uri] : "#{data[:uri]}/")
      @host = uri.host
      @port = uri.port.to_i
      @url = uri.path
      @user = data[:user]
      @password = data[:password]
      @ssl = uri.scheme == 'https'

      if data[:authentication_type].nil? || data[:authentication_type] == 'basic'
        @authentication_type = 'basic'
      elsif @authentication_type == 'digest'
        @authentication_type = 'digest'
        @digest_auth = Net::HTTP::DigestAuth.new
        @digest_uri = URI.parse(data[:uri])
        @digest_uri.user = @user
        @digest_uri.password = @password
      else
        raise "Authentication Type Specified Is Not Valid. Please use basic or digest"
      end
    end

    def build_http
      if @proxy_uri.nil?
        http = Net::HTTP.new(@host, @port)
      else
        http = Net::HTTP.new(@host, @port, @proxy_host, @proxy_port)
      end
      if @ssl
        http.use_ssl = @ssl
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http
    end

    def all_events(start_at, end_at)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Report.new(@url, INIT_HEADER)
        add_auth_header(request, 'REPORT')
        request.body = RubyCaldav::Request::ReportVEVENT.new.all_events(Time.parse(start_at).utc.strftime("%Y%m%dT%H%M%S"),
                                                                        Time.parse(end_at).utc.strftime("%Y%m%dT%H%M%S"),
                                                                        skip_getetag: true)
        response = http.request(request)
        handle_errors(response, request)
      end

      RubyCaldav::Parser.parse_events(response.body)
    end

    def find_etags(start_at = nil, end_at = nil)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Report.new(@url, INIT_HEADER)
        add_auth_header(request, 'REPORT')
        if start_at && end_at
          request.body = RubyCaldav::Request::ReportVEVENT.new.etags(Time.parse(start_at).utc.strftime("%Y%m%dT%H%M%S"),
                                                                     Time.parse(end_at).utc.strftime("%Y%m%dT%H%M%S"))
        else
          request.body = RubyCaldav::Request::ReportVEVENT.new.etags
        end
        response = http.request(request)
        handle_errors(response, request)
      end

      RubyCaldav::Parser.parse_etags(response.body)
    end

    def find_events(events_href)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Report.new(@url, INIT_HEADER)
        add_auth_header(request, 'REPORT')
        request.body = RubyCaldav::Request::ReportVEVENT.new.events(events_href, skip_getetag: true)
        response = http.request(request)
        handle_errors(response, request)
      end

      RubyCaldav::Parser.parse_events(response.body)
    end

    def find_event(href)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Get.new(href, INIT_HEADER)
        add_auth_header(request, 'GET')
        response = http.request(request)
        handle_errors(response, request)
      end

      RubyCaldav::Parser.parse_event(response.body)
    end

    def find_etag(href)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Report.new(@url, INIT_HEADER)
        add_auth_header(request, 'REPORT')
        request.body = RubyCaldav::Request::ReportVEVENT.new.etag(href)
        response = http.request(request)
        handle_errors(response, request)
      end
      RubyCaldav::Parser.parse_etags(response.body)
    end

    def delete_event(href)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Delete.new(href, INIT_HEADER)
        add_auth_header(request, 'DELETE')
        response = http.request(request)
        handle_errors(response, request)
      end

      http_success?(response)
    end

    def save_event(href, ical_string)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Put.new(href, INIT_HEADER)
        request['Content-Type'] = 'text/calendar'
        add_auth_header(request, 'PUT')
        request.body = ical_string
        response = http.request(request)
        handle_errors(response, request)
      end
      http_success?(response)
    end

    def entry_with_uhref_exists?(href)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Get.new(href, INIT_HEADER)
        add_auth_header(request, 'GET')
        response = http.request(request)
        handle_errors(response, request)
      end
      http_success?(response)
    end

    def create_calendar(identifier, display_name = nil, description = nil, color = nil)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Mkcalendar.new("#{@url}#{identifier}/", INIT_HEADER)
        add_auth_header(request, 'MKCALENDAR')
        request.body = RubyCaldav::Request::Mkcalendar.new(display_name, description, color).to_xml
        response = http.request(request)
        handle_errors(response, request)
      end
      http_success?(response)
    end

    def update_calendar(properties, custom_namespaces = {})
      response = nil
      build_http.start do |http|
        request = Net::HTTP::PropPatch.new(@url, INIT_HEADER)
        add_auth_header(request, 'PROPPATCH')
        request.body = RubyCaldav::Request::PropPatch.new(properties, custom_namespaces).to_xml
        response = http.request(request)
        handle_errors(response, request)
      end
      http_success?(response)
    end

    def delete_calendar
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Delete.new(@url, INIT_HEADER)
        add_auth_header(request, 'DELETE')
        response = http.request(request)
        handle_errors(response, request)
      end
      http_success?(response)
    end

    def calendar_all_props
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Propfind.new(@url, INIT_HEADER)
        add_auth_header(request, 'PROPFIND')
        request.body = RubyCaldav::Request::Propfind.new.basic
        response = http.request(request)
        handle_errors(response, request)
      end
      RubyCaldav::Parser.parse_propfind(response.body)
    end

    def calendar_timezone
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Propfind.new(@url, INIT_HEADER)
        add_auth_header(request, 'PROPFIND')
        request.body = RubyCaldav::Request::Propfind.new.basic(["c:calendar-timezone"])
        response = http.request(request)
        handle_errors(response, request)
      end
      RubyCaldav::Parser.parse_propfind(response.body)["calendar-timezone"]
    end

    private

    def digest_auth(method)
      http = Net::HTTP.new(@digest_uri.host, @digest_uri.port)
      if @ssl
        http.use_ssl = @ssl
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Get.new(@digest_uri.request_uri, INIT_HEADER)
      response = http.request(request)
      @digest_auth.auth_header(@digest_uri, response['www-authenticate'], method)
    end

    def add_auth_header(request, method)
      if @authentication_type != 'digest'
        request.basic_auth(@user, @password)
      else
        request.add_field('Authorization', digest_auth(method))
      end
    end

    def http_success?(response)
      response.code.to_i.between?(200, 299)
    end

    def handle_errors(response, request)
      unless http_success?(response)
        p '==== API error detail ===='
        p '==== Request'
        p "path: #{request.path}"
        p "method: #{request.method}"
        p 'headers:'
        p request.to_hash.inspect
        p 'body:'
        p request.body.inspect
        p '==== Response'
        p "code: #{response.code.to_i}"
        p "message: #{response.message.inspect}"
        p 'header:'
        p response.header.inspect
        p 'body:'
        p response.body.inspect
        p '=========================='
      end
      raise AuthenticationError if response.code.to_i == 401
      raise ForbiddenError if response.code.to_i == 403
      raise NotExistError if response.code.to_i == 410
      raise APIError if response.code.to_i != 404 && response.code.to_i >= 400
    end
  end


  class RubyCaldavError < StandardError
  end
  class AuthenticationError < RubyCaldavError;
  end
  class ForbiddenError < RubyCaldavError;
  end
  class DuplicateError < RubyCaldavError;
  end
  class APIError < RubyCaldavError;
  end
  class NotExistError < RubyCaldavError;
  end
end
