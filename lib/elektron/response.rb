module Elektron
  class Response
    attr_reader :body, :header
    attr_accessor :service_name, :http_method, :url

    def initialize(body, header)
      @body = body
      @header = header
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
      data = @body
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
end
