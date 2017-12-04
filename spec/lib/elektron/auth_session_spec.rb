

describe Elektron::AuthSession do
  it 'auth v3' do
    auth_session = Elektron::AuthSession.new({
      url: 'https://identity-3.staging.cloud.sap/v3',
      user_name: 'dashboard',
      user_domain_name: 'Default',
      password: 'mugs55;Maxus',
      domain_name: 'monsoon3'
    }, {region: 'staging', debug: false})
    domain_id = auth_session.token_context.domain_id
    identity = auth_session.service('identity', path_prefix: '/v3', interface: 'public')
    p identity.get('users', {domain_id: domain_id}).map_to('body.users' => OpenStruct)
  end

  context 'compute service' do
    auth_session = Elektron::AuthSession.new({
      url: 'https://identity-3.staging.cloud.sap/v3',
      user_name: 'D064310',
      user_domain_name: 'monsoon3',
      password: 'Ap302112018',
      project_id: '2fbf16e217d74cec805a4f476b2bc306'
    }, {region: 'staging', debug: true, interface: 'public'})

    compute = auth_session.service('compute', path_prefix: '/v2')

    it 'should list all servers' do
      p compute.get('/:project_id/servers').map_to('body.servers' => OpenStruct)
    end

    it "should create a server" do
      compute.post('/servers') do
        {
          'server' => {
            'name' => 'new-server-test2',
            'imageRef' => '8a7b7785-92df-4168-95c0-85e7b8f1db1a',
            'flavorRef' => '30',
            'availability_zone' => 'stagingb',
            'OS-DCF:diskConfig' => 'AUTO',
            'metadata' => {
              'My Server Name' => 'Apache1'
            },
            'security_groups' => [
              {
                'name' => 'default'
              }
            ],
            'networks' => [{
              'uuid' => '4d622609-2020-4b43-9159-7c238feb0b84'
            }]
          }
        }
      end
    end

    it 'should delete a server' do
      compute.delete("/servers/5342fcd3-1c64-4a97-b0bd-4babdaa4e86c")
    end

    it 'should stop a server' do
      compute.post("/servers/9727689b-884a-4f21-b006-c518ce870176/action") do
        { "os-stop" => nil }
      end
    end

    it 'should start a server' do
      compute.post("/servers/9727689b-884a-4f21-b006-c518ce870176/action") do
        { "os-start" => nil }
      end
    end
  end

  context 'create auth_session from existing one' do
    auth_session = Elektron::AuthSession.new({
      url: 'https://identity-3.staging.cloud.sap/v3',
      user_name: 'dashboard',
      user_domain_name: 'Default',
      password: 'mugs55;Maxus',
      domain_name: 'monsoon3'
    }, {region: 'staging', debug: false})

    it 'should create a new auth session' do
      new_auth_session = Elektron::AuthSession.new({
        token_context: auth_session.token_context.context,
        token: auth_session.token
      },{region: 'staging', debug: true, interface: 'public'})

      p new_auth_session.service('identity', path_prefix: '/v3').get('auth/projects').data
    end
  end
end
