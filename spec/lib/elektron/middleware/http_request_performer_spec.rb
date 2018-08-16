describe Elektron::Middlewares::HttpRequestPerformer do
  subject { Elektron::Middlewares::HttpRequestPerformer.new }

  it 'should resond to call' do
    expect(subject).to respond_to(:call)
  end

  describe '#create_request' do
    shared_examples 'request without data' do |http_method|
      klazz = Object.const_get("Net::HTTP::#{http_method.capitalize}")

      before :each do
        allow(klazz)
          .to receive(:new).and_call_original

        @request = subject.create_request(
          http_method, 'test', { 'header1' => 'test' }, {}
        )
      end

      it "should create a http #{http_method} request" do
        expect(@request).to be_kind_of(klazz)
      end

      it 'should pass path and headers to request object' do
        expect(klazz).to have_received(:new).with(
          'test', 'header1' => 'test'
        )
      end
    end

    shared_examples 'request with data' do |http_method|
      klazz = Object.const_get("Net::HTTP::#{http_method.capitalize}")

      before :each do
        allow(klazz).to receive(:new).and_call_original

        @request = subject.create_request(
          http_method, 'test', { 'header1' => 'test' }, 'data1' => 'value1'
        )
      end

      it "should create a http #{http_method} request" do
        expect(@request).to be_kind_of(klazz)
      end

      it 'should pass path and headers to request object' do
        expect(klazz).to have_received(:new).with(
          'test',
          'Content-Type' => Elektron::Middlewares::HttpRequestPerformer::CONTENT_TYPE_JSON,
          'header1' => 'test'
        )
      end

      it 'should set data to request object' do
        expect_any_instance_of(klazz).to receive(:body=).with(
          { 'data1' => 'value1' }.to_json
        )
        subject.create_request(http_method, 'test', { 'header1' => 'test' }, 'data1' => 'value1')
      end
    end

    ################# HTTP METHODS #####################
    context 'method is get' do
      it_behaves_like 'request without data', :get
    end

    context 'method is head' do
      it_behaves_like 'request without data', :head
    end

    context 'method is delete' do
      it_behaves_like 'request without data', :delete
    end

    context 'method is options' do
      it_behaves_like 'request without data', :options
    end

    context 'method is copy' do
      it_behaves_like 'request without data', :copy
    end

    context 'method is post' do
      it_behaves_like 'request with data', :post
    end

    context 'method is put' do
      it_behaves_like 'request with data', :put
    end

    context 'method is patch' do
      it_behaves_like 'request with data', :patch
    end
  end

  describe '#encode_data' do
    it 'should json encode data' do
      expect(
        subject.encode_data(
          Elektron::Middlewares::HttpRequestPerformer::CONTENT_TYPE_JSON,
          'test' => 'value'
        )
      ).to eq('{"test":"value"}')
    end

    it 'should not json encode data' do
      expect(
        subject.encode_data(
          'text/html',
          'TEXT'
        )
      ).to eq('TEXT')
    end
  end

  describe '#json?' do
    it 'should return true' do
      expect(subject.json?('{"test":"value"}')).to eq(true)
    end

    it 'should return false' do
      expect(subject.json?('test' => 'value')).to eq(false)
    end
  end

  describe '#headers' do
    it 'should merge default headers with given headers' do
      expect(subject.headers(headers: { 'Test' => 'abc' })).to eq(
        {}.merge(Elektron::Middlewares::HttpRequestPerformer::DEFAULT_HEADERS)
          .merge('Test' => 'abc')
      )
    end

    it 'should create a copy of default headers' do
      new_headers = subject.headers(headers: { 'Test' => 'abc' })
      expect do
        test = {}.merge(Elektron::Middlewares::HttpRequestPerformer::DEFAULT_HEADERS)
        test['bad'] = 'test'
      end.to change(new_headers, :size).by(0)
    end
  end

  describe '#http_options' do
    it 'should copy default options and merge' do
      http_options = subject.http_options(URI('http:://test.com'), client: { read_timeout: 10 })
      expect(http_options).to eq(
        {}.merge(Elektron::Middlewares::HttpRequestPerformer::DEFAULT_OPTIONS)
          .merge(read_timeout: 10)
      )
    end

    it 'should not modify default options' do
      http_options = subject.http_options(URI('http:://test.com'), client: { read_timeout: 10 })
      expect do
        http_options['test'] = true
      end.to change(Elektron::Middlewares::HttpRequestPerformer::DEFAULT_OPTIONS, :size)
        .by(0)
    end

    it 'should set use_ssl option to true' do
      http_options = subject.http_options(URI('https:://test.com'), {})
      expect(http_options[:use_ssl]).to eq(true)
    end

    it 'should set verfiy mode' do
      http_options = subject.http_options(
        URI('https:://test.com'), client: { verify_ssl: false }
      )
      expect(http_options[:verify_mode]).to eq(OpenSSL::SSL::VERIFY_NONE)
    end
  end

  describe '#perform' do
    before :each do
      @connection = double('connection').as_null_object
      allow_any_instance_of(Net::HTTP).to receive(:start).and_yield(@connection)
    end

    it 'should create a new net http object' do
      expect(Net::HTTP).to receive(:new).and_call_original

      subject.perform(
        URI('http://test.com'),
        double('request').as_null_object,
        {}
      )
    end

    it 'should send http options to net http object' do
      http_options = Elektron::Middlewares::HttpRequestPerformer::DEFAULT_OPTIONS
      http_options.each do |k, v|
        expect_any_instance_of(Net::HTTP).to receive("#{k}=").with(v)
      end
      subject.perform(URI('http://test.com'), double('request'), http_options)
    end

    it 'should call start on net http object' do
      expect_any_instance_of(Net::HTTP).to receive(:start)
      subject.perform(URI('http://test.com'), double('request'), {})
    end
  end
end
