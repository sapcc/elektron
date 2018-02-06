describe Elektron::Containers::Response do
  subject { Elektron::Containers::Response.new }

  describe '::new' do
    before :each do
      @response = Elektron::Containers::Response.new(
        body: 'test_body', header: { 'test' => 'test' }
      )
    end

    it 'should create a new conatiner object' do
      expect(@response).not_to be(nil)
    end

    it 'should return service_name' do
      expect(@response.body).to eq('test_body')
    end

    it 'should return token' do
      expect(@response.header).to eq({ 'test' => 'test' })
    end

    it 'should return nil' do
      expect(@response.url).to be(nil)
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

  %w[body header service_name http_method url].each do |m|
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
