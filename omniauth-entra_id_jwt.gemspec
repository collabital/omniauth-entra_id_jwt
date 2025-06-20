# frozen_string_literal: true

require_relative "lib/omniauth/entra_id_jwt/version"

Gem::Specification.new do |spec|
  spec.name = "omniauth-entra_id_jwt"
  spec.version = OmniAuth::Entra::Id::JWT::VERSION
  spec.authors = ["Benjamin Elias"]
  spec.email = ["12136262+collabital@users.noreply.github.com"]

  spec.summary = "OAuth 2 authentication with the Entra ID API using an On Behalf Of JWT token."
  spec.homepage = "https://github.com/collabital/omniauth-entra_id_jwt"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency("omniauth-oauth2", "~> 1.8")

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.add_development_dependency("rspec", "~>  3.13")
  spec.add_development_dependency("simplecov", "~> 0.22")
  spec.add_development_dependency("webmock", "~>  3.25")
  spec.add_development_dependency("debug", "~> 1.0")
end
