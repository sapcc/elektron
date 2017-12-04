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

    def get(path, *args)
      params, headers = get_params_and_headers(args)
      handle_response http_client.get(full_path(path, params), headers)
    end

    def post(path, *args)
      params, headers = get_params_and_headers(args)
      data = yield if block_given?
      handle_response http_client.post(full_path(path, params), data, headers)
    end

    def put(path, *args)
      params, headers = get_params_and_headers(args)
      data = yield if block_given?
      handle_response http_client.put(full_path(path, params), data, headers)
    end

    def patch(path, *args)
      params, headers = get_params_and_headers(args)
      data = yield if block_given?
      handle_response http_client.patch(full_path(path, params), data, headers)
    end

    def delete(path, *args)
      params, headers = get_params_and_headers(args)
      handle_response http_client.delete(full_path(path, params), headers)
    end

    private

    def get_params_and_headers(args)
      params = args.length > 0 ? args[0] : {}
      headers = args.length > 1 ? args[1] : {}
      [params, headers]
    end

    def full_path(path, params = {})
      path = join_path_parts(@path_prefix, path) if @path_prefix
      p ">>>>>>>>>>>>>>>>>>>>>>>>>>"
      p path
      p params
      p @auth_session.project_id
      p to_url(path, params).gsub(/:project_id/, @auth_session.project_id)
      url = to_url(path, params).gsub(/:project_id/, @auth_session.project_id)
                          .gsub(/:tenant_id/, @auth_session.project_id)
      p url
      url
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
