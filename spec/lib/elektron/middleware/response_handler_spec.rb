describe Elektron::Middlewares::ResponseHandler do
  before :each do
    @response = double(
      'response',
      code: 200,
      header: {},
      body: {
        'users' => [
          { 'id' => 1, 'name' => 'test1' },
          { 'id' => 2, 'name' => 'test2' }
        ]
      }
    )
    @next_middleware = double('next_middleware')
    allow(@next_middleware).to receive(:call).and_return(@response)
    @response_handler = Elektron::Middlewares::ResponseHandler.new(@next_middleware)
  end

  it 'should return an instance of Response' do
    expect(@response_handler.call(double('request context'))).to be_a(
      Elektron::Middlewares::ResponseHandler::Response
    )
  end

  it 'should return response header' do
    expect(@response_handler.call(double('request context')).header).to eq(
      @response.header
    )
  end

  it 'should return response body' do
    expect(@response_handler.call(double('request context')).body).to eq(
      @response.body
    )
  end
end

describe Elektron::Middlewares::ResponseHandler::Response do
  let(:http_response) do
    double(
      'response',
      header: {},
      body: {
        'users' => [
          { 'id' => 1, 'name' => 'test1' },
          { 'id' => 2, 'name' => 'test2' }
        ]
      }
    )
  end

  let(:response) {
    Elektron::Middlewares::ResponseHandler::Response.new(
      http_response.header, http_response.body
    )
  }

  describe '#map_to' do
    context 'map body to an object' do
      let(:mapped_response) { response.map_to('body' => OpenStruct) }

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
      let(:mapped_response) { response.map_to('body.users' => User) }

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
      let(:mapped_response) { response.map_to('body.bad_key' => OpenStruct) }

      it 'mapped response is an Array' do
        expect(mapped_response).to be(nil)
      end
    end

    context 'map using block' do
      class User < OpenStruct; end
      let(:mapped_response) {
        response.map_to('body.users') do |params|
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
