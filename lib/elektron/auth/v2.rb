module Elektron
  module Auth
    class V2
      attr_reader :context, :token_value
      def initialize(auth_conf, options)
        @auth_conf = auth_conf
        @options = options
        @client = Elektron::HttpClient.new(auth_conf[:url], @options)
        response = @client.post('/v2.0/tokens', credentials.to_json)
        @context = response.body['access']['token']
        @token_value = response.body['access']['token']['id']
      end

      def credentials
        # TODO: implement the body of this method
        {}
      end
    end
  end
end
