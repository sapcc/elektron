describe Elektron::Auth::V3 do
  let(:request_performer) {
    request_performer = Elektron::Middlewares::Stack.new
    request_performer.add(Elektron::Middlewares::HttpRequestPerformer)
    request_performer.add(Elektron::Middlewares::ResponseErrorHandler)
    request_performer.add(Elektron::Middlewares::ResponseHandler)
    request_performer
  }

  before :each do
    response = double('response').as_null_object
    allow(response).to receive(:body).and_return(ScopedTokenContext.context)
    allow(response).to receive(:header).and_return(
      { 'x-subject-token' => ScopedTokenContext.token }
    )

    allow_any_instance_of(Net::HTTP).to receive(:start).and_return(response)
  end

  shared_examples 'authentication' do |auth_conf, auth_params|
    let(:request) { double('request').as_null_object }

    it 'should create an auth object' do
      expect(Elektron::Auth::V3.new(auth_conf, request_performer)).not_to be(nil)
    end

    it 'should call identity api with auth params' do
      expect(
        Elektron::Auth::V3.new(auth_conf, request_performer).credentials
      ).to eq(auth_params)
    end

    it 'should create net http post request object' do
      expect(Net::HTTP::Post).to receive(:new).with(
        '/v3/auth/tokens',
        {}.merge(Elektron::Middlewares::HttpRequestPerformer::DEFAULT_HEADERS)
          .merge('Content-Type' => 'application/json')
      ).and_return(request)
      Elektron::Auth::V3.new(auth_conf, request_performer)
    end

    it 'should create net http object' do
      expect(Net::HTTP).to receive(:new).with(
        'keystone.api.com', 443, :ENV
      ).and_call_original
      Elektron::Auth::V3.new(auth_conf, request_performer)
    end
  end

  context 'Password authentication with unscoped authorization' do
    context 'user name and domain name are used' do
      auth_conf = {
        url: 'https://keystone.api.com',
        user_name: 'admin',
        password: 'devstacker',
        user_domain_name: 'Default'
      }

      auth_params = {
        'auth' => {
          'identity' => {
            'methods' => [
              'password'
            ],
            'password' => {
              'user' => {
                'name' => 'admin',
                'domain' => {
                  'name' => 'Default'
                },
                'password' => 'devstacker'
              }
            }
          }
        }
      }
      it_behaves_like 'authentication', auth_conf, auth_params
    end

    context 'user name and domain id are used' do
      auth_conf = {
        url: 'https://keystone.api.com',
        user_name: 'admin',
        password: 'devstacker',
        user_domain_id: 'default'
      }

      auth_params = {
        'auth' => {
          'identity' => {
            'methods' => [
              'password'
            ],
            'password' => {
              'user' => {
                'name' => 'admin',
                'domain' => {
                  'id' => 'default'
                },
                'password' => 'devstacker'
              }
            }
          }
        }
      }
      it_behaves_like 'authentication', auth_conf, auth_params
    end

    context 'user id and domain id are used' do
      auth_conf = {
        url: 'https://keystone.api.com',
        user_id: 'ee4dfb6e5540447cb3741905149d9b6e',
        password: 'devstacker',
        user_domain_id: 'default'
      }

      auth_params = {
        'auth' => {
          'identity' => {
            'methods' => [
              'password'
            ],
            'password' => {
              'user' => {
                'id' => 'ee4dfb6e5540447cb3741905149d9b6e',
                'domain' => {
                  'id' => 'default'
                },
                'password' => 'devstacker'
              }
            }
          }
        }
      }
      it_behaves_like 'authentication', auth_conf, auth_params
    end
  end

  context 'Password authentication with scoped authorization' do
    context 'user id and scope project id are given' do
      auth_conf = {
        url: 'https://keystone.api.com',
        user_id: 'ee4dfb6e5540447cb3741905149d9b6e',
        password: 'devstacker',
        user_domain_name: 'Default',
        scope_project_id: 'a6944d763bf64ee6a275f1263fae0352'
      }
      auth_params = {
        'auth' => {
          'identity' => {
            'methods' => [
              'password'
            ],
            'password' => {
              'user' => {
                'id' => 'ee4dfb6e5540447cb3741905149d9b6e',
                'domain' => { 'name' => 'Default'},
                'password' => 'devstacker'
              }
            }
          },
          'scope' => {
            'project' => {
              'id' => 'a6944d763bf64ee6a275f1263fae0352'
            }
          }
        }
      }
      it_behaves_like 'authentication', auth_conf, auth_params
    end

    context 'user id and scope domain name and project name are given' do
      auth_conf = {
        url: 'https://keystone.api.com',
        user_id: 'ee4dfb6e5540447cb3741905149d9b6e',
        password: 'devstacker',
        user_domain_id: 'default',
        scope_project_domain_name: 'Default',
        scope_project_name: 'Test'
      }
      auth_params = {
        'auth' => {
          'identity' => {
            'methods' => [
              'password'
            ],
            'password' => {
              'user' => {
                'domain' => { 'id' => 'default'},
                'password' => 'devstacker',
                'id' => 'ee4dfb6e5540447cb3741905149d9b6e'
              }
            }
          },
          'scope' => {
            'project' => {
              'name' => 'Test',
              'domain' => { 'name' => 'Default' }
            }
          }
        }
      }
      it_behaves_like 'authentication', auth_conf, auth_params
    end
  end

  context 'Password authentication with explicit unscoped authorization' do
    auth_conf = {
      url: 'https://keystone.api.com',
      user_id: 'ee4dfb6e5540447cb3741905149d9b6e',
      password: 'devstacker',
      unscoped: true
    }
    auth_params = {
      'auth' => {
        'identity' => {
          'methods' => [
            'password'
          ],
          'password' => {
            'user' => {
              'id' => 'ee4dfb6e5540447cb3741905149d9b6e',
              'password' => 'devstacker',
              'domain' => {
                'id' => nil
              }
            }
          }
        },
        'scope' => 'unscoped'
      }
    }
    it_behaves_like 'authentication', auth_conf, auth_params
  end

  context 'Token authentication with unscoped authorization' do
    auth_conf = {
      url: 'https://keystone.api.com',
      token: 'OS_TOKEN'
    }

    it 'should create an auth object' do
      expect(Elektron::Auth::V3.new(auth_conf, request_performer)).not_to be(nil)
    end

    it 'should create net http get object' do
      expect(Net::HTTP::Get).to receive(:new).with(
        '/v3/auth/tokens', anything
      )
      Elektron::Auth::V3.new(auth_conf, request_performer)
    end

    it 'should set headers' do
      expect(Net::HTTP::Get).to receive(:new) do |path, headers|
        expect(path).to eq('/v3/auth/tokens')
        expect(headers['X-Auth-Token']).to eq('OS_TOKEN')
        expect(headers['X-Subject-Token']).to eq('OS_TOKEN')
      end
      Elektron::Auth::V3.new(auth_conf, request_performer)
    end
  end

  context 'Token authentication with scoped authorization' do
    auth_conf = {
      url: 'https://keystone.api.com',
      token: 'OS_TOKEN',
      scope_project_id: '5b50efd009b540559104ee3c03bbb2b7'
    }
    auth_params = {
      'auth' => {
        'identity' => {
          'methods' => [
            'token'
          ],
          'token' => {
            'id' => 'OS_TOKEN'
          }
        },
        'scope' => {
          'project' => {
            'id' => '5b50efd009b540559104ee3c03bbb2b7'
          }
        }
      }
    }
    it_behaves_like 'authentication', auth_conf, auth_params
  end

  context 'Token authentication with explicit unscoped authorization' do
    auth_conf = {
      url: 'https://keystone.api.com',
      token: 'OS_TOKEN',
      unscoped: true
    }
    auth_params = {
      'auth' => {
        'identity' => {
          'methods' => [
            'token'
          ],
          'token' => {
            'id' => 'OS_TOKEN'
          }
        },
        'scope' => 'unscoped'
      }
    }
    it_behaves_like 'authentication', auth_conf, auth_params
  end
end
