describe Elektron::Auth::V3 do
  before :each do
    response = double('response').as_null_object
    allow(response).to receive(:body).and_return(ScopedTokenContext.context)
    allow(response).to receive(:[]).with(
      'x-subject-token'
    ).and_return(ScopedTokenContext.token)

    @client = double('client').as_null_object
    allow(@client).to receive(:post).with('/v3/auth/tokens', anything)
                                    .and_return(response)
    allow(@client).to receive(:get).with('/v3/auth/tokens', anything, anything)
                                   .and_return(response)
    allow(Elektron::HttpClient).to receive(:new).and_return(@client)
  end

  shared_examples 'authentication' do |auth_conf, auth_params|
    it 'should create an auth object' do
      expect(Elektron::Auth::V3.new(auth_conf)).not_to be(nil)
    end

    it 'should call identity api with auth params' do
      expect(Elektron::Auth::V3.new(auth_conf).credentials).to eq(auth_params)
    end

    it 'should call post method on http client' do
      expect(@client).to receive(:post)
      Elektron::Auth::V3.new(auth_conf)
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
      token: 'OS_TOKEN'
    }

    it 'should create an auth object' do
      expect(Elektron::Auth::V3.new(auth_conf)).not_to be(nil)
    end

    it 'should call get method on http client' do
      expect(@client).to receive(:get)
      Elektron::Auth::V3.new(auth_conf)
    end

    it 'should set headers' do
      expect(@client).to receive(:get).with(
        '/v3/auth/tokens',
        {},
        { 'X-Auth-Token' => 'OS_TOKEN', 'X-Subject-Token' => 'OS_TOKEN' })
      Elektron::Auth::V3.new(auth_conf)
    end
  end

  context 'Token authentication with scoped authorization' do
    auth_conf = {
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
