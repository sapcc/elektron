require 'logger'
require_relative 'elektron/client'
require_relative 'elektron/service'
require_relative 'elektron/version'

module Elektron
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.client(auth_conf, options = {})
    Elektron::Client.new(auth_conf, options)
  end
end
