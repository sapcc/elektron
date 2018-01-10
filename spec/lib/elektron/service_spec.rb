describe Elektron::Service do
  let(:auth_session) {
    auth = double('auth V3').as_null_object
    allow(auth).to receive(:context).and_return(ScopedTokenContext.context)
    allow(auth).to receive(:token_value).and_return(ScopedTokenContext.token)
    allow(Elektron::Auth::V3).to receive(:new).and_return(auth)

    Elektron::AuthSession.new({})
  }

  describe '::new' do
    it 'should create a new instance' do
      expect(Elektron::Service.new('identity', auth_session)).not_to be(nil)
    end

    it 'should create a new instance with custom headers' do
      service = Elektron::Service.new(
        'identity', auth_session, headers: { 'X-Test-Request' => 'test' }
      )
      expect(service.instance_variable_get(:@options)[:headers]).to eq(
        { 'X-Test-Request' => 'test' }
      )
    end
  end

  let(:service) {
    Elektron::Service.new('identity', auth_session)
  }

  let(:service_internal) {
    Elektron::Service.new('identity', auth_session, interface: 'internal')
  }

  let(:service_bad) {
    Elektron::Service.new('identity', auth_session, interface: 'bad')
  }

  before :each do
    @http_client = double('http client').as_null_object
    allow(Elektron::HttpClient).to receive(:new).and_return(@http_client)
    @http_client
  end

  describe '#http_client' do
    context 'user credentials provided' do
      before :each do
        @service = Elektron::Service.new('identity', auth_session)
      end

      it 'do not create a new http client' do
        @service.instance_variable_set(:@service_url, 'some url')
        @service.instance_variable_set(:@token, ScopedTokenContext.token)
        expect(Elektron::HttpClient).not_to receive(:new)
        @service.send(:http_client, 'some url')
      end
    end

    context 'no user credentials provided' do
      before :each do
        auth_conf = {
          token_context: ScopedTokenContext.context,
          token: ScopedTokenContext.token
        }
        @auth_session = Elektron::AuthSession.new(auth_conf)
      end

      it 'create a new http client' do
        service = Elektron::Service.new('identity', @auth_session)
        allow(@auth_session).to receive(:expired?).and_return(true)
        expect(Elektron::HttpClient).to receive(:new)
        service.send(:http_client, 'some url')
      end
    end
  end

  describe '#endpoint_url' do
    it 'should return the public endpoint of identity' do
      expect(service.endpoint_url).to eq('http://example.com/identity/public/v2.0')
    end

    it 'should return the internal endpoint of identity' do
      expect(service_internal.endpoint_url).to eq('http://example.com/identity/internal/v2.0')
    end

    it 'should rais an error' do
      expect {
        service_bad.endpoint_url
      }.to raise_error(Elektron::Errors::ServiceEndpointUnavailable)
    end

    context 'options are provided' do
      it 'should return the public endpoint of identity' do
        expect(service.endpoint_url(region: 'RegionOne', interface: 'public'))
          .to eq('http://example.com/identity/public/v2.0')
      end

      it 'should return the internal endpoint of identity' do
        expect(service.endpoint_url(interface: 'internal'))
          .to eq('http://example.com/identity/internal/v2.0')
      end

      it 'should rais an error' do
        expect {
          service.endpoint_url(interface: 'bad')
        }.to raise_error(Elektron::Errors::ServiceEndpointUnavailable)
      end
    end
  end

  describe '#post' do
    it 'should create a new http client' do
      expect(Elektron::HttpClient).to receive(:new)
      service.post('test')
    end

    it 'should not create a new http client' do
      service.post('test')
      expect(Elektron::HttpClient).not_to receive(:new)
      service.post('test')
    end

    it 'should call http client with data' do
      expect(@http_client).to receive(:post) do |path, data|
        expect(path).to eq('/test')
        expect(data).to eq({param1: 'param1'})
      end.and_return(double('response').as_null_object)
      service.post('test', path_prefix: '') do
        {param1: 'param1'}
      end
    end

    it 'should call http client with data and headers' do
      expect(@http_client).to receive(:post) do |path, data, headers|
        expect(path).to eq('/test')
        expect(data).to eq({param1: 'param1'})
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.post('test', {}, headers: {'X-Test-Header' => 'test'}, path_prefix: '' ) do
        {param1: 'param1'}
      end
    end

    it 'should call http client with params, data and headers' do
      expect(@http_client).to receive(:post) do |path, data, headers|
        expect(path).to eq('/test?param1=param1')
        expect(data).to eq({data1: 'test'})
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.post('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '') do
        {data1: 'test'}
      end
    end

    it 'accepts options in params' do
      expect(@http_client).to receive(:post) do |path, data, headers|
        expect(path).to eq('/test?param1=param1')
        expect(data).to eq({data1: 'test'})
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.post('test', param1: 'param1', interface: 'public', headers: {'X-Test-Header' => 'test'}, path_prefix: '') do
        {data1: 'test'}
      end
    end

    it 'should request new token' do
      expect(service.instance_variable_get(:@auth_session)).to receive(:token)
      service.post('test')
    end

    describe 'option path_prefix' do
      it 'should adopt path' do
        expect(@http_client).to receive(:post) do |path, data, headers|
          expect(path).to eq('/test?param1=param1')
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.post('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '') do
          {data1: 'test'}
        end
      end
    end

    context 'path starts with / and path_prefix is nil' do
      it 'should use path as full path' do
        expect(@http_client).to receive(:post) do |path, data, headers|
          expect(path).to eq('/test?param1=param1')
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.post('/test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}) do
          {data1: 'test'}
        end
      end
    end

    context 'path does not start with / and path_prefix is nil' do
      it 'should use path of service url as prefix' do
        expect(@http_client).to receive(:post) do |path, data, headers|
          expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.post('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}) do
          {data1: 'test'}
        end
      end
    end

    context 'path does not start with / and path_prefix is set' do
      it 'should use path prefix' do
        expect(@http_client).to receive(:post) do |path, data, headers|
          expect(path).to eq("/test/test?param1=param1")
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.post('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '/test') do
          {data1: 'test'}
        end
      end

      it 'should set prefix to /' do
        expect(@http_client).to receive(:post) do |path, data, headers|
          expect(path).to eq("/test?param1=param1")
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.post('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '') do
          {data1: 'test'}
        end
      end
    end

    context 'overwrite default headers' do
      before :each do
        allow(Elektron::HttpClient).to receive(:new).and_call_original
        allow_any_instance_of(Elektron::HttpClient).to receive(
          :perform
        ).and_return(double('response', body: 'test'))
      end

      it 'should overwrite the default content type' do
        expect(Net::HTTP::Post).to receive(:new) do |_path, headers|
          expect(headers['Content-Type']).to eq(
            'application/openstack-images-v2.1-json-patch'
          )
        end

        service.post(
          'test', {}, headers: {
            'Content-Type' => 'application/openstack-images-v2.1-json-patch'
          }
        )
      end
    end
  end

  describe '#put' do
    it 'should create a new http client' do
      expect(Elektron::HttpClient).to receive(:new)
      service.put('test')
    end

    it 'should not create a new http client' do
      service.put('test')
      expect(Elektron::HttpClient).not_to receive(:new)
      service.put('test')
    end

    it 'should call http client with data' do
      expect(@http_client).to receive(:put) do |path, data|
        expect(path).to eq('/test')
        expect(data).to eq({param1: 'param1'})
      end.and_return(double('response').as_null_object)
      service.put('test', path_prefix: '') do
        {param1: 'param1'}
      end
    end

    it 'should call http client with data and headers' do
      expect(@http_client).to receive(:put) do |path, data, headers|
        expect(path).to eq('/test')
        expect(data).to eq({param1: 'param1'})
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.put('test', {}, headers: {'X-Test-Header' => 'test'}, path_prefix: '') do
        {param1: 'param1'}
      end
    end

    it 'should call http client with params, data and headers' do
      expect(@http_client).to receive(:put) do |path, data, headers|
        expect(path).to eq('/test?param1=param1')
        expect(data).to eq({data1: 'test'})
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.put('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '') do
        {data1: 'test'}
      end
    end

    it 'should call http client with params, data and headers' do
      expect(@http_client).to receive(:put) do |path, data, headers|
        expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
        expect(data).to eq({data1: 'test'})
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.put('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}) do
        {data1: 'test'}
      end
    end

    context 'path starts with / and path_prefix is nil' do
      it 'should use path as full path' do
        expect(@http_client).to receive(:put) do |path, data, headers|
          expect(path).to eq('/test?param1=param1')
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.put('/test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}) do
          {data1: 'test'}
        end
      end
    end

    context 'path does not start with / and path_prefix is nil' do
      it 'should use path of service url as prefix' do
        expect(@http_client).to receive(:put) do |path, data, headers|
          expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.put('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}) do
          {data1: 'test'}
        end
      end
    end

    context 'path does not start with / and path_prefix is set' do
      it 'should use path prefix' do
        expect(@http_client).to receive(:put) do |path, data, headers|
          expect(path).to eq("/test/test?param1=param1")
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.put('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '/test') do
          {data1: 'test'}
        end
      end

      it 'should set prefix to /' do
        expect(@http_client).to receive(:put) do |path, data, headers|
          expect(path).to eq("/test?param1=param1")
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.put('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '') do
          {data1: 'test'}
        end
      end
    end

    context 'overwrite default headers' do
      before :each do
        allow(Elektron::HttpClient).to receive(:new).and_call_original
        allow_any_instance_of(Elektron::HttpClient).to receive(
          :perform
        ).and_return(double('response', body: 'test'))
      end

      it 'should overwrite the default content type' do
        expect(Net::HTTP::Put).to receive(:new) do |_path, headers|
          expect(headers['Content-Type']).to eq(
            'application/openstack-images-v2.1-json-patch'
          )
        end

        service.put(
          'test', {}, headers: {
            'Content-Type' => 'application/openstack-images-v2.1-json-patch'
          }
        )
      end
    end
  end

  describe '#patch' do
    it 'should create a new http client' do
      expect(Elektron::HttpClient).to receive(:new)
      service.patch('test')
    end

    it 'should not create a new http client' do
      service.patch('test')
      expect(Elektron::HttpClient).not_to receive(:new)
      service.patch('test')
    end

    it 'should call http client with data' do
      expect(@http_client).to receive(:patch) do |path, data|
        expect(path).to eq('/test')
        expect(data).to eq({param1: 'param1'})
      end.and_return(double('response').as_null_object)
      service.patch('test', path_prefix: '') do
        {param1: 'param1'}
      end
    end

    it 'should call http client with data and headers' do
      expect(@http_client).to receive(:patch) do |path, data, headers|
        expect(path).to eq('/test')
        expect(data).to eq({param1: 'param1'})
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.patch('test', {}, headers: {'X-Test-Header' => 'test'}, path_prefix: '') do
        {param1: 'param1'}
      end
    end

    it 'should call http client with params, data and headers' do
      expect(@http_client).to receive(:patch) do |path, data, headers|
        expect(path).to eq('/test?param1=param1')
        expect(data).to eq({data1: 'test'})
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.patch('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '') do
        {data1: 'test'}
      end
    end

    it 'should build path including original path_prefix' do
      expect(@http_client).to receive(:patch) do |path, data, headers|
        expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
        expect(data).to eq({data1: 'test'})
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.patch('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}) do
        {data1: 'test'}
      end
    end

    context 'path starts with / and path_prefix is nil' do
      it 'should use path as full path' do
        expect(@http_client).to receive(:patch) do |path, data, headers|
          expect(path).to eq('/test?param1=param1')
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.patch('/test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}) do
          {data1: 'test'}
        end
      end
    end

    context 'path does not start with / and path_prefix is nil' do
      it 'should use path of service url as prefix' do
        expect(@http_client).to receive(:patch) do |path, data, headers|
          expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.patch('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}) do
          {data1: 'test'}
        end
      end
    end

    context 'path does not start with / and path_prefix is set' do
      it 'should use path prefix' do
        expect(@http_client).to receive(:patch) do |path, data, headers|
          expect(path).to eq("/test/test?param1=param1")
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.patch('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '/test') do
          {data1: 'test'}
        end
      end

      it 'should set prefix to /' do
        expect(@http_client).to receive(:patch) do |path, data, headers|
          expect(path).to eq("/test?param1=param1")
          expect(data).to eq({data1: 'test'})
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.patch('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '') do
          { data1: 'test' }
        end
      end

      context 'overwrite default headers' do
        before :each do
          allow(Elektron::HttpClient).to receive(:new).and_call_original
          allow_any_instance_of(Elektron::HttpClient).to receive(
            :perform
          ).and_return(double('response', body: 'test'))
        end

        it 'should overwrite the default content type' do
          expect(Net::HTTP::Patch).to receive(:new) do |_path, headers|
            expect(headers['Content-Type']).to eq(
              'application/openstack-images-v2.1-json-patch'
            )
          end

          service.patch(
            'test', {}, headers: {
              'Content-Type' => 'application/openstack-images-v2.1-json-patch'
            }
          )
        end
      end
    end
  end

  describe '#get' do
    it 'should call a get with custom headers' do
      expect(@http_client).to receive(:get) do |path, headers|
        expect(headers['Accept']).to eq('text/plain')
      end.and_return(double('response').as_null_object)
      service.get('test', headers: { 'Accept' => 'text/plain'})
    end

    it 'should create a new http client' do
      expect(Elektron::HttpClient).to receive(:new)
      service.get('test')
    end

    it 'should not create a new http client' do
      service.get('test')
      expect(Elektron::HttpClient).not_to receive(:new)
      service.get('test')
    end

    it 'should call http client with params' do
      expect(@http_client).to receive(:get) do |path|
        expect(path).to eq('/test?param1=param1')
      end.and_return(double('response').as_null_object)
      service.get('test', {param1: 'param1'}, path_prefix: '')
    end

    it 'should call http client with params and headers' do
      expect(@http_client).to receive(:get) do |path, headers|
        expect(path).to eq('/test?param1=param1')
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.get('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '')
    end

    it 'should build path including original path_prefix' do
      expect(@http_client).to receive(:get) do |path, headers|
        expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.get('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'})
    end

    context 'path starts with / and path_prefix is nil' do
      it 'should use path as full path' do
        expect(@http_client).to receive(:get) do |path, headers|
          expect(path).to eq('/test?param1=param1')
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.get('/test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'})
      end
    end

    context 'path does not start with / and path_prefix is nil' do
      it 'should use path of service url as prefix' do
        expect(@http_client).to receive(:get) do |path, headers|
          expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.get('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'})
      end
    end

    context 'path does not start with / and path_prefix is set' do
      it 'should use path prefix' do
        expect(@http_client).to receive(:get) do |path, headers|
          expect(path).to eq("/test/test?param1=param1")
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.get('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '/test')
      end

      it 'should set prefix to /' do
        expect(@http_client).to receive(:get) do |path, headers|
          expect(path).to eq("/test?param1=param1")
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.get('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '')
      end
    end

    context 'path starts with http' do
      it 'should use path as full_path' do
        expect(@http_client).to receive(:get) do |path, headers|
          expect(path).to eq("http://test.com/test?param1=param1")
        end.and_return(double('response').as_null_object)
        service.get('http://test.com/test', {param1: 'param1'})
      end

      it 'should ignore path_prefix' do
        expect(@http_client).to receive(:get) do |path, headers|
          expect(path).to eq("http://test.com/test?param1=param1")
        end.and_return(double('response').as_null_object)
        service.get('http://test.com/test', {param1: 'param1'}, path_prefix: '/test')
      end

      it 'should accept http as param' do
        expect(@http_client).to receive(:get) do |path, headers|
          expect(path).to eq("/test/test?#{URI.encode_www_form({param1: 'http://test.com'})}")
        end.and_return(double('response').as_null_object)
        service.get('test', {param1: 'http://test.com'}, path_prefix: '/test')
      end
    end
  end

  describe '#delete' do
    it 'should create a new http client' do
      expect(Elektron::HttpClient).to receive(:new)
      service.delete('test')
    end

    it 'should not create a new http client' do
      service.delete('test')
      expect(Elektron::HttpClient).not_to receive(:new)
      service.delete('test')
    end

    it 'should call http client with params' do
      expect(@http_client).to receive(:delete) do |path|
        expect(path).to eq('/test?param1=param1')
      end.and_return(double('response').as_null_object)
      service.delete('test', {param1: 'param1'}, path_prefix: '')
    end

    it 'should call http client with params and headers' do
      expect(@http_client).to receive(:delete) do |path, headers|
        expect(path).to eq('/test?param1=param1')
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.delete('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '')
    end

    it 'should build path including original path_prefix' do
      expect(@http_client).to receive(:delete) do |path, headers|
        expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.delete('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'})
    end


    context 'path starts with / and path_prefix is nil' do
      it 'should use path as full path' do
        expect(@http_client).to receive(:delete) do |path, headers|
          expect(path).to eq('/test?param1=param1')
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.delete('/test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'})
      end
    end

    context 'path does not start with / and path_prefix is nil' do
      it 'should use path of service url as prefix' do
        expect(@http_client).to receive(:delete) do |path, headers|
          expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.delete('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'})
      end
    end

    context 'path does not start with / and path_prefix is set' do
      it 'should use path prefix' do
        expect(@http_client).to receive(:delete) do |path, headers|
          expect(path).to eq("/test/test?param1=param1")
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.delete('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '/test')
      end

      it 'should set prefix to /' do
        expect(@http_client).to receive(:delete) do |path, headers|
          expect(path).to eq("/test?param1=param1")
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.delete('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '')
      end
    end
  end

  describe '#options' do
    it 'should create a new http client' do
      expect(Elektron::HttpClient).to receive(:new)
      service.options('test')
    end

    it 'should not create a new http client' do
      service.options('test')
      expect(Elektron::HttpClient).not_to receive(:new)
      service.options('test')
    end

    it 'should call http client with params' do
      expect(@http_client).to receive(:options) do |path|
        expect(path).to eq('/test?param1=param1')
      end.and_return(double('response').as_null_object)
      service.options('test', {param1: 'param1'}, path_prefix: '')
    end

    it 'should call http client with params and headers' do
      expect(@http_client).to receive(:options) do |path, headers|
        expect(path).to eq('/test?param1=param1')
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.options('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '')
    end

    it 'should build path including original path_prefix' do
      expect(@http_client).to receive(:options) do |path, headers|
        expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
        expect(headers).to eq({'X-Test-Header' => 'test'})
      end.and_return(double('response').as_null_object)
      service.options('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'})
    end


    context 'path starts with / and path_prefix is nil' do
      it 'should use path as full path' do
        expect(@http_client).to receive(:options) do |path, headers|
          expect(path).to eq('/test?param1=param1')
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.options('/test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'})
      end
    end

    context 'path does not start with / and path_prefix is nil' do
      it 'should use path of service url as prefix' do
        expect(@http_client).to receive(:options) do |path, headers|
          expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.options('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'})
      end
    end

    context 'path does not start with / and path_prefix is set' do
      it 'should use path prefix' do
        expect(@http_client).to receive(:options) do |path, headers|
          expect(path).to eq("/test/test?param1=param1")
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.options('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '/test')
      end

      it 'should set prefix to /' do
        expect(@http_client).to receive(:options) do |path, headers|
          expect(path).to eq("/test?param1=param1")
          expect(headers).to eq({'X-Test-Header' => 'test'})
        end.and_return(double('response').as_null_object)
        service.options('test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '')
      end
    end
  end

  describe 'middlewares' do
    it 'should response to add_middleware' do
      expect(service).to respond_to(:add_middleware)
    end

    describe '#add_middleware' do
      before :each do
        @middlewares = service.instance_variable_get(:@middlewares)
      end

      it 'should add a new middleware' do
        expect {
          service.add_middleware { |params, options, data| }
        }.to change(@middlewares, :length).by(1)
      end

      it 'should not add a new middleware' do
        expect {
          service.add_middleware
        }.to raise_error(Elektron::Errors::BadMiddleware)
      end

      it 'should return true' do
        expect(service.add_middleware {}).to eq(true)
      end

      it 'should accept proc as parameter' do
        middleware = proc { |p, o, d| }

        expect {
          service.add_middleware(middleware)
        }.to change(@middlewares, :length).by(1)
      end

      it 'should accept object as parameter' do
        class TestMiddleware
          def call(p, o, d); end
        end

        expect {
          service.add_middleware(TestMiddleware.new)
        }.to change(@middlewares, :length).by(1)
      end
    end

    describe 'execute middlewares' do
      before :each do
        @service = Elektron::Service.new('identity', auth_session)
        @service_http_client = double('http client').as_null_object
        allow(Elektron::HttpClient).to receive(:new).and_return(@service_http_client)
      end

      context 'modify parameters' do
        before :each do
          @service.add_middleware do |params, options, data|
            options[:headers] ||= {}
            options[:headers].merge!('X-TEST' => 'test')

            [
              params.merge(test: true),
              options,
              (data || {}).merge('item' => 'test')
            ]
          end

          @service.post('auth/tokens', {}, headers: { 'X-Auth-Token' => 'TOKEN' }) do
            { 'token' => 'TOKEN' }
          end
        end

        it 'should pass modified params to http_client' do
          expect(@service_http_client).to have_received(:post).with(
            "#{URI(service.endpoint_url).path}/auth/tokens?test=true",
            { 'token' => 'TOKEN', 'item' => 'test' },
            { 'X-Auth-Token' => 'TOKEN', 'X-TEST' => 'test' }
          )
        end
      end

      context 'overwrite parameters' do
        before :each do
          @service.add_middleware do |params, options, data|
            [{ test: true }, { headers: { 'X-Auth-Token' => 'TEST' } }, nil]
          end

          @service.get('auth/tokens', param1: 'param1')
        end

        it 'should pass modified params to http_client' do
          expect(@service_http_client).to have_received(:get).with(
            "#{URI(service.endpoint_url).path}/auth/tokens?test=true",
            { 'X-Auth-Token' => 'TEST' }
          )
        end
      end
    end
  end

  describe Elektron::Service::ApiResponse do
    let(:response) do
      double(
        'response',
        body: {
          'users' => [
            { 'id' => 1, 'name' => 'test1' },
            { 'id' => 2, 'name' => 'test2' }
          ]
        }
      )
    end

    let(:api_response) { Elektron::Service::ApiResponse.new(response) }

    describe '#map_to' do
      context 'map body to an object' do
        let(:mapped_response) { api_response.map_to('body' => OpenStruct) }

        it 'mapped response is an OpenStruct' do
          expect(mapped_response.class).to be(OpenStruct)
        end

        it 'mapped response contains an array' do
          expect(mapped_response.users.class).to be(Array)
        end

        it 'mapped response contains an array of hashes' do
          expect(mapped_response.users.first.class).to be(Hash)
        end
      end

      context 'map body.users to an array of objects' do
        class User < OpenStruct; end
        let(:mapped_response) { api_response.map_to('body.users' => User) }

        it 'mapped response is an Array' do
          expect(mapped_response.class).to be(Array)
        end

        it 'mapped response is an array of User objects' do
          expect(mapped_response.first.class).to be(User)
        end

        it 'mapped objects contains id attribute' do
          expect(mapped_response.first.id).to eq(1)
        end

        it 'mapped objects contains name attribute' do
          expect(mapped_response.first.name).to eq('test1')
        end
      end

      context 'mapping key does not exist' do
        let(:mapped_response) { api_response.map_to('body.bad_key' => OpenStruct) }

        it 'mapped response is an Array' do
          expect(mapped_response).to be(nil)
        end
      end

      context 'map using block' do
        class User < OpenStruct; end
        let(:mapped_response) {
          api_response.map_to('body.users') do |params|
            User.new(params)
          end
        }

        it 'mapped response is an Array' do
          expect(mapped_response.class).to be(Array)
        end

        it 'mapped response is an array of User objects' do
          expect(mapped_response.first.class).to be(User)
        end

        it 'mapped objects contains id attribute' do
          expect(mapped_response.first.id).to eq(1)
        end

        it 'mapped objects contains name attribute' do
          expect(mapped_response.first.name).to eq('test1')
        end
      end
    end
  end
end
