module Elektron
  module Utils
    def with_indifferent_access(hash)
      hash.each_with_object({}) { |(k, v), new_hash| new_hash[k.to_sym] = v }
    end

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
  end
end
