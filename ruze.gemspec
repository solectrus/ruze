require_relative 'lib/ruze/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruze'
  spec.version       = Ruze::VERSION
  spec.authors       = ['Georg Ledermann']
  spec.email         = ['georg@ledermann.dev']

  spec.summary       = 'Unofficial Ruby client for the Renault ZE API'
  spec.description   = 'Queries vehicle data like mileage, charging state and GPS location'
  spec.homepage      = 'https://github.com/solectrus/ruze'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/solectrus/ruze'
  spec.metadata['changelog_uri'] = 'https://github.com/solectrus/ruze/releases'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
