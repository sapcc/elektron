describe Elektron::Auth::V3 do
  shared_examples 'authentication' do |auth_conf, auth_params|
    it 'should create an auth object' do
      expect(Elektron::Auth::V3.new(auth_conf)).not_to be(nil)
    end

    it 'should call identity api with auth params' do
      expect(Elektron::Auth:V3.auth_params(auth_conf)).to eq(auth_params)
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
      include_examples 'authentication', auth_conf, auth_params
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
      include_examples 'authentication', auth_conf, auth_params
    end

    context 'user id and domain id are used' do
      auth_conf = {
        user_name: 'ee4dfb6e5540447cb3741905149d9b6e',
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
      include_examples 'authentication', auth_conf, auth_params
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
      include_examples 'authentication', auth_conf, auth_params
    end

    context 'user id and scope domain name and project name are given' do
      auth_conf = {
        user_id: 'ee4dfb6e5540447cb3741905149d9b6e',
        password: 'devstacker',
        user_domain_id: 'default',
        scope_domain_name: 'Default',
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
                'id' => 'ee4dfb6e5540447cb3741905149d9b6e',
                'domain' => { 'id' => 'default'},
                'password' => 'devstacker'
              }
            }
          },
          'scope' => {
            'project' => {
              'name' => 'Test',
              'domain' => { 'id' => 'default' }
            }
          }
        }
      }
      include_examples 'authentication', auth_conf, auth_params
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
              'password' => 'devstacker'
            }
          }
        },
        'scope' => 'unscoped'
      }
    }
    include_examples 'authentication', auth_conf, auth_params
  end

  context 'Token authentication with unscoped authorization' do
    auth_conf = {
      token: 'OS_TOKEN'
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
        }
      }
    }
    include_examples 'authentication', auth_conf, auth_params
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
    include_examples 'authentication', auth_conf, auth_params
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
    include_examples 'authentication', auth
  end
end
