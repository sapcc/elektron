require_relative './auth_session'
require_relative './service'
require_relative './utils/hashmap_helper'
require_relative './errors/service_unavailable'

module Elektron
  # Entry point
  class Client
    include Utils
    extend Forwardable

    def_delegators :@auth_session, :is_admin_project?, :user_id, :user_name,
                   :user_description, :user_domain_id, :user_domain_name,
                   :domain_id, :domain_name, :project_id, :project_name,
                   :project_parent_id, :project_domain_id, :project_domain_name,
                   :expires_at, :expired?, :issued_at, :catalog,
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
      # make auth_conf accessible via symbols and strings
      auth_conf = with_indifferent_access(auth_conf)
      # make options accessible via symbols and strings
      options = with_indifferent_access(options)

      @options = deep_merge({}.merge(DEFAULT_OPTIONS), options)
      @auth_session = Elektron::AuthSession.new(auth_conf, @options)
      @services = {}
    end

    def service(name, options = {})
      # caching
      key = "#{name}_#{options}"
      raise Elektron::Errors::ServiceUnavailable, name unless service?(name)
      @services[key] ||= Service.new(name,
                                      @auth_session,
                                      @options.clone.merge(options))
    end
  end
end
