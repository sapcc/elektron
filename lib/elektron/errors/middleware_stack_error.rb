require 'json'
require_relative './general'

module Elektron
  module Errors
    class MiddlewareStackError < ::Elektron::Errors::General
    end
  end
end
