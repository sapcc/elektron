describe Elektron::TokenContext do
  let(:token_context) do
    Class.new do
      include Elektron::TokenContext
      def initialize
        current_context(ScopedTokenContext.context)
      end
    end.new
  end

  describe '#current_context' do
    it 'should cache value' do
      user_name = token_context.user_name
      expect(
        token_context.instance_variable_get(:@token_values)[:user_name]
      ).to eq(user_name)
    end

    it 'should reset token context' do
      token_context.user_name
      token_context.current_context(ScopedTokenContext.context)
      expect(
        token_context.instance_variable_get(:@token_values)[:user_name]
      ).to be(nil)
    end
  end

  describe 'available methods' do
    it 'responds to is_admin_project?' do
      expect(token_context).to respond_to(:is_admin_project?)
    end

    it 'responds to user_id' do
      expect(token_context).to respond_to(:user_id)
    end

    it 'responds to user_name' do
      expect(token_context).to respond_to(:user_name)
    end

    it 'responds to user_description' do
      expect(token_context).to respond_to(:user_description)
    end

    it 'responds to user_domain_id' do
      expect(token_context).to respond_to(:user_domain_id)
    end

    it 'responds to user_domain_name' do
      expect(token_context).to respond_to(:user_domain_name)
    end

    it 'responds to domain_id' do
      expect(token_context).to respond_to(:domain_id)
    end

    it 'responds to domain_name' do
      expect(token_context).to respond_to(:domain_name)
    end

    it 'responds to project_id' do
      expect(token_context).to respond_to(:project_id)
    end

    it 'responds to project_name' do
      expect(token_context).to respond_to(:project_name)
    end

    it 'responds to project_parent_id' do
      expect(token_context).to respond_to(:project_parent_id)
    end

    it 'responds to project_domain_id' do
      expect(token_context).to respond_to(:project_domain_id)
    end

    it 'responds to project_domain_name' do
      expect(token_context).to respond_to(:project_domain_name)
    end

    it 'responds to project' do
      expect(token_context).to respond_to(:project)
    end

    it 'responds to domain' do
      expect(token_context).to respond_to(:domain)
    end

    it 'responds to expires_at' do
      expect(token_context).to respond_to(:expires_at)
    end

    it 'responds to expired?' do
      expect(token_context).to respond_to(:expired?)
    end

    it 'responds to issued_at' do
      expect(token_context).to respond_to(:issued_at)
    end

    it 'responds to catalog' do
      expect(token_context).to respond_to(:catalog)
    end

    it 'responds to service?' do
      expect(token_context).to respond_to(:service?)
    end

    it 'responds to roles' do
      expect(token_context).to respond_to(:roles)
    end

    it 'responds to role_names' do
      expect(token_context).to respond_to(:role_names)
    end

    it 'responds to has_role?' do
      expect(token_context).to respond_to(:has_role?)
    end

    it 'responds to service_url' do
      expect(token_context).to respond_to(:service_url)
    end

    # Returns list of unique region name values found in service catalog
    it 'responds to available_services_regions' do
      expect(token_context).to respond_to(:available_services_regions)
    end
  end

  context 'scoped token' do
    let(:context) {
      token_context.instance_variable_get(:@context)
    }

    shared_examples 'boolean token attribute' do |method, token_key|
      it 'returns a boolean value' do
        expect(
          [TrueClass, FalseClass].include?(token_context.send(method).class)
        ).to eq(true)
      end

      it 'returns true' do
        context[token_key] = true
        expect(token_context.send(method)).to eq(true)
      end

      it 'returns false' do
        context[token_key] = false
        expect(token_context.send(method)).to eq(false)
      end

      if token_key
        it 'should return value from token_context' do
          token_keys = token_key.to_s.split('.')
          value = ScopedTokenContext.context['token']
          token_keys.each { |key| value = value[key] if value }
          expect(token_context.send(method)).to eq(value==true)
        end
      end
    end

    shared_examples 'token attribute' do |method, token_key, options = {}|
      it "returns #{method}" do
        token_keys = token_key.to_s.split('.')
        value = ScopedTokenContext.context['token']
        token_keys.each { |key| value = value[key] if value }

        expect(token_context.send(method)).to eq(value)
      end

      if options[:expected_value]
        it "should return #{options[:expected_value]}" do
          expect(token_context.send(method)).not_to be(options[:expected_value])
        end
      end
    end

    shared_examples 'time object' do |method, options = {}|
      it 'should return Time object' do
        expect(token_context.send(method).class).to be(Time)
      end

      if options[:expected_value]
        it "should return #{options[:expected_value]}" do
          expect(token_context.send(method)).to eq(options[:expected_value])
        end
      end
    end

    describe '#is_admin_project?' do
      it_behaves_like 'boolean token attribute', :is_admin_project?, 'is_admin_project'
    end

    describe '#user_id' do
      it_behaves_like 'token attribute', :user_id, 'user.id'
    end

    describe '#user_name' do
      it_behaves_like 'token attribute', :user_name, 'user.name'
    end

    describe '#user_description' do
      it_behaves_like 'token attribute', :user_description, 'user.description'
    end

    describe '#user_domain_id' do
      it_behaves_like 'token attribute', :user_domain_id, 'user.domain.id'
    end

    describe '#user_domain_name' do
      it_behaves_like 'token attribute', :user_domain_name, 'user.domain.name'
    end

    describe '#domain_id' do
      it_behaves_like 'token attribute', :domain_id, 'domain.id'
    end

    describe '#domain_name' do
      it_behaves_like 'token attribute', :domain_name, 'domain.name'
    end

    describe '#project_id' do
      it_behaves_like 'token attribute', :project_id, 'project.id'
    end

    describe '#project_name' do
      it_behaves_like 'token attribute', :project_name, 'project.name'
    end

    describe '#project_parent_id' do
      it_behaves_like 'token attribute', :project_parent_id, 'project.parent_id'
    end

    describe '#project_domain_id' do
      it_behaves_like 'token attribute', :project_domain_id, 'project.domain.id'
    end

    describe '#project_domain_name' do
      it_behaves_like 'token attribute', :project_domain_name, 'project.domain.name'
    end

    describe '#project' do
      it_behaves_like 'token attribute', :project, 'project'
    end

    describe '#domain' do
      it_behaves_like 'token attribute', :domain, 'domain'
    end

    describe '#expires_at' do
      value = DateTime.parse(
        ScopedTokenContext.context['token']['expires_at']
      ).to_time

      it_behaves_like 'time object', :expires_at, expected_value: value
    end

    describe '#expired?' do
      it 'should return true' do
        context['expires_at'] = (Time.now-100).to_s
        expect(token_context.expired?).to eq(true)
      end

      it 'should return false' do
        context['expires_at'] = (Time.now+100).to_s
        expect(token_context.expired?).to eq(false)
      end
    end

    describe '#issued_at' do
      value = DateTime.parse(
        ScopedTokenContext.context['token']['issued_at']
      ).to_time

      it_behaves_like 'time object', :issued_at, expected_value: value
    end

    describe '#catalog' do
      it_behaves_like 'token attribute', :catalog, 'catalog'
    end

    describe '#service?' do
      it 'should return false' do
        expect(token_context.service?('test')).to eq(false)
      end

      it 'should return true' do
        service = ScopedTokenContext.context['token']['catalog'].first
        expect(token_context.service?(service['name'])).to eq(true)
      end

      it 'should find service by type' do
        service = ScopedTokenContext.context['token']['catalog'].first
        expect(token_context.service?(service['type'])).to eq(true)
      end
    end

    describe '#roles' do
      it_behaves_like 'token attribute', :roles, 'roles'
      it 'should return an array' do
        expect(token_context.roles.class).to be(Array)
      end

      it 'length of array is the same like in token context' do
        expect(token_context.roles.length).to eq(
          ScopedTokenContext.context['token']['roles'].length
        )
      end
    end

    describe '#role_names' do
      it 'returns names of roles' do
        expect(token_context.role_names).to eq(
          ScopedTokenContext.context['token']['roles'].collect { |r| r['name']}
        )
      end
    end

    describe '#has_role?' do
      it 'returns true' do
        expect(token_context.has_role?('admin')).to eq(true)
      end

      it 'returns false' do
        expect(token_context.has_role?('test')).to eq(false)
      end
    end

    describe '#service_url' do
      it 'returns the public url of identity' do
        expect(token_context.service_url('identity')).to eq(
          'http://example.com/identity/public/v2.0'
        )
      end

      it 'returns the internal url of identity' do
        expect(token_context.service_url('identity', interface: 'internal')).to eq(
          'http://example.com/identity/internal/v2.0'
        )
      end

      it 'returns the admin url of identity' do
        expect(token_context.service_url('identity', interface: 'admin')).to eq(
          'http://example.com/identity/admin/v2.0'
        )
      end

      it 'returns nil for unknown region' do
        expect(token_context.service_url('identity', region: 'test')).to be(nil)
      end
    end

    describe '#available_services_regions' do
      it 'returns an array of regions' do
        expect(token_context.available_services_regions.class).to be(Array)
      end

      it 'contains all available regions' do
        expect(token_context.available_services_regions).to eq(['RegionOne'])
      end
    end
  end
end
