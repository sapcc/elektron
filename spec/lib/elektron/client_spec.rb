describe Elektron::Client do
  auth_conf = {
    url: 'https://identity.test.com',
    user_name: 'test',
    user_domain_name: 'Default',
    password: 'test',
    domain_name: 'Default'
  }

  let(:request_performer) {
    double('middlewares stack').as_null_object
  }

  options = {
    region: 'RegionOne', interface: 'public', debug: false,
    headers: {}, http_client: {}, path_prefix: nil
  }

  describe '::new' do
    before :each do
      allow(Elektron::Auth::Session).to receive(:new)
      @client = Elektron.client(auth_conf, options)
    end

    it 'crates a new instance of auth session' do
      expect(Elektron::Auth::Session).to have_received(:new).with(
        auth_conf, kind_of(Elektron::Middlewares::Stack), options
      )
    end

    it 'creates a new client instance' do
      expect(@client).not_to be(nil)
    end

    it 'creates an instance of Elektron::Client' do
      expect(@client.class).to be(Elektron::Client)
    end
  end

  describe '#service' do
    let(:client) do
      Elektron.client(
        {
          token_context: ScopedTokenContext.context,
          token: ScopedTokenContext.token
        },
        options
      )
    end

    it 'returns an instance of Elektron::Service' do
      expect(client.service('identity').class).to be(Elektron::Service)
    end

    it 'returns a the identity endpoint' do
      expect(
        client.service('identity').endpoint_url =~ /identity\/public/
      ).not_to be(nil)
    end

    it 'returns a the internal identity endpoint' do
      expect(
        client.service('identity', interface: 'internal').endpoint_url =~ /identity\/internal/
      ).not_to be(nil)
    end

    it 'returns a the admin identity endpoint' do
      expect(
        client.service('identity', interface: 'admin').endpoint_url =~ /identity\/admin/
      ).not_to be(nil)
    end

    it 'raises an error for unknown region' do
      expect{
        client.service('identity', region: 'bad').endpoint_url
      }.to raise_error(Elektron::Errors::ServiceEndpointUnavailable)
    end
  end

  describe 'token_context methods' do
    shared_examples 'delegated method' do |method, params = nil|
      let(:client) do
        Elektron.client(
          {
            token_context: ScopedTokenContext.context,
            token: ScopedTokenContext.token
          },
          options
        )
      end

      let(:auth_session) {
        client.instance_variable_get(:@auth_session)
      }

      it "calls #{method} on auth_session" do
        expect(auth_session).to receive(method)
        params ? client.send(method, params) : client.send(method)
      end
    end

    [
      :user_id, :user_name, :is_admin_project?,
      :user_description, :user_domain_id, :user_domain_name,
      :domain_id, :domain_name, :project_id, :project_name,
      :project_parent_id, :project_domain_id, :project_domain_name,
      :expires_at, :expired?, :issued_at, :catalog,
      :roles, :role_names, :available_services_regions, :token
    ].each do |m|
      describe "##{m}" do
        it_behaves_like 'delegated method', m
      end
    end

    [
      :service?, :has_role?, :service_url
    ].each do |m|
      describe "##{m}" do
        it_behaves_like 'delegated method', m, 'test'
      end
    end
  end
end
