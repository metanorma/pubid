lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pubid/nist/version"

Gem::Specification.new do |spec|
  spec.name          = "pubid-nist"
  spec.version       = Pubid::Nist::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.homepage      = "https://github.com/metanorma/pubid-nist"
  spec.summary       = "Library to generate, parse and manipulate NIST PubID."
  spec.description   = "Library to generate, parse and manipulate NIST PubID."
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
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"

  spec.add_dependency "lightly"
  spec.add_dependency "nokogiri"
  spec.add_dependency "parslet"
  spec.add_dependency "pubid-core", "= 1.15.0"
  spec.add_dependency "rubyzip"
  spec.add_dependency "thor"
end
