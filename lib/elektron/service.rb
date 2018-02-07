require_relative './utils/uri_helper'
require_relative './utils/hashmap_helper'
require_relative './errors/service_endpoint_unavailable'
require_relative './errors/bad_middleware'

module Elektron
  class Service
    include Utils::HashmapHelper
    include Utils::UriHelper

    DEFAULT_OPTIONS = {
      path_prefix: nil
    }.merge(Elektron::Client::DEFAULT_OPTIONS).freeze

    attr_reader :name, :middlewares

    def initialize(name, auth_session, middlewares, options = {})
      @name = name
      @auth_session = auth_session
      @options = clone_hash(options)
      @middlewares = middlewares.clone
      @cache = {}
    end

    def get(path, *args)
      perform_request(:get, path, args)
    end

    def head(path, *args)
      perform_request(:head, path, args)
    end

    def copy(path, *args)
      perform_request(:copy, path, args)
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

    def endpoint_url(region: @options[:region], interface: @options[:interface])
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

    def perform_request(method, path, request_args, data = nil)
      params, options = get_params_and_options(request_args)
      service_url = endpoint_url(region: options[:region],
                                 interface: options[:interface])
      uri = URI(service_url)
      service_url = "#{uri.scheme}://#{uri.host}"
      service_url += ":#{uri.port}" if uri.port

      path = extend_path(path, uri.path, options[:path_prefix])
      extend_headers(options)

      request_context = Elektron::Containers::RequestContext.new(
        service_name: @name, service_url: service_url,
        http_method: method, path: path, params: params,
        options: options, data: data, cache: @cache
      )
      @middlewares.execute(request_context)
    end

    def extend_headers(options)
      options[:headers] ||= {}
      token = @auth_session.token
      return unless token
      options[:headers]['X-Auth-Token'] = token
    end

    def extend_path(path, uri_path, path_prefix = nil)
      if path !~ /https?:\/\/[\S]+/
        if path_prefix.nil? || path_prefix.empty?
          path = join_path_parts(uri_path, path)
        elsif path_prefix.start_with?('/')
          path = join_path_parts(path_prefix, path)
        else
          path = join_path_parts(uri_path, path_prefix, path)
        end
      end

      if @auth_session.project_id
        path.gsub!(/:project_id/, @auth_session.project_id)
        path.gsub!(/:tenant_id/, @auth_session.project_id)
      end

      path
    end

    def get_params_and_options(args)
      params = args.length.positive? ? args[0] : {}
      options = args.length > 1 ? args[1] : {}

      # merge service options with request options
      # This allows to overwrite all options by single request
      request_options = DEFAULT_OPTIONS.keys.each_with_object({}) do |key, hash|
        value = options[key] || params.delete(key)
        hash[key] = value unless value.nil?
      end

      options = deep_merge(clone_hash(@options), request_options)

      [params, options]
    end
  end
end
