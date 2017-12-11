require_relative './http_client'
require_relative './utils/uri_helper'
require_relative './errors/service_endpoint_unavailable'

module Elektron
  class Service
    include UriHelper

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
      microversion = microversion_header(@options.delete(:microversion))
      @options[:headers].merge(microversion) if microversion
      @path_prefix = @options.delete(:path_prefix)
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

      # it is allowed to provide options via params,
      # so check both options and params
      path_prefix = options.delete(:path_prefix) || params.delete(:path_prefix)
      headers = options.delete(:headers) || params.delete(:headers) || {}
      region = options.delete(:region) || params.delete(:region)
      interface = options.delete(:interface) || params.delete(:interface)

      microversion = options.delete(:microversion)
      headers.megre(microversion_header(microversion)) if microversion
      path = full_path(path, params, path_prefix)

      handle_response do
        if data
          http_client(region: region, interface: interface).send(
            method, path, data, headers
          )
        else
          http_client(region: region, interface: interface).send(
            method, path, headers
          )
        end
      end
    end

    def microversion_header(microversion)
      if microversion
        if microversion.to_f >= 2.27
          return { 'OpenStack-API-Version' => "#{@name} #{microversion}" }
        else
          return { 'X-OpenStack-Nova-API-Version' => microversion }
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

    def full_path(path, params = {}, path_prefix = nil)
      path_prefix ||= @path_prefix
      path = join_path_parts(path_prefix, path) if path_prefix
      url = to_url(path, params)
      if @auth_session.project_id
        url.gsub!(/:project_id/, @auth_session.project_id)
        url.gsub!(/:tenant_id/, @auth_session.project_id)
      end
      url
    end

    def http_client(request_options = {})
      token = @auth_session.token
      service_url = endpoint_url(request_options)
      if @service_url != service_url || @token != token
        options = @options.clone
        options[:headers]['X-Auth-Token'] = token
        @client = Elektron::HttpClient.new(service_url, options)
        @service_url = service_url
        @token = token
      end
      @client
    end

    # def http_client
    #   token = @auth_session.token
    #   service_url = url
    #   if @service_url != service_url || @token != token
    #     options = @options.clone
    #     options[:headers]['X-Auth-Token'] = token
    #     @client = Elektron::HttpClient.new(url, options)
    #     @service_url = service_url
    #     @token = token
    #   end
    #   @client
    # end

  end
end
