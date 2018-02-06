module Elektron
  module Middlewares
    # Middlware is simply a class that implements two methods
    # "initialize" with reference to the next middlware and
    # "call" with request_context which contains information about the service,
    # represents the request body for POST, PUT and PATH.
    #
    # Middlewares allow to manipulate both the request and the response parameters.
    # For example, you can edit the parameters, options, or data before passing
    # them to the next middleware. The response of the "call" method returns the
    # Http response object, which can now be edited on the way back.
    #
    # Example:
    #      class NewMiddleware < Elektron::Middleware::Base
    #        def initialize(next_middleware_in_the_stack)
    #          @next_middleware = next_middleware_in_the_stack
    #        end
    #
    #        def call(request_context)
    #          # manipulate url parameters
    #          request_context.params['new_param'] = 'test'
    #          # execute request
    #          response = @next_middleware.call(request_context)
    #          # manipulate response body
    #          response.body = {}
    #          return new response
    #          response
    #        end
    #      end
    class Base
      def initialize(next_middleware = nil)
        @next_middleware = next_middleware
      end

      def call(request_context)
        @next_middleware.call(request_context) if @next_middleware
      end
    end
  end
end
