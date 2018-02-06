describe Elektron::Service do
  let(:request_performer) {
    request_performer = Elektron::Middlewares::Stack.new
    request_performer.add(Elektron::Middlewares::HttpRequestPerformer)
    request_performer.add(Elektron::Middlewares::ResponseErrorHandler)
    request_performer.add(Elektron::Middlewares::ResponseHandler)
    request_performer
  }

  let(:auth_session) {
    auth = double('auth V3').as_null_object
    allow(auth).to receive(:context).and_return(ScopedTokenContext.context)
    allow(auth).to receive(:token_value).and_return(ScopedTokenContext.token)
    allow(Elektron::Auth::V3).to receive(:new).and_return(auth)

    Elektron::Auth::Session.new({}, request_performer)
  }

  let(:response) {
    response = double('response', code: 200, header: {}, body: "{}")
    allow(response).to receive(:body=)
    allow(response).to receive(:content_type).and_return('application/json')
    response
  }

  describe '::new' do
    it 'should create a new instance' do
      expect(
        Elektron::Service.new(
          'identity', auth_session, request_performer
        )
      ).not_to be(nil)
    end

    it 'should create a new instance with custom headers' do
      service = Elektron::Service.new(
        'identity', auth_session, request_performer,
        headers: { 'X-Test-Request' => 'test' }
      )
      expect(service.instance_variable_get(:@options)[:headers]).to eq(
        { 'X-Test-Request' => 'test' }
      )
    end
  end

  let(:service) {
    Elektron::Service.new('identity', auth_session, request_performer)
  }

  let(:service_internal) {
    Elektron::Service.new(
      'identity', auth_session, request_performer, interface: 'internal'
    )
  }

  let(:service_bad) {
    Elektron::Service.new(
      'identity', auth_session, request_performer, interface: 'bad'
    )
  }

  let(:identity_url) {
    catalog = ScopedTokenContext.context['token']['catalog']
    service = catalog.find{ |service| service['type'] == 'identity' }
    endpoint = service['endpoints'].find { |endpoint| endpoint['interface'] == 'public' }
    endpoint['url']
  }

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

  before :each do
    allow_any_instance_of(Net::HTTP).to receive(:start).and_return(response)
  end

  shared_examples 'request without data' do |http_method|
    http_method = :get
    klazz = Object.const_get("Net::HTTP::#{http_method.capitalize}")

    before :each do
      @request = double('request').as_null_object
      allow(klazz).to receive(:new).and_return(@request)
    end

    it "should create a #{http_method} request with custom headers" do
      expect(klazz).to receive(:new) do |_path, headers|
        expect(headers['Accept']).to eq('text/plain')
      end.and_return(response)

      service.send(http_method, 'test', headers: { 'Accept' => 'text/plain'})
    end

    it "should create a new #{http_method} request" do
      expect(klazz).to receive(:new)
      service.send(http_method, 'test')
    end

    it "should create #{http_method} request with params" do
      expect(klazz).to receive(:new) do |path, _headers|
        expect(path).to eq('/test?param1=param1')
      end
      service.send(http_method, 'test', { param1: 'param1' }, path_prefix: '/')
    end

    it "should create #{http_method} request with params and headers" do
      expect(klazz).to receive(:new) do |path, headers|
        expect(path).to eq('/test?param1=param1')
        expect(headers['X-Test-Header']).to eq('test')
      end
      service.send(http_method,
        'test',
        { param1: 'param1' },
        headers: { 'X-Test-Header' => 'test' },
        path_prefix: '/'
      )
    end

    it "should build path including original path_prefix" do
      expect(klazz).to receive(:new) do |path, headers|
        expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
        expect(headers['X-Test-Header']).to eq('test')
      end.and_return(response)
      service.send(http_method, 'test', { param1: 'param1' }, headers: { 'X-Test-Header' => 'test' })
    end

    context 'path_prefix starts with /' do
      it 'should use path as full path' do
        expect(klazz).to receive(:new) do |path, headers|
          expect(path).to eq('/test?param1=param1')
          expect(headers['X-Test-Header']).to eq('test')
        end.and_return(response)
        service.send(http_method, '/test', { param1: 'param1' }, headers: { 'X-Test-Header' => 'test' }, path_prefix: '/')
      end
    end

    context 'path_prefix is nil' do
      it 'should use path of service url as prefix' do
        expect(klazz).to receive(:new) do |path, headers|
          expect(path).to eq("#{URI(service.endpoint_url).path}/test?param1=param1")
          expect(headers['X-Test-Header']).to eq('test')
        end.and_return(response)
        service.send(http_method, '/test', { param1: 'param1' }, headers: { 'X-Test-Header' => 'test' }, path_prefix: nil)
      end
    end

    it 'should use path prefix' do
      expect(klazz).to receive(:new) do |path, headers|
        expect(path).to eq("/test/test?param1=param1")
        expect(headers['X-Test-Header']).to eq('test')
      end.and_return(response)
      service.send(http_method, '/test', { param1: 'param1' }, headers: { 'X-Test-Header' => 'test' }, path_prefix: '/test')
    end

    context 'path starts with http' do
      it 'should use path as full_path' do
        expect(klazz).to receive(:new) do |path, _headers|
          expect(path).to eq("http://test.com/test?param1=param1")
        end.and_return(response)
        service.send(http_method, 'http://test.com/test', { param1: 'param1' })
      end

      it 'should ignore path_prefix' do
        expect(klazz).to receive(:new) do |path, _headers|
          expect(path).to eq("http://test.com/test?param1=param1")
        end.and_return(response)
        service.send(http_method, 'http://test.com/test', {param1: 'param1'}, path_prefix: '/test')
      end

      it 'should accept http as param' do
        expect(klazz).to receive(:new) do |path, _headers|
          expect(path).to eq("/test/test?#{URI.encode_www_form({param1: 'http://test.com'})}")
        end.and_return(response)
        service.send(http_method, 'test', { param1: 'http://test.com' }, path_prefix: '/test')
      end
    end
  end

  shared_examples 'request with data' do |http_method|
    klazz = Object.const_get("Net::HTTP::#{http_method.capitalize}")

    before :each do
      @request = double('request').as_null_object
      allow(klazz).to receive(:new).and_return(@request)
    end

    it "should create a new #{http_method} request" do
      expect(klazz).to receive(:new) do |path, _headers|
        expect(path).to eq(URI(identity_url).path + '/test')
      end
      service.send(http_method, 'test')
    end

    it "should create #{http_method} request with data" do
      expect(@request).to receive(:body=).with("{\"param1\":\"param1\"}")
      service.send(http_method, 'test') do
        { param1: 'param1' }
      end
    end

    it "should create #{http_method} request with headers" do
      expect(klazz).to receive(:new) do |path, headers|
        expect(path).to eq(URI(identity_url).path + '/test')
        expect(headers['X-Test-Header']).to eq('test')
      end.and_return(response)

      service.send(http_method, 'test', headers: { 'X-Test-Header' => 'test' }) do
        { param1: 'param1' }
      end
    end

    it "should create #{http_method} request with params, data and headers" do
      expect(klazz).to receive(:new) do |path, headers|
        expect(path).to eq(URI(identity_url).path + '/test?param1=param1')
        expect(headers['X-Test-Header']).to eq('test')
      end.and_return(response)

      service.send(http_method, 'test', {param1: 'param1'}, headers: {'X-Test-Header' => 'test'}, path_prefix: '') do
        {data1: 'test'}
      end
    end

    it 'accepts options in params' do
      expect(klazz).to receive(:new) do |path, headers|
        expect(path).to eq(URI(identity_url).path + '/test?param1=param1')
        expect(headers['X-Test-Header']).to eq('test')
      end.and_return(response)

      service.send(http_method, 'test', param1: 'param1', interface: 'public', headers: {'X-Test-Header' => 'test'}) do
        { data1: 'test' }
      end
    end

    it 'should request new token' do
      expect(service.instance_variable_get(:@auth_session)).to receive(:token)
      service.send(http_method, 'test')
    end

    describe 'option path_prefix' do
      it 'should reset service url path' do
        expect(klazz).to receive(:new) do |path, _headers|
          expect(path).to eq('/test')
        end.and_return(response)

        service.send(http_method, 'test', path_prefix: '/') do
          { data1: 'test' }
        end
      end

      it 'should ignore path_prefix' do
        expect(klazz).to receive(:new) do |path, _headers|
          expect(path).to eq(URI(identity_url).path + '/test')
        end.and_return(response)

        service.send(http_method, 'test', path_prefix: '') do
          { data1: 'test' }
        end
      end

      it 'should extend pathwith path_prefix' do
        expect(klazz).to receive(:new) do |path, _headers|
          expect(path).to eq(URI(identity_url).path + '/prefix/test')
        end.and_return(response)

        service.send(http_method, 'test', path_prefix: 'prefix') do
          { data1: 'test' }
        end
      end

      it 'should use service url path' do
        expect(klazz).to receive(:new) do |path, _headers|
          expect(path).to eq(URI(identity_url).path + '/test')
        end.and_return(response)

        service.send(http_method, 'test', path_prefix: nil) do
          { data1: 'test' }
        end
      end

      it 'should set path prefix to /v3' do
        expect(klazz).to receive(:new) do |path, _headers|
          expect(path).to eq('/v3/test')
        end.and_return(response)

        service.send(http_method, 'test', path_prefix: '/v3') do
          { data1: 'test' }
        end
      end
    end

    context 'overwrite default headers' do
      it 'should overwrite the default content type' do
        expect(klazz).to receive(:new) do |_path, headers|
          expect(headers['Content-Type']).to eq(
            'application/openstack-images-v2.1-json-patch'
          )
        end.and_return(double('response').as_null_object)

        service.send(http_method,
          'test', {}, headers: {
            'Content-Type' => 'application/openstack-images-v2.1-json-patch'
          }
        )
      end
    end
  end

  describe '#post' do
    it_behaves_like 'request with data', :post
  end

  describe '#put' do
    it_behaves_like 'request with data', :put
  end

  describe '#patch' do
    it_behaves_like 'request with data', :patch
  end

  describe '#get' do
    it_behaves_like 'request without data', :get
  end

  describe '#delete' do
    it_behaves_like 'request without data', :delete
  end

  describe '#options' do
    it_behaves_like 'request without data', :options
  end

  describe '#copy' do
    it_behaves_like 'request without data', :copy
  end
end
