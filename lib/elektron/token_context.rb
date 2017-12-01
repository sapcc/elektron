require 'date'

module Elektron
  class TokenContext
    attr_reader :context
    
    def initialize(context, value)
      @context = context['token'].nil? ? context : context['token']
      @value = value
    end

    def token
      @value
    end

    def is_admin_project?
      @is_admin_project ||= read_value('is_admin_project')
    end

    def user_id
      @user_id ||= read_value('user.id')
    end

    def user_name
      @user_name ||= read_value('user.name')
    end

    def user_description
      @user_description ||= read_value('user.description')
    end

    def user_domain_id
      @user_domain_id ||= read_value('user.domain.id')
    end

    def user_domain_name
      @user_domain_name ||= read_value('user.domain.name')
    end

    def domain_id
      @scope_domain_id ||= read_value('domain.id')
    end

    def domain_name
      @scope_domain_name ||= read_value('domain.name')
    end

    def project_id
      @scope_project_id ||= read_value('project.id')
    end

    def project_name
      @scope_project_name ||= read_value('project.name')
    end

    def project_parent_id
      @project_parent_id ||= read_value('project.parent_id')
    end

    def project_domain_id
      @project_domain_id ||= read_value('project.domain.id')
    end

    def project_domain_name
      @project_domain_name ||= read_value('project.domain.name')
    end

    def project
      @project ||= read_value('project')
    end

    def domain
      @domain ||= read_value('domain')
    end

    def expires_at
      @token_expires_at ||= DateTime.parse(@context['expires_at']).to_time
    end

    def expired?
      expires_at < Time.now
    end

    def issued_at
      @token_issued_at ||= DateTime.parse(@context['issued_at']).to_time
    end

    def service_catalog
      @service_catalog ||= (@context['catalog'] || @context['serviceCatalog'] || [])
    end

    def service?(type)
      services = service_catalog.select { |service| service['type'] == type }
      !services.empty?
    end

    def roles
      @roles ||= (@context['roles'] || read_value('user.roles') || [])
    end

    def role_names
      @role_names ||= roles.nil? ? [] : roles.collect { |r| r.is_a?(Hash) ? r['name'] : r }
    end

    def has_role?(name)
      roles.each { |role| return true if role['name'] == name }
      false
    end

    def service_url(type, options={})
      region = options[:region] || default_services_region
      interface = options[:interface] || 'public'

      service = service_catalog.find do |s|
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
      unless @regions
        @regions = []
        service_catalog.each do |service|
          next if service['type']=='identity'
          (service['endpoints'] || []).each do |endpoint|
            @regions << endpoint['region']
          end
        end
        @regions.uniq!
      end
      @regions
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
