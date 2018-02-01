describe Elektron::Middlewares::ResponseErrorHandler do
  before :each do
    @response = double(
      'response',
      code: 200,
      body: {
        'users' => [
          { 'id' => 1, 'name' => 'test1' },
          { 'id' => 2, 'name' => 'test2' }
        ]
      }
    )
    @next_app = double('next_app')
    allow(@next_app).to receive(:call).and_return(@response)
    @response_handler = Elektron::Middlewares::ResponseErrorHandler.new(@next_app)
    @metadata = double('metadata').as_null_object
  end

  context 'should not raise error on valid response' do
    it 'response 200' do
      allow(@response).to receive(:code).and_return(200)
      expect{ @response_handler.call(@metadata, {}, {}, {}) }.not_to raise_error
    end

    it 'response code is 100' do
      allow(@response).to receive(:code).and_return(100)
      expect{ @response_handler.call(@metadata, {}, {}, {}) }.not_to raise_error
    end

    it 'response code is 300' do
      allow(@response).to receive(:code).and_return(300)
      expect{ @response_handler.call(@metadata, {}, {}, {}) }.not_to raise_error
    end
  end

  context 'should raise api response error' do
    it 'raises error on response code 400' do
      allow(@response).to receive(:code).and_return(400)
      expect{
        @response_handler.call(@metadata, {}, {}, {})
      }.to raise_error Elektron::Errors::ApiResponse
    end
  end
end
