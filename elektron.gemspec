$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'elektron/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'elektron'
  s.version     = Elektron::VERSION
  s.authors     = ['Andreas Pfau']
  s.email       = ['andreas.pfau@sap.com']
  s.homepage    = 'https://github.com/sapcc/elektron'
  s.summary     = 'Elektron is a tiny client for OpenStack APIs.'
  s.description = 'It handles the authentication, manages the session
                   (reauthentication), implements the service discovery and
                   offers the most important HTTP methods. Everything that
                   Elektron knows and depends on is based solely on the token
                   context it gets from Keystone.'
  s.license     = 'APACHE'

  s.files = Dir[
    '{lib}/**/*', 'APACHE-LICENSE', 'Rakefile', 'README.md'
  ]
end
