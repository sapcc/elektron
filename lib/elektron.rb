require 'logger'
require_relative 'elektron/auth_session'

module Elektron
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end  
end
