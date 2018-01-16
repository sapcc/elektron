require_relative './http_client'
require_relative './utils/uri_helper'
require_relative './utils/hashmap_helper'
require_relative './errors/service_endpoint_unavailable'
require_relative './errors/bad_middleware'

module Elektron
  class Service
    include Utils::UriHelper
    include Utils::HashmapHelper

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
        key = key_class_map
        klass = nil
        if key_class_map.is_a?(Hash)
          key = key_class_map.keys.first
          klass = key_class_map.values.first
        end

        key_tokens = key.split('.')
        key_tokens.shift if key_tokens[0] == 'body'
        data = @response.body
        key_tokens.each { |k| data = data[k] }

        if data.is_a?(Array)
          data.collect do |item|
            params = item.merge(options)
            block_given? ? yield(params) : klass.new(params)
          end
        elsif data.is_a?(Hash)
          params = data.merge(options)
          block_given? ? yield(params) : klass.new(params)
        else
          data
        end
      end
    end

    attr_reader :name

    def initialize(name, auth_session, options = {})
      @name = name
      @auth_session = auth_session
      @options = clone_hash(options)
      @options[:headers] ||= {}
      @path_prefix = @options.delete(:path_prefix)
      @middlewares = []
    end

    def add_middleware(middleware = nil, &block)
      middleware = block if middleware.nil?
      if middleware.is_a?(Class) && !middleware.respond_to?(:call)
        middleware = middleware.new
      end

      unless middleware.respond_to?(:call)
        raise Elektron::Errors::BadMiddleware, 'Middleware does not respond to '\
                                               'call method! Please provide a '\
                                               'proc or an object with a call '\
                                               'method which accepts three '\
                                               'parameters "params", "options" '\
                                               'and "data"'
      end
      @middlewares << middleware && true
    end

    def get(path, *args)
      perform_request(:get, path, args)
    end

    def post(path, *args)
      data = yield if block_given?
      perform_request(:post, path, args, data)
    end

    def put(path, *args)
      data = yield if block_given?
      perform_request(:put, path, args, data)
    end

    def patch(path, *args)
      data = yield if block_given?
      perform_request(:patch, path, args, data)
    end

    def delete(path, *args)
      perform_request(:delete, path, args)
    end

    def options(path, *args)
      perform_request(:options, path, args)
    end

    def endpoint_url(options = {})
      region = (options[:region] || @options[:region])
      interface = (options[:interface] || @options[:interface])

      endpoint = @auth_session.service_url(
        @name, region: region, interface: interface
      )
      return endpoint if endpoint
      raise Elektron::Errors::ServiceEndpointUnavailable,
            "service: #{@name}, " \
            "region: #{region}, " \
            "interface: #{interface}"
    end

    private

    def perform_request(method, path, request_args, data=nil)
      params, options = get_params_and_options(request_args)

      @middlewares.each do |middleware|
        result = middleware.call(params, options, data)
        if !result.is_a?(Array) || result.length != 3
          raise ::Elektron::Errors::BadMiddleware, 'Middleware must return an '\
                                                   'array of three values, '\
                                                   'params", "options" '\
                                                   'and "data"'
        end
        params, options, data = result
      end

      # it is allowed to provide options via params,
      # so check both options and params
      path_prefix = options.delete(:path_prefix) || params.delete(:path_prefix)
      headers = options.delete(:headers) || params.delete(:headers) || {}

      region = options.delete(:region) || params.delete(:region)
      interface = options.delete(:interface) || params.delete(:interface)
      service_url = endpoint_url(region: region, interface: interface)
      path = full_path(service_url, path, params, path_prefix)

      handle_response do
        if %i[post put patch].include?(method)
          http_client(service_url).send(method, path, data, headers)
        else
          http_client(service_url).send(method, path, headers)
        end
      end
    end

    def handle_response(response = nil)
      response = yield if block_given?
      ApiResponse.new(response)
    end

    def get_params_and_options(args)
      params = args.length > 0 ? args[0] : {}
      options = args.length > 1 ? args[1] : {}
      [params, options]
    end

    def full_path(service_url, path, params = {}, path_prefix = nil)
      if path !~ /https?:\/\/[\S]+/ &&
         !(path_prefix.nil? && @path_prefix.nil? && path.start_with?('/'))

        path_prefix ||= @path_prefix
        path_prefix ||= URI(service_url).path

        path = join_path_parts(path_prefix, path) if path_prefix
      end

      url = to_url(path, params)
      if @auth_session.project_id
        url.gsub!(/:project_id/, @auth_session.project_id)
        url.gsub!(/:tenant_id/, @auth_session.project_id)
      end
      url
    end

    def http_client(service_url)
      token = @auth_session.token
      # caching
      if @service_url != service_url || @token != token
        options = clone_hash(@options)
        options[:headers]['X-Auth-Token'] = token
        @client = Elektron::HttpClient.new(service_url, options)
        @service_url = service_url
        @token = token
      end
      @client
    end
  end
end
