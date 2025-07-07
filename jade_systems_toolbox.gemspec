# frozen_string_literal: true

require_relative "lib/jade_systems_toolbox/version"

Gem::Specification.new do |spec|
  spec.name = "jade_systems_toolbox"
  spec.version = JadeSystemsToolbox::VERSION
  spec.authors = [ "Larry Reid" ]
  spec.email = [ "lcreid@jadesystems.ca" ]

  spec.summary = "A collection of command line commands to support development."
  spec.homepage = "https://github.com/lcreid/jade_systems_toolbox"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = File.join(spec.homepage, "CHANGELOG.nd")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = [ "lib" ]

  spec.add_dependency "open3", "~> 0.1"
  spec.add_dependency "pathname", "~> 0.2"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "yaml", "~> 0.2"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
