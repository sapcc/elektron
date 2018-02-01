describe Elektron::Middlewares::ResponseHandler do
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
    @response_handler = Elektron::Middlewares::ResponseHandler.new(@next_app)
    @metadata = double('metadata').as_null_object
  end

  it 'should return an instance of Response' do
    expect(@response_handler.call(@metadata, {}, {}, {})).to be_a(
      Elektron::Middlewares::ResponseHandler::Response
    )
  end

  it 'should return response body' do
    expect(@response_handler.call(@metadata, {}, {}, {}).body).to eq(
      @response.body
    )
  end
end

describe Elektron::Middlewares::ResponseHandler::Response do
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

  let(:api_response) { Elektron::Middlewares::ResponseHandler::Response.new(response) }

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
