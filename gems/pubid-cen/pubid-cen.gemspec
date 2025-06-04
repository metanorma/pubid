lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pubid/cen/version"

Gem::Specification.new do |spec|
  spec.name          = "pubid-cen"
  spec.version       = Pubid::Cen::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.homepage      = "https://github.com/metanorma/pubid-cen"
  spec.summary       = "Library to generate, parse and manipulate CEN PubID."
  spec.description   = "Library to generate, parse and manipulate CEN PubID."
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

  spec.add_dependency "parslet"
  spec.add_dependency "pubid-core", "= 1.15.0"
  spec.add_dependency "pubid-iec", "= 1.15.0"
  spec.add_dependency "pubid-iso", "= 1.15.0"
end
