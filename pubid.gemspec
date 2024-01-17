lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pubid/version"

Gem::Specification.new do |spec|
  spec.name          = "pubid"
  spec.version       = Pubid::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.homepage      = "https://github.com/metanorma/pubid"
  spec.summary       = "Gem including all pubid-* gems."
  spec.description   = "Gem including all pubid-* gems."
  spec.license       = "BSD-2-Clause"

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").select do |f|
      f.match(%r{^(lib|exe)/}) || f.match(%r{\.yaml$})
    end
  end
  spec.extra_rdoc_files = %w[README.adoc LICENSE.txt]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "pubid-core", "~> 1.12.2"
  spec.add_dependency "pubid-nist", "~> 0.2.6"
  spec.add_dependency "pubid-iso", "~> 0.7"
  spec.add_dependency "pubid-ieee", "~> 0.2.1"
  spec.add_dependency "pubid-cen", "~> 0.2.3"
  spec.add_dependency "pubid-iec", "~> 0.3.1"
  spec.add_dependency "pubid-ccsds", "~> 0.1"
  spec.add_dependency "pubid-itu", "~> 0.1.0"
  spec.add_dependency "pubid-jis", "~> 0.3.2"
  spec.add_dependency "pubid-bsi", "~> 0.3.2"
end
