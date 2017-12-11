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
  s.summary     = 'Summary of Elektron.'
  s.description = 'Description of Elektron.'
  s.license     = 'APACHE'

  s.files = Dir[
    '{app,config,db,lib}/**/*', 'APACHE-LICENSE', 'Rakefile', 'README.md'
  ]

  s.add_dependency 'rails', '~> 5.1.4'
end
