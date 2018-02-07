require_relative './auth/session'
require_relative './utils/hashmap_helper'
require_relative './errors/service_unavailable'
require_relative './middlewares/stack'
require_relative './middlewares/http_request_performer'
require_relative './middlewares/response_handler'
require_relative './middlewares/response_error_handler'

module Elektron
  # Entry point
  class Client
    include Utils::HashmapHelper
    extend Forwardable

    def_delegators :@auth_session, :is_admin_project?, :user_id, :user_name,
                   :user_description, :user_domain_id, :user_domain_name,
                   :domain_id, :domain_name, :project_id, :project_name,
                   :project_parent_id, :project_domain_id, :project_domain_name,
                   :expires_at, :expired?, :issued_at, :catalog,
                   :service?, :roles, :role_names, :has_role?, :service_url,
                   :available_services_regions, :token, :enforce_valid_token

    DEFAULT_OPTIONS = {
      # version: 'V3',
      headers: {},
      interface: 'internal',
      region: nil,
      http_client: {},
      debug: false
    }.freeze

    def initialize(auth_conf, options = {})
      # make auth_conf accessible via symbols and strings
      auth_conf = with_indifferent_access(clone_hash(auth_conf))
      # make options accessible via symbols and strings
      options = with_indifferent_access(options)
      # important: clone DEFAULT_OPTIONS
      default_options = clone_hash(DEFAULT_OPTIONS)

      @options = deep_merge(default_options, options)

      @request_performer = Elektron::Middlewares::Stack.new
      @request_performer.add(Elektron::Middlewares::HttpRequestPerformer)
      @request_performer.add(Elektron::Middlewares::ResponseErrorHandler)
      @request_performer.add(Elektron::Middlewares::ResponseHandler)

      @auth_session = Elektron::Auth::Session.new(
        auth_conf, @request_performer, @options
      )
      @services = {}
    end

    def middlewares
      @request_performer
    end

    def service(name, options = {})
      # caching
      key = "#{name}_#{options}"
      raise Elektron::Errors::ServiceUnavailable, name unless service?(name)
      @services[key] ||= Service.new(name,
                                     @auth_session,
                                     @request_performer,
                                     service_options(options))
    end

    def service_options(options)
      # merge service options with request options
      # This allows to overwrite all options by single request
      default_options_keys = Elektron::Service::DEFAULT_OPTIONS.keys

      options.select! { |k, _| default_options_keys.include?(k) }
      deep_merge(clone_hash(@options), options)
    end
  end
end
