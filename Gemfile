# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in pubid.gemspec
gemspec

gem "lutaml-model", github: "lutaml/lutaml-model", branch: "main"
# PG artifact engine (R1 parser swap). The published parsanol release
# predates Parsanol::PARG::Artifact — flip this to a rubygems pin once a
# release carrying the PG runtime is cut (owner call at PR time). Until
# then bundler builds the Rust extension from the git checkout. To use a
# local clone instead, run:
#   bundle config set local.parsanol ../../parsanol/parsanol-ruby
gem "parsanol", github: "parsanol/parsanol-ruby", branch: "main"
gem "json_schemer" # testsuite schema validation (tools/validate_schema.rb)
# benchmark is used by spec/pubid/iso/performance_spec.rb and is no longer a
# default gem as of Ruby 4.0, so it must be declared explicitly.
gem "benchmark"
gem "nokogiri"
gem "rake"
gem "rspec"
gem "yard" # docs:api_reference — the generated API reference (pubid#577)
gem "json_schemer"
gem "rubocop"
gem "rubocop-performance"
gem "rubocop-rake"
gem "rubocop-rspec"
