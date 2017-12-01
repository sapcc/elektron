require_relative './authentication'
require_relative './service'
require_relative './utils'

module Elektron
  # Entry point
  class AuthSession
    include Utils
    extend Forwardable
    def_delegators :token_context, :is_admin_project?, :user_id, :user_name,
                   :user_description, :user_domain_id, :user_domain_name,
                   :domain_id, :domain_name, :project_id, :project_name,
                   :project_parent_id, :project_domain_id, :project_domain_name,
                   :expires_at, :expired?, :issued_at, :service_catalog,
                   :service?, :roles, :role_names, :has_role?, :service_url,
                   :available_services_regions, :token

    DEFAULT_OPTIONS = {
      # version: 'V3',
      headers: {},
      interface: 'internal',
      client: {},
      debug: false
    }.freeze

    def initialize(auth_conf, options)
      @auth_conf = with_indifferent_access(auth_conf)
      @options = deep_merge(
        {}.merge(DEFAULT_OPTIONS), with_indifferent_access(options)
      )
      @services = {}
    end

    def token_context
      return @token_context if @token_context && !@token_context.expired?
      @token_context = Elektron::Authentication.token_context(
        @auth_conf, @options
      )
    end

    def service(name, options = {})
      @services[name] ||= Service.new(
        name, self, {}.merge(@options).merge(options)
      )
    end
  end
end
