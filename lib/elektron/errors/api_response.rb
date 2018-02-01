require 'json'
require_relative './general'

module Elektron
  module Errors
    class ApiResponse < ::Elektron::Errors::General
      attr_reader :response, :messages, :code, :code_type, :error_type

      def initialize(response)
        if response
          @code = response.code.to_i if response.code && response.code.respond_to?(:to_i)
          @code_type = response.code_type if response.respond_to?(:code_type)
          @error_type = response.error_type if response.respond_to?(:error_type)

          @response = response
          data = @response.respond_to?(:body) ? @response.body : @response
          if data.is_a?(String)
            data = begin
                     JSON.parse(data)
                   rescue JSON::ParserError => _e
                     # do nothing
                     data
                   end
          end

          @messages = self.class.read_error_messages(data)
          super(@messages.join(', '))
        else
          super(response)
        end
      end

      def self.read_error_messages(hash, messages = [])
        return [hash.to_s] unless hash.respond_to?(:each)

        message_candidates = {
          'message' => nil,
          'description' => nil,
          'type' => nil
        }

        hash.each do |k, v|
          if v.is_a?(Hash)
            read_error_messages(v, messages)
          elsif v.is_a?(Array)
            v.each do |value|
              read_error_messages(value, messages) if value.is_a?(Hash)
            end
          else
            if message_candidates.keys.include?(k)
              message_candidates[k] = v
            end
          end
        end
        if message_candidates.values.uniq.length.positive?
          messages << (message_candidates['message'] ||
            message_candidates['description'] ||
            message_candidates['type'])
        end
        messages
      end
    end
  end
end
