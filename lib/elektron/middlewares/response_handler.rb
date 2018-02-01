require_relative './base'

module Elektron
  module Middlewares
    # This is an Elektron middleware which wrappes the http response.
    # It also checks if the response code is smaller than 400. Otherwise
    # it raises an ApiError.
    class ResponseHandler < ::Elektron::Middlewares::Base

      # This is the response wrapper. It adds the map_to method and
      # holds some usefull infos.
      class Response
        extend Forwardable
        attr_reader :data, :service_name, :http_method, :path
        def_delegators :@response, :body, :[], :header

        def initialize(response, service_name: nil, http_method: nil, path: nil)
          @response     = response
          @data         = response.body
          @service_name = service_name
          @http_method  = http_method
          @path         = path
        end

        # This method is used to map raw data to a Object.
        def map_to(key_class_map, options = {})
          key = key_class_map
          klass = nil
          if key_class_map.is_a?(Hash)
            key = key_class_map.keys.first
            klass = key_class_map.values.first
          end

          key_tokens = key.split('.')
          key_tokens.shift if key_tokens[0] == 'body'
          data = @response.body
          key_tokens.each { |k| data = data[k] }

          if data.is_a?(Array)
            data.collect do |item|
              params = item.merge(options)
              block_given? ? yield(params) : klass.new(params)
            end
          elsif data.is_a?(Hash)
            params = data.merge(options)
            block_given? ? yield(params) : klass.new(params)
          else
            data
          end
        end
      end

      def call(request_context)
        # get the response from the next middleware in the stack.
        response = @next_middleware.call(request_context)
        Response.new(
          response,
          service_name: metadata.service_name,
          http_method: metadata.http_method,
          path: metadata.path
        )
      end
    end
  end
end
