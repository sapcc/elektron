module Elektron
  class RequestContext
    ALLOWED_KEYS = %w[
      service_name token service_url project_id
      http_method path params options data cache
    ].freeze

    def initialize(hash_map = nil)
      hash_map.each { |k, v| set(k, v) }
    end

    def set(key, value)
      unless ALLOWED_KEYS.include?(key)
        raise UnsupportedRequestContextKey, "key #{key} is not supported"
      end
      @hash_map[key] = value
    end

    def get(key)
      @hash_map[key]
    end
  end
end
