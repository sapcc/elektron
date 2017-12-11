require 'logger'
require_relative 'elektron/client'

module Elektron
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.client(auth_conf, options = {})
    Elektron::Client.new(auth_conf, options)
  end
end
