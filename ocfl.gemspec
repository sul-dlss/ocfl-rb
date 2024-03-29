# frozen_string_literal: true

require_relative "lib/ocfl/version"

Gem::Specification.new do |spec|
  spec.name = "ocfl"
  spec.version = OCFL::VERSION
  spec.authors = ["Justin Coyne"]
  spec.email = ["jcoyne@justincoyne.com"]

  spec.summary = "A ruby library for interacting with the Oxford Common File Layout (OCFL) "
  spec.description = "See https://ocfl.io/"
  spec.homepage = "https://github.com/sul-dlss/ocfl-rb"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "dry-monads", "~> 1.6"
  spec.add_dependency "dry-schema", "~> 1.13"
  spec.add_dependency "dry-struct", "~> 1.6"
  spec.add_dependency "zeitwerk", "~> 2.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
