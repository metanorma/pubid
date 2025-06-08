require_relative "lib/pubid/version"

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

  spec.add_dependency "pubid-bsi", "= 1.15.0"
  spec.add_dependency "pubid-ccsds", "= 1.15.0"
  spec.add_dependency "pubid-cen", "= 1.15.0"
  spec.add_dependency "pubid-core", "= 1.15.0"
  spec.add_dependency "pubid-etsi", "= 1.15.0"
  spec.add_dependency "pubid-iec", "= 1.15.0"
  spec.add_dependency "pubid-ieee", "= 1.15.0"
  spec.add_dependency "pubid-iso", "= 1.15.0"
  spec.add_dependency "pubid-itu", "= 1.15.0"
  spec.add_dependency "pubid-jis", "= 1.15.0"
  spec.add_dependency "pubid-nist", "= 1.15.0"
  spec.add_dependency "pubid-plateau", "= 1.15.0"
end
