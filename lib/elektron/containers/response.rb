module Elektron
  module Containers
    # This is a container for response data which
    # is passed through middlewares on the way back
    class Response
      attr_accessor :body, :header, :service_name, :http_method, :url

      def initialize(hash_map = nil)
        hash_map.each { |k, v| send("#{k}=", v) } if hash_map
      end
    end
  end
end
