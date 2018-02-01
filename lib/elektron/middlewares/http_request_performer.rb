require_relative './base'
require 'uri'
require 'json'
require 'net/http'
require_relative '../utils/uri_helper'
require_relative '../utils/hashmap_helper'
require_relative '../errors/request'
require_relative '../errors/api_response'
require_relative '../version'

module Elektron
  module Middlewares
    # This is an Elektron middleware which wrappes the http response.
    # It also checks if the response code is smaller than 400. Otherwise
    # it raises an ApiError.
    class HttpRequestPerformer < ::Elektron::Middlewares::Base
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

      def call(request_context)
        uri = URI.parse(request_context.service_url)
        options = request_context.options || {}

        headers = headers(options)
        http_options = http_options(uri, request_options)

        path = to_url(request_context.path, (request_context.params || {}))
        @debug = options.fetch(:debug, false)

        request = create_request(
          request_context.http_method, path, headers, request_context.data
        )
        perform(uri, request, http_options)
      end

      def create_request(http_method, path, headers, data)
        http_method = http_method.to_sym

        if %i[post put patch].include?(http_method)
          headers = { 'Content-Type' => CONTENT_TYPE_JSON }.merge(headers)
        end

        request = case http_method
                  when :head then Net::HTTP::Head.new(path, headers)
                  when :get then Net::HTTP::Get.new(path, headers)
                  when :delete then Net::HTTP::Delete.new(path, headers)
                  when :post then Net::HTTP::Post.new(path, headers)
                  when :put then Net::HTTP::Put.new(path, headers)
                  when :patch then Net::HTTP::Patch.new(path, headers)
                  when :options then Net::HTTP::Options.new(path, headers)
                  when :copy then Net::HTTP::Copy.new(path, headers)
                  end

        if data && !data.empty?
          request.body = encode_data(headers['Content-Type'], data)
        end
        request
      end

      def encode_data(content_type, data)
        return data unless content_type == CONTENT_TYPE_JSON
        json?(data) ? data : JSON.generate(data)
      end

      def perform(uri, request, http_options)
        http = Net::HTTP.new(uri.host, uri.port, :ENV)
        http_options.each { |key, value| http.send("#{key}=", value) }
        http.set_debug_output($stdout) if @debug
        http.start { |connection| connection.request(request) }
      end

      def headers(request_options)
        clone_hash(DEFAULT_HEADERS).merge(request_options[:headers] || {})
      end

      def http_options(uri, request_options)
        client_options = clone_hash(request_options.fetch(:client, {}))
        http_options = clone_hash(DEFAULT_OPTIONS).merge(client_options)
        verify_ssl = http_options.delete(:verify_ssl) != false

        if uri.scheme == 'https'
          http_options[:use_ssl] = true
          if verify_ssl == false
            http_options[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
          end
        end

        http_options
      end
    end
  end
end
