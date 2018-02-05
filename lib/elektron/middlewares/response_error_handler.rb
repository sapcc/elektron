require_relative './base'
require_relative '../errors/request'
require_relative '../errors/api_response'

module Elektron
  module Middlewares
    # This is an Elektron middleware which checks if the response code
    # is smaller than 400. Otherwise it raises an ApiError.
    class ResponseErrorHandler < ::Elektron::Middlewares::Base
      def call(request_context)
        # get the response from the next middleware in the stack.
        response = @next_middleware.call(request_context) if @next_middleware
      rescue StandardError => e
        # throws a Request error
        raise ::Elektron::Errors::Request, e
      else
        # return response object if response status code is
        # smaller than 400
        return response if response.code.to_i < 400
        # otherwise raise ApiError
        error = ::Elektron::Errors::ApiResponse.new(response)
        error.service_name = request_context.service_name
        error.http_method = request_context.http_method
        error.url = request_context.service_url
        raise error
      end
    end
  end
end
