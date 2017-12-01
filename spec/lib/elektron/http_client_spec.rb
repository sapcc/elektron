describe Elektron::HttpClient do
  it 'should make a request' do
    @client = Elektron::HttpClient.new('https://identity-3.staging.cloud.sap/v3')
    @client.http_get('/', {})
  end
end
