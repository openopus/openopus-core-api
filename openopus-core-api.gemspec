$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "openopus/core/api/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "openopus-core-api"
  spec.version     = Openopus::Core::Api::VERSION
  spec.authors     = ["Brian J. Fox", "Daniel Staudigel", "Khrystle Dunn"]
  spec.email       = ["bfox@opuslogica.com", "krae@opuslogica.com"]
  spec.homepage    = "https://github.com/opuslogica/openopus-core-api"
  spec.summary     = "Zeroconf customizable RESTful API CRUDs your DB."
  spec.description = "RESTful API server easily configurable authentication delivers API automagically."
  spec.license     = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 5.2.3"

  spec.add_development_dependency "sqlite3"
end
