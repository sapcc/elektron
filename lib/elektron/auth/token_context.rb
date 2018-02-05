require 'date'
require_relative '../errors/bad_token_context'

module Elektron
  module TokenContext
    attr_reader :context

    def current_context(context)
      raise Elektron::Errors::BadTokenContext unless context.is_a?(Hash)
      @context = context['token'].nil? ? context : context['token']
      @token_values = {}
    end

    def is_admin_project?
      @token_values[:is_admin_project] ||= read_value('is_admin_project') || false
    end

    def user_id
      @token_values[:user_id] ||= read_value('user.id')
    end

    def user_name
      @token_values[:user_name] ||= read_value('user.name')
    end

    def user_description
      @token_values[:user_description] ||= read_value('user.description')
    end

    def user_domain_id
      @token_values[:user_domain_id] ||= read_value('user.domain.id')
    end

    def user_domain_name
      @token_values[:user_domain_name] ||= read_value('user.domain.name')
    end

    def domain_id
      @token_values[:scope_domain_id] ||= read_value('domain.id')
    end

    def domain_name
      @token_values[:scope_domain_name] ||= read_value('domain.name')
    end

    def project_id
      @token_values[:scope_project_id] ||= read_value('project.id')
    end

    def project_name
      @token_values[:scope_project_name] ||= read_value('project.name')
    end

    def project_parent_id
      @token_values[:project_parent_id] ||= read_value('project.parent_id')
    end

    def project_domain_id
      @token_values[:project_domain_id] ||= read_value('project.domain.id')
    end

    def project_domain_name
      @token_values[:project_domain_name] ||= read_value('project.domain.name')
    end

    def project
      @token_values[:project] ||= read_value('project')
    end

    def domain
      @token_values[:domain] ||= read_value('domain')
    end

    def expires_at
      @token_values[:token_expires_at] ||= DateTime.parse(@context['expires_at']).to_time
    end

    def expired?
      expires_at < Time.now
    end

    def issued_at
      @token_values[:token_issued_at] ||= DateTime.parse(@context['issued_at']).to_time
    end

    def catalog
      @token_values[:catalog] ||= (@context['catalog'] || @context['serviceCatalog'] || [])
    end

    def service?(type)
      services = catalog.select do |service|
        service['type'] == type || service['name'] == type
      end
      !services.empty?
    end

    def roles
      @token_values[:roles] ||= (@context['roles'] || read_value('user.roles') || [])
    end

    def role_names
      @token_values[:role_names] ||= roles.nil? ? [] : roles.collect { |r| r.is_a?(Hash) ? r['name'] : r }
    end

    def has_role?(name)
      roles.each { |role| return true if role['name'] == name }
      false
    end

    def service_url(type, options={})
      region = options[:region] || available_services_regions.first
      interface = options[:interface] || 'public'

      service = catalog.find do |s|
        s['type'] == type.to_s || s['name'] == type.to_s
      end

      return nil unless service

      endpoint = service['endpoints'].find do |e|
        e['region_id'] == region.to_s && e['interface'] == interface.to_s
      end

      return nil unless endpoint

      endpoint['url']
    end

    # Returns list of unique region name values found in service catalog
    def available_services_regions
      unless @token_values[:regions]
        @token_values[:regions] = []
        catalog.each do |service|
          next if service['type']=='identity'
          (service['endpoints'] || []).each do |endpoint|
            @token_values[:regions] << endpoint['region']
          end
        end
        @token_values[:regions].uniq!
      end
      @token_values[:regions]
    end

    protected

    # Returns a value from context for given key.
    # example for key: 'user.id'
    def read_value(key)
      keys = key.split('.')
      result = @context
      keys.each do |k|
        return nil unless result
        result = result[k]
      end
      result
    end
  end
end
