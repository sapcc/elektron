describe Elektron::Containers::RequestContext do
  subject { Elektron::Containers::RequestContext.new }

  describe '::new' do
    before :each do
      @context = Elektron::Containers::RequestContext.new(
        service_name: 'test_service', token: 'test_token'
      )
    end

    it 'should create a new conatiner object' do
      expect(@context).not_to be(nil)
    end

    it 'should return service_name' do
      expect(@context.service_name).to eq('test_service')
    end

    it 'should return token' do
      expect(@context.token).to eq('test_token')
    end

    it 'should return nil' do
      expect(@context.options).to be(nil)
    end
  end

  shared_examples 'container value' do |method|
    it "responds to #{method}" do
      expect(subject).to respond_to(method.to_sym).with(0).arguments
    end

    it "responds to #{method}=" do
      expect(subject).to respond_to("#{method}=".to_sym).with(1).arguments
    end

    it 'should set a value' do
      subject.send("#{method}=", 'test')
      expect(subject.send(method)).to eq('test')
    end

    it 'should overwrite a value' do
      subject.send("#{method}=", 'test')
      expect(subject.send(method)).to eq('test')
      subject.send("#{method}=", 'test2')
      expect(subject.send(method)).to eq('test2')
    end
  end

  %w[
    service_name token service_url project_id http_method path params
    options data cache
  ].each do |m|
    describe '#container value' do
      it_behaves_like 'container value', m
    end
  end

  it 'should raise an error' do
    expect {
      subject.bad_key = 'test'
    }.to raise_error NoMethodError
  end
end
