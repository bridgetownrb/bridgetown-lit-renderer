# frozen_string_literal: true

require_relative "lib/bridgetown-lit-renderer/version"

Gem::Specification.new do |spec|
  spec.name          = "bridgetown-lit-renderer"
  spec.version       = BridgetownLitRenderer::VERSION
  spec.author        = "Bridgetown Team"
  spec.email         = "maintainers@bridgetownrb.com"
  spec.summary       = "Simple pipeline for SSR + hydration of Lit components"
  spec.homepage      = "https://github.com/bridgetownrb/bridgetown-lit-renderer"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r!^(test|script|spec|features|frontend)/!)
  end
  spec.test_files    = spec.files.grep(%r!^test/!)
  spec.require_paths = ["lib"]
  spec.metadata      = { "yarn-add"              => "bridgetown-lit-renderer@#{BridgetownLitRenderer::VERSION}",
                         "rubygems_mfa_required" => "true", }

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "bridgetown", ">= 0.15", "< 2.0"
  spec.add_dependency "random-port", ">= 0.5"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop-bridgetown", "~> 0.3"
end
