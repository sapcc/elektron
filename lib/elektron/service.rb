require_relative './http_client'
require_relative './uri_helper'

module Elektron
  class Service
    include UriHelper

    class ApiError < StandardError; end
    class ApiResponse
      extend Forwardable
      attr_reader :data
      def_delegators :@response, :body, :[]

      def initialize(response)
        @response = response
        @data = response.body
      end

      # This method is used to map raw data to a Object.
      def map_to(key_class_map, options = {})
        key = key_class_map.keys.first
        klass = key_class_map.values.first

        key_tokens = key.split('.')
        key_tokens.shift if key_tokens[0] == 'body'
        data = @response.body
        key_tokens.each { |k| data = data[k] }

        if data.is_a?(Array)
          data.collect do |item|
            klass.new(item.merge(options))
          end
        elsif data.is_a?(Hash)
          klass.new(data.merge(options))
        else
          data
        end
      end
    end

    attr_reader :name

    def initialize(name, auth_session, options = {})
      @name = name
      @auth_session = auth_session
      @options = options
      @options[:headers] ||= {}
      microversion = @options.delete(:microversion)
      if microversion
        if microversion.to_f >= 2.27
          @options[:headers]['OpenStack-API-Version'] = "#{@name} #{microversion}"
        else
          @options[:headers]['X-OpenStack-Nova-API-Version'] = microversion
        end
      end
      @path_prefix = @options.delete(:path_prefix)
    end

    def url
      @auth_session.token_context.service_url(
        @name,
        region: @options[:region],
        interface: @options[:interface]
      )
    end

    def get(path, params = {})
      handle_response http_client.get(full_path(path, params))
    end

    def post(path, params = {})
      data = yield if block_given?
      handle_response http_client.post(full_path(path, params), data)
    end

    def put(path, params = {}, &block)
      data = block.call() if block?
      handle_response http_client.put(full_path(path, params), data)
    end

    def patch(path, params = {}, &block)
      data = block.call() if block?
      handle_response http_client.patch(full_path(path, params), data)
    end

    def delete(path, params = {})
      handle_response http_client.delete(full_path(path, params))
    end

    private

    def full_path(path, params = {})
      if @path_prefix
        path = join_path_parts(@path_prefix, path)
      end
      to_url(path, params)
    end

    def http_client
      token = @auth_session.token_context.token
      if @service_url != url || @token != token
        options = @options.clone
        options[:headers]['X-Auth-Token'] = @auth_session.token_context.token
        @client = Elektron::HttpClient.new(url, options)
      end
      @client
    end

    def handle_response(response)
      ApiResponse.new(response)
    end
  end
end
