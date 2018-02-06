require_relative '../containers/request_context'
require_relative '../errors/middleware_stack_error'

module Elektron
  module Middlewares
    # This class implements the middlware stack which contains methods
    # like add, remove, replace and execute.
    class Stack
      class BadMiddlewareError < StandardError; end

      def initialize(middlewares = nil)
        @middlewares = middlewares || []
      end

      def clone
        stack_copy = all.collect { |m| m.dup }
        self.class.new(stack_copy)
      end

      # The parameters after and before make it possible to order middlwares.
      def add(middleware, after: nil, before: nil)
        if !middleware.is_a?(Class) || !middleware.method_defined?(:call)
          raise BadMiddlewareError, 'Middleware "' + middleware.to_s + '" does ' \
                                    'not respond to call method! Please ' \
                                    'provide a class which responds to call '\
                                    'method with four parameters ' \
                                    '"request_metadata", "params", ' \
                                    '"options", "data" and returns a ' \
                                    'response object!'
        end

        if after
          index = @middlewares.index(after)
          if index.nil? || (index + 1) == @middlewares.length
            @middlewares << middleware
          else
            @middlewares.insert(index + 1, middleware)
          end
        elsif before
          index = @middlewares.index(before)
          if index.nil?
            @middlewares << middleware
          else
            @middlewares.insert(index, middleware)
          end
        else
          @middlewares << middleware
        end
        middleware
      end

      # This method removes a middlware from stack.
      def remove(middleware)
        index = @middlewares.index(middleware)
        return false if index.nil?
        @middlewares.delete_at(index)
        middleware
      end

      # This method replaces a middleware with another.
      def replace(middleware, new_middleware)
        index = @middlewares.index(middleware)
        return false if index.nil?
        @middlewares.delete_at(index)
        @middlewares.insert(index, new_middleware)
        middleware
      end

      # Returns the stack
      def all
        @middlewares
      end

      def to_s
        'Request <- ' + @middlewares.join(' <- ')
      end

      # This method executes the middleware stack
      def execute(request_context)
        if !request_context.is_a?(Hash) &&
           !request_context.is_a?(Elektron::Containers::RequestContext)
          raise Elektron::Errors::MiddlewareStackError,
                'Please provide a hash or request context object'
        end

        if request_context.is_a?(Hash)
          request_context = Elektron::Containers::RequestContext.new(
            request_context
          )
        end

        previous_middleware = nil

        @middlewares.each do |middleware|
          previous_middleware = middleware.new(previous_middleware)
        end
        previous_middleware.call(request_context)
      end
    end
  end
end
