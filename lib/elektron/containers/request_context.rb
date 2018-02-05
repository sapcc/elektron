module Elektron
  module Containers
    # This is a container for request data which
    # is passed through middlewares
    class RequestContext
      attr_accessor :service_name, :token, :service_url,
                    :project_id, :http_method, :path, :params,
                    :options, :data, :cache

      def initialize(hash_map = nil)
        hash_map.each { |k, v| send("#{k}=", v) } if hash_map
      end
    end
  end
end
