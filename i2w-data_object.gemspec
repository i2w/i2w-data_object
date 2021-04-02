require_relative "lib/i2w/data_object/version"

Gem::Specification.new do |s|
  s.name        = "i2w-data_object"
  s.version     = I2w::DataObject::VERSION
  s.authors     = ["Ian White"]
  s.email       = ["ian.w.white@gmail.com"]

  s.homepage    = 'https://github.com/i2w/data_object'
  s.summary     = 'A simple data object'
  s.description = 'i2w-data_object is provides a simple data object in 2 flavours, immutable and mutable.'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  s.metadata['homepage_uri'] = s.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  s.files = Dir['{lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_development_dependency 'activesupport', '>= 6'
  s.add_development_dependency 'rake', '>= 13.0.3'
end
