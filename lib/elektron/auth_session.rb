require_relative './auth'

module Elektron
  def self.with_indifferent_access(hash)
    hash.each_with_object({}) { |(k, v), new_hash| new_hash[k.to_sym] = v }
  end

  def self.deep_merge(hash1, hash2)
    hash2.each_pair do |current_key, value2|
      value1 = hash1[current_key]

      hash1[current_key] = if value1.is_a?(Hash) && value2.is_a?(Hash)
                             deep_merge(value1, value2)
                           else
                             value2
                           end
    end
    hash1
  end

  # Entry point
  class AuthSession
    attr_reader :token_context

    DEFAULT_OPTIONS = {
      headers: {},
      default_interface: 'public'
    }.freeze

    def initialize(auth_conf, options)
      @auth_conf = Elektron.with_indifferent_access(auth_conf)
      @options = Elektron.deep_merge(
        {}.merge(DEFAULT_OPTIONS),
        Elektron.with_indifferent_access(options)
      )
    end

    def authenticate
      @token_context = Elektron::Auth.token_context(@auth_conf, @options)
    end

    def token
      authenticate if @token_context.expired?
      @token_context.token
    end

    def service(name, options = {})
      Service.new(name, self, Elektron.deep_merge(@options, options))
    end
  end
end
