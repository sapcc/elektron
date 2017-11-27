require_relative './http_client'

module Elektron
  class Service
    def initialize(name, auth_session, options = {})
      @name = name
      @auth_session = auth_session
      @options = options
    end

    def get(url, options = {})
      http_request(:get, url, options)
    end

    def post(url, options = {}, &block)
      http_request(:post, url, options, block)
    end

    def put(url, options = {}, &block)
      http_request(:put, url, options, block)
    end

    def patch(url, options = {}, &block)
      http_request(:patch, url, options, block)
    end

    def delete(url, options = {})
      http_request(:delete, url, options)
    end

    private

    def http_request(method, url, options = {}, &block)

    end
  end
end
