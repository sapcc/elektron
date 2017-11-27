# forezen_string_literal: true
require_relative './auth/v2'
require_relative './auth/v3'
require_relative './token_context'

module Elektron
  # Abstract class
  class Auth
    attr_reader :token_context, :token

    VERSIONS = %w[V2 V3].freeze

    class UnknownIdentityVersion < StandardError; end

    def self.version(auth_conf, options)
      if options[:version] && VERSIONS.include?(options[:version].to_s.upcase)
        return options[:version].to_s.upcase
      end

      return 'V2' if auth_conf[:tenant_id] || auth_conf[:tenant_name]
      'V3'
    end

    def self.token_context(auth_conf, options)
      version = version(auth_conf, options)
      raise UnknownIdentityVersion unless version
      klass = Object.const_get("Elektron::Auth::#{version}")
      auth = klass.new(auth_conf, options)
      TokenContext.new(auth.context, auth.token_value)
    end
  end
end
