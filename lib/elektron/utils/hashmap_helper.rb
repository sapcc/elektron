module Elektron
  module Utils
    module Utils::HashmapHelper
      # Returns a new hashn
      #
      #   with_indifferent_access({ a: 1 })['a'] # => 1
      #   with_indifferent_access({ 'a' => 1 })[:a] # => 1
      def with_indifferent_access(hash)
        hash.each_with_object({}) { |(k, v), new_hash| new_hash[k.to_sym] = v }
      end

      # Returns a new hash with hash1 and hash2 merged recursively.
      #
      #   h1 = { a: true, b: { c: [1, 2, 3] } }
      #   h2 = { a: false, b: { x: [3, 4, 5] } }
      #
      #   deep_merge(h1, h2) # => { a: false, b: { c: [1, 2, 3], x: [3, 4, 5] } }
      def deep_merge(hash1, hash2)
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

      # Returns a deep copy of hash (value).
      def clone_hash(value)
        if value.is_a?(Hash)
          result = value.dup
          value.each { |k, v| result[k] = clone_hash(v) }
          result
        elsif value.is_a?(Array)
          result = value.dup
          result.clear
          value.each { |v| result << clone_hash(v) }
          result
        else
          value.dup
        end
      end
    end
  end
end
