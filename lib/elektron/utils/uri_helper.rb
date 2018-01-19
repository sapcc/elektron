require 'uri'

module Elektron
  module Utils
    module UriHelper
      def to_url(path, params)
        uri = URI(URI.escape(path))
        uri.query = URI.encode_www_form(params) if params && !params.empty?
        uri.to_s
      end

      def join_path_parts(*path_parts)
        File.join(path_parts)
      end
    end
  end
end
