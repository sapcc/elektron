require 'uri'
require 'json'
require 'net/http'
require_relative './utils/uri_helper'
require_relative './utils/hashmap_helper'
require_relative './errors/request'
require_relative './errors/api_response'
require_relative './version'

module Elektron
  # http client
  class HttpClient
    include Utils::HashmapHelper

    # Content-types
    CONTENT_TYPE_JSON = 'application/json'.freeze
    CONTENT_TYPE_FORM = 'application/x-www-form-urlencoded'.freeze

    DEFAULT_OPTIONS = {
      open_timeout: 10,
      read_timeout: 60,
      keep_alive_timeout: 60
    }.freeze

    DEFAULT_HEADERS = {
      'Accept' => CONTENT_TYPE_JSON,
      'Connection' => 'keep-alive',
      'User-Agent' => "Elektron #{::Elektron::VERSION}"
    }.freeze

    def initialize(url, options = {})
      @uri = URI.parse(url)
      # important: create a deep copy of options!
      options = clone_hash(options)
      default_headers = clone_hash(DEFAULT_HEADERS)
      options_headers = (options.delete(:headers) || {})

      @headers = default_headers.merge(options_headers)
      @http_options = clone_hash(DEFAULT_OPTIONS)

      verify_ssl = options.fetch(:client, {}).delete(:verify_ssl) != false
      if @uri.scheme == 'https'
        @http_options[:use_ssl] = true
        if verify_ssl == false
          @http_options[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
        end
      end

      @http_options.merge!(options[:client]) if options[:client]
      @debug = options[:debug]
    end

    ############ REQUESTS ############
    # DELETE
    def delete(path, headers = {})
      headers = {}.merge(@headers).merge(headers)
      request = Net::HTTP::Delete.new(path, headers)
      perform(request)
    end

    # GET
    def get(path, headers = {})
      headers = {}.merge(@headers).merge(headers)
      perform(Net::HTTP::Get.new(path, headers))
    end

    # HEAD
    def head(path, headers = {})
      headers = {}.merge(@headers).merge(headers)
      perform(Net::HTTP::Head.new(path, headers))
    end

    # OPTIONS
    def options(path, headers = {})
      headers = {}.merge(@headers).merge(headers)
      perform(Net::HTTP::Options.new(path, headers))
    end

    # PATCH
    def patch(path, *args)
      data = args.empty? ? {} : args[0]
      headers = args.length > 1 ? args[1] : {}
      headers = { 'Content-Type' => CONTENT_TYPE_JSON }.merge(@headers)
                                                       .merge(headers)
      request = Net::HTTP::Patch.new(path, headers)
      if data && !data.empty?
        request.body = json?(data) ? data : JSON.generate(data)
      end
      perform(request)
    end

    # POST
    def post(path, *args)
      data = args.empty? ? {} : args[0]
      headers = args.length > 1 ? args[1] : {}
      headers = { 'Content-Type' => CONTENT_TYPE_JSON }.merge(@headers)
                                                       .merge(headers)

      request = Net::HTTP::Post.new(path, headers)
      if data && !data.empty?
        request.body = json?(data) ? data : JSON.generate(data)
      end
      perform(request)
    end

    # PUT
    def put(path, *args)
      data = args.empty? ? {} : args[0]
      headers = args.length > 1 ? args[1] : {}
      headers = { 'Content-Type' => CONTENT_TYPE_JSON }.merge(@headers)
                                                       .merge(headers)

      request = Net::HTTP::Put.new(path, headers)
      if data && !data.empty?
        request.body = json?(data) ? data : JSON.generate(data)
      end
      perform(request)
    end

    protected

    def perform(request)
      http = Net::HTTP.new(@uri.host, @uri.port, :ENV)
      @http_options.each { |key, value| http.send("#{key}=", value) }
      http.set_debug_output($stdout) if @debug

      response = http.start { |connection| connection.request(request) }
    rescue StandardError => e
      raise ::Elektron::Errors::Request, e
    else
      return parse(response) if response.code.to_i < 400
      raise ::Elektron::Errors::ApiResponse, response
    end

    def parse(response)
      if response.body && response.content_type == CONTENT_TYPE_JSON
        # Parse the response as JSON if possible.
        response.body = JSON.parse(response.body)
      end
      response
    rescue JSON::ParserError
      # do nothing
      return response
    end

    def json?(string)
      return false unless string.is_a?(String)
      JSON.parse(string) && true
    rescue JSON::ParserError => _e
      false
    end
  end
end
