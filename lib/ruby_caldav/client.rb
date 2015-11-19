module RubyCaldav

  class Client
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

      uri = URI(data[:uri])
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
        request = Net::HTTP::Report.new(@url, initheader = {'Content-Type' => 'application/xml'})
        add_auth_header(request, 'REPORT')
        request.body = RubyCaldav::Request::ReportVEVENT.new.any_events(Time.parse(start_at).utc.strftime("%Y%m%dT%H%M%S"),
                                                                        Time.parse(end_at).utc.strftime("%Y%m%dT%H%M%S"))
        response = http.request(request)
      end
      handle_errors(response)

      RubyCaldav::Parser.parse_events(response.body)
    end

    def find_etags(start_at = nil, end_at = nil)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Report.new(@url, initheader = {'Content-Type' => 'application/xml'})
        add_auth_header(request, 'REPORT')
        request.body = RubyCaldav::Request::ReportVEVENT.new.etags(Time.parse(start_at).utc.strftime("%Y%m%dT%H%M%S"),
                                                                   Time.parse(end_at).utc.strftime("%Y%m%dT%H%M%S"))
        response = http.request(request)
      end
      handle_errors(response)

      RubyCaldav::Parser.parse_etags(response.body)
    end

    def find_events(events_href)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Report.new(@url, initheader = {'Content-Type' => 'application/xml'})
        add_auth_header(request, 'REPORT')
        request.body = RubyCaldav::Request::ReportVEVENT.new.events(events_href)
        response = http.request(request)
      end
      handle_errors(response)

      RubyCaldav::Parser.parse_events(response.body)
    end

    def find_event(uuid)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Get.new("#{@url}/#{uuid}.ics")
        add_auth_header(request, 'GET')
        response = http.request(request)
      end
      handle_errors(response)

      RubyCaldav::Parser.parse_event(response.body)
    end

    def delete_event(uuid)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Delete.new("#{@url}/#{uuid}.ics")
        add_auth_header(request, 'DELETE')
        response = http.request(request)
      end
      handle_errors(response)

      response.code.to_i.between?(200, 299)
    end

    def save_event(uid, ical_string)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Put.new("#{@url}/#{uid}.ics")
        request['Content-Type'] = 'text/calendar'
        add_auth_header(request, 'PUT')
        request.body = ical_string
        response = http.request(request)
      end
      handle_errors(response)
      response.code.to_i == 201
    end

    def entry_with_uuid_exists?(uuid)
      response = nil
      build_http.start do |http|
        request = Net::HTTP::Get.new("#{@url}/#{uuid}.ics")
        add_auth_header(request, 'GET')
        response = http.request(request)
      end
      handle_errors(response)
      response.code.to_i == 200
    end

    private

    def digest_auth(method)
      http = Net::HTTP.new(@digest_uri.host, @digest_uri.port)
      if @ssl
        http.use_ssl = @ssl
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Get.new @digest_uri.request_uri
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

    def handle_errors(response)
      raise AuthenticationError if response.code.to_i == 401
      raise NotExistError if response.code.to_i == 410
      raise APIError if response.code.to_i >= 500
    end
  end


  class AgCalDAVError < StandardError
  end
  class AuthenticationError < AgCalDAVError;
  end
  class DuplicateError < AgCalDAVError;
  end
  class APIError < AgCalDAVError;
  end
  class NotExistError < AgCalDAVError;
  end
end
