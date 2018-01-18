describe Elektron::HttpClient do
  url = 'https://testurl.com'

  before(:each) do
    allow_any_instance_of(Net::HTTP).to receive(:request)
      .and_return(double('response', code: 200).as_null_object)

    @connection = double('connection').as_null_object
    allow_any_instance_of(Net::HTTP).to receive(:start).and_yield(@connection)
  end

  describe '::new' do
    before :each do
      @conn = double('connection').as_null_object
      allow(Net::HTTP).to receive(:new).and_return(@conn)
    end

    it 'should raise an argument error' do
      expect {
        Elektron::HttpClient.new
      }.to raise_error(ArgumentError)
    end

    it 'should create a new http client' do
      expect(Elektron::HttpClient.new('https://auth_url.com')).not_to be(nil)
    end

    it 'should create a new net/http object' do
      expect(Net::HTTP).to receive(:new).with('testurl.com', 443, anything).and_call_original
      Elektron::HttpClient.new('https://testurl.com').get('path')
    end

    it 'should set default keep alive timeout' do
      client = Elektron::HttpClient.new(url)
      expect(@conn).to receive(:keep_alive_timeout=).with(
        Elektron::HttpClient::DEFAULT_OPTIONS[:keep_alive_timeout]
      )
      client.get('path')
    end

    context 'options are given' do
      options = {
        headers: { 'Test' => 'Test' },
        debug: true,
        client: {}
      }

      let(:client){
        Elektron::HttpClient.new(url, options.clone)
      }

      it 'should set the headers instance variable' do
        expect(client.instance_variable_get(:@headers)).to eq(
          Elektron::HttpClient::DEFAULT_HEADERS.clone.merge(options[:headers])
        )
      end

      it 'create a new http client with options' do
        expect(@conn).to receive(:use_ssl=).with(true)
        client.get('path')
      end

      context 'use ssl is false' do
        let(:client) {
          Elektron::HttpClient.new(
            url, options.clone.merge(client: { use_ssl: false })
          )
        }

        it 'should disable ssl' do
          expect(@conn).to receive(:use_ssl=).with(false)
          client.get('path')
        end
      end

      context 'overwrite default client options' do
        let(:client) {
          Elektron::HttpClient.new(
            url, options.clone.merge(client: { keep_alive_timeout: 0 })
          )
        }

        it 'should set keep_alive_timeout to 0' do
          expect(@conn).to receive(:keep_alive_timeout=).with(0)
          client.get('path')
        end
      end
    end
  end

  shared_examples 'request' do |request_class, method|
    before :each do
      @client = Elektron::HttpClient.new(url)
      allow(request_class).to receive(:new).and_call_original
      @client.send(method, 'test')
    end

    it "should create an instance of #{request_class}" do
      expect(request_class).to have_received(:new) do |path, headers|
        expect(path).to eq('test')
        Elektron::HttpClient::DEFAULT_HEADERS.each do |k, v|
          expect(headers[k]).to eq(v)
        end
      end
    end

    it 'should make a request' do
      expect(@connection).to have_received(:request).with(
        an_instance_of(request_class)
      )
    end

    it 'should set default headers on request' do
      expect(@connection).to have_received(:request) do |request|
        %w[Accept Connection User-Agent].each do |k|
          expect(request[k]).to eq(Elektron::HttpClient::DEFAULT_HEADERS[k])
        end
      end
    end
  end

  shared_examples 'request without params and data' do |request_class, method|
    before :each do
      @client = Elektron::HttpClient.new(url)
      @request = double(request_class.name).as_null_object
      allow(request_class).to receive(:new).and_return @request
    end

    context 'headers are provided' do
      before :each do
        @request_headers = {'X-Header' => 'TEST'}
        @client.send(method, 'test', @request_headers)
      end

      it 'should create a http post request with headers' do
        expect(request_class).to have_received(:new).with(
          'test', Elektron::HttpClient::DEFAULT_HEADERS.clone.merge(
            @request_headers
          )
        )
      end

      it 'should not set data to body' do
        expect(@request).not_to have_received(:body=)
      end
    end

    context 'client headers and request headers are provided' do
      before :each do
        @client_headers = { 'X-Client-Header' => 'Client Header' }
        @request_headers = { 'X-Post-Request' => 'Post Request' }
        @client = Elektron::HttpClient.new(url, headers: @client_headers)
        @request = double('post request').as_null_object
        allow(request_class).to receive(:new).and_return @request
        @client.send(method, 'test', @request_headers)
      end

      it 'should create a http request with headers' do
        expect(request_class).to have_received(:new).with(
          'test', Elektron::HttpClient::DEFAULT_HEADERS.clone.merge(
            @client_headers
          ).merge(@request_headers)
        )
      end
    end
  end

  shared_examples 'request with data' do |request_class, method|
    before :each do
      @client = Elektron::HttpClient.new(url)
      @request = double(request_class.name).as_null_object
      allow(request_class).to receive(:new).and_return @request
    end

    context 'data is provided' do
      before :each do
        @client.send(method, 'test', params1: 'test')
      end

      it 'should create a http request with data' do
        expect(request_class).to have_received(:new).with(
          'test', { 'Content-Type' => Elektron::HttpClient::CONTENT_TYPE_JSON }
            .merge(Elektron::HttpClient::DEFAULT_HEADERS.clone)
        )
      end

      it 'should set data to body' do
        expect(@request).to have_received(:body=).with(
          {params1: 'test'}.to_json
        )
      end

      it 'should set content_type to json' do
        expect(request_class).to have_received(:new) do |_path, headers|
          expect(headers['Content-Type']).to eq(
            Elektron::HttpClient::CONTENT_TYPE_JSON
          )
        end
      end
    end

    context 'headers are provided' do
      before :each do
        @request_headers = {'X-Header' => 'TEST'}
        @client.send(method, 'test', {}, @request_headers)
      end

      it 'should create a http post request with headers' do
        expect(request_class).to have_received(:new).with(
          'test', { 'Content-Type' => Elektron::HttpClient::CONTENT_TYPE_JSON }
            .merge(Elektron::HttpClient::DEFAULT_HEADERS.clone)
            .merge(@request_headers)
        )
      end

      it 'should not set data to body' do
        expect(@request).not_to have_received(:body=)
      end

      it 'should set content_type to json' do
        expect(request_class).to have_received(:new) do |_path, headers|
          expect(headers['Content-Type']).to eq(
            Elektron::HttpClient::CONTENT_TYPE_JSON
          )
        end
      end
    end

    context 'data and headers are provided' do
      before :each do
        @data = {param1: 'test1', params2: 'test2'}
        @request_headers = {'X-Header' => 'TEST'}
        @client.send(method, 'test', @data, @request_headers)
      end

      it 'should create a http request with headers' do
        expect(request_class).to have_received(:new).with(
          'test', { 'Content-Type' => Elektron::HttpClient::CONTENT_TYPE_JSON }
            .merge(Elektron::HttpClient::DEFAULT_HEADERS.clone)
            .merge(@request_headers)
        )
      end

      it 'should set data to body' do
        expect(@request).to have_received(:body=).with(@data.to_json)
      end

      it 'should set content_type to json' do
        expect(request_class).to have_received(:new) do |_path, headers|
          expect(headers['Content-Type']).to eq(
            Elektron::HttpClient::CONTENT_TYPE_JSON
          )
        end
      end
    end

    context 'client headers and request headers are provided' do
      before :each do
        @client_headers = { 'X-Client-Header' => 'Client Header' }
        @request_headers = { 'X-Post-Request' => 'Post Request' }
        client = Elektron::HttpClient.new(url, headers: @client_headers)
        client.send(method, 'test', {}, @request_headers)
      end

      it 'should create a http request with headers' do
        expect(request_class).to have_received(:new).with(
          'test', { 'Content-Type' => Elektron::HttpClient::CONTENT_TYPE_JSON }
            .merge(Elektron::HttpClient::DEFAULT_HEADERS.clone)
            .merge(@client_headers)
            .merge(@request_headers)
        )
      end
      it 'should set content_type to json' do
        expect(request_class).to have_received(:new) do |path, headers|
          expect(headers['Content-Type']).to eq(Elektron::HttpClient::CONTENT_TYPE_JSON)
        end
      end
    end
  end

  describe '#post' do
    it_behaves_like 'request', Net::HTTP::Post, :post
    it_behaves_like 'request with data', Net::HTTP::Post, :post
  end

  describe '#put' do
    it_behaves_like 'request', Net::HTTP::Put, :put
    it_behaves_like 'request with data', Net::HTTP::Put, :put
  end

  describe '#patch' do
    it_behaves_like 'request', Net::HTTP::Patch, :patch
    it_behaves_like 'request with data', Net::HTTP::Patch, :patch
  end

  describe '#get' do
    it_behaves_like 'request', Net::HTTP::Get, :get
    it_behaves_like 'request without params and data', Net::HTTP::Delete, :delete
  end

  describe '#delete' do
    it_behaves_like 'request', Net::HTTP::Delete, :delete
    it_behaves_like 'request without params and data', Net::HTTP::Delete, :delete
  end

  describe '#options' do
    it_behaves_like 'request', Net::HTTP::Options, :options
    it_behaves_like 'request without params and data', Net::HTTP::Options, :options
  end

  describe '#perform' do
    before :each do
      @client = Elektron::HttpClient.new(url)
    end

    context 'should not raise error on valid response' do
      it 'response 200' do
        allow(@connection).to receive(:request).and_return(
          double('response', code: 200).as_null_object
        )

        expect{ @client.get('test')}.not_to raise_error
      end

      it 'response code is 100' do
        allow(@connection).to receive(:request).and_return(
          double('response', code: 100).as_null_object
        )

        expect{ @client.get('test')}.not_to raise_error
      end

      it 'response code is 300' do
        allow(@connection).to receive(:request).and_return(
          double('response', code: 300).as_null_object
        )

        expect{ @client.get('test')}.not_to raise_error
      end
    end


    context 'should raise api response error' do
      it 'raises error on response code 400' do
        allow(@connection).to receive(:request).and_return(
          double('response', code: 400).as_null_object
        )

        expect{
          @client.get('test')
        }.to raise_error Elektron::Errors::ApiResponse
      end
    end

    context 'custom accept header' do
      it 'should accept custom Acept header' do
        expect(@connection).to receive(:request) do |request|
          expect(request['Accept']).to eq('text/plain')
        end.and_return(double('request', code: 200).as_null_object)
        @client.get('test', { 'Accept' => 'text/plain' } )
      end
    end
  end
end
